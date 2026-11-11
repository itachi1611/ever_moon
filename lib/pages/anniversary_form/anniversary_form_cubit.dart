import 'package:ever_moon/models/anniversary.dart';
import 'package:ever_moon/models/anniversary_date.dart';
import 'package:ever_moon/repositories/anniversary_repository.dart';
import 'package:ever_moon/services/lunar/anniversary_resolver.dart';
import 'package:ever_moon/utils/app_logger.dart' as logger;
import 'package:flutter_bloc/flutter_bloc.dart';

import 'anniversary_draft.dart';
import 'anniversary_form_state.dart';

/// Validates and saves the add/edit form (plan 0005, U3; D4).
///
/// Every input goes through an intent method so the leap-month rule (UI-5)
/// and the reminder limits (D9) hold whatever the widgets send.
class AnniversaryFormCubit extends Cubit<AnniversaryFormState> {
  /// Creates the Cubit; tests inject [today] to pin the current day.
  AnniversaryFormCubit(
    this._repository,
    this._resolver, {
    DateTime Function()? today,
  }) : _today = today ?? DateTime.now,
       super(const AnniversaryFormLoading());

  final AnniversaryRepository _repository;
  final AnniversaryResolver _resolver;
  final DateTime Function() _today;
  Anniversary? _original;

  /// Name of the record as stored, for the delete question; `null` when
  /// adding.
  String? get storedName => _original?.name;

  /// Opens an empty form, or the record with [id] for editing.
  Future<void> load(String? id) async {
    if (id == null) {
      emit(_editing(const AnniversaryDraft()));
      return;
    }
    emit(const AnniversaryFormLoading());
    try {
      final found = await _repository.findById(id);
      if (isClosed) return;
      _original = found;
      emit(
        found == null
            ? const AnniversaryFormUnavailable()
            : _editing(AnniversaryDraft.of(found)),
      );
    } catch (error, stackTrace) {
      logger.err('Anniversary $id could not be read', error, stackTrace);
      if (!isClosed) emit(const AnniversaryFormUnavailable());
    }
  }

  /// Sets the name.
  void changeName(String name) => _change((d) => d.copyWith(name: name));

  /// Sets the lunar day; `null` clears it.
  void changeDay(int? day) => _change((d) => d.copyWith(lunarDay: () => day));

  /// Sets the lunar month; `null` clears it.
  void changeMonth(int? month) =>
      _change((d) => d.copyWith(lunarMonth: () => month));

  /// Sets the death year; `null` means unknown.
  void changeYear(int? year) =>
      _change((d) => d.copyWith(deathYear: () => year));

  /// Answers the leap-month question; ignored while it does not apply.
  void changeLeapMonth(bool value) =>
      _change((d) => d.copyWith(diedInLeapMonth: value));

  /// Turns the reminder on or off; its settings are kept either way.
  void changeReminder(bool enabled) =>
      _change((d) => d.copyWith(reminderEnabled: enabled));

  /// Sets the reminder lead time; values outside [remindDaysChoices] are
  /// rejected because only those are offered (D9).
  void changeDaysBefore(int days) {
    if (!remindDaysChoices.contains(days)) return;
    _change((d) => d.copyWith(remindDaysBefore: days));
  }

  /// Sets the reminder time in minutes after midnight (0 to 1439).
  void changeReminderTime(int minuteOfDay) {
    if (minuteOfDay < 0 || minuteOfDay >= Duration.minutesPerDay) return;
    _change((d) => d.copyWith(remindMinuteOfDay: minuteOfDay));
  }

  /// Sets the address.
  void changeAddress(String address) =>
      _change((d) => d.copyWith(address: address));

  /// Sets the note.
  void changeNote(String note) => _change((d) => d.copyWith(note: note));

  /// Saves a valid draft and closes; an invalid one shows its errors (UI-4).
  Future<void> save() async {
    final current = _idleEditing();
    if (current == null) return;
    final date = current.draft.date;
    if (current.draft.errors.isNotEmpty || date == null) {
      emit(current.copyWith(submitted: true));
      return;
    }
    emit(current.copyWith(submitted: true, busy: true, notice: _none));
    try {
      await _persist(current.draft, date);
      if (!isClosed) emit(const AnniversaryFormDone());
    } catch (error, stackTrace) {
      logger.err('Anniversary could not be saved', error, stackTrace);
      _report(AnniversaryFormNotice.saveFailed);
    }
  }

  /// Soft-deletes the edited record and closes (UI-6). The page asks for
  /// confirmation first.
  Future<void> delete() async {
    final current = _idleEditing();
    final original = _original;
    if (current == null || original == null) return;
    emit(current.copyWith(busy: true, notice: _none));
    try {
      await _repository.delete(original.id);
      if (!isClosed) emit(const AnniversaryFormDone());
    } catch (error, stackTrace) {
      logger.err('Anniversary ${original.id} not deleted', error, stackTrace);
      _report(AnniversaryFormNotice.deleteFailed);
    }
  }

  static const _none = AnniversaryFormNotice.none;

  AnniversaryFormEditing? _idleEditing() {
    final current = state;
    return current is AnniversaryFormEditing && !current.busy ? current : null;
  }

  /// Input is taken even while a save runs, so the draft always matches
  /// what the fields show if that save fails.
  void _change(AnniversaryDraft Function(AnniversaryDraft) edit) {
    final current = state;
    if (current is! AnniversaryFormEditing) return;
    emit(
      _editing(
        edit(current.draft),
        submitted: current.submitted,
        busy: current.busy,
      ),
    );
  }

  /// Reports a failed write on the latest draft, not the one being saved.
  void _report(AnniversaryFormNotice notice) {
    final latest = state;
    if (isClosed || latest is! AnniversaryFormEditing) return;
    emit(latest.copyWith(submitted: true, busy: false, notice: notice));
  }

  /// Builds the editing state; clears the leap answer when the year and
  /// month no longer allow it (UI-5, ADR 0001).
  AnniversaryFormEditing _editing(
    AnniversaryDraft draft, {
    bool submitted = false,
    bool busy = false,
  }) {
    final canBeLeap = _canBeLeapMonth(draft);
    final fixed = canBeLeap ? draft : draft.copyWith(diedInLeapMonth: false);
    final now = _today();
    final date = fixed.date;
    final holding = date == null ? null : _resolver.nextHolding(date, now);
    return AnniversaryFormEditing(
      draft: fixed,
      isEdit: _original != null,
      canBeLeapMonth: canBeLeap,
      nextHolding: holding,
      daysUntilNext: _daysFrom(now, holding?.solar),
      submitted: submitted,
      busy: busy,
    );
  }

  /// Whole days from the calendar day of [now] to [solar] (UTC midnight).
  static int? _daysFrom(DateTime now, DateTime? solar) =>
      solar?.difference(DateTime.utc(now.year, now.month, now.day)).inDays;

  bool _canBeLeapMonth(AnniversaryDraft draft) {
    final year = draft.deathYear;
    final month = draft.lunarMonth;
    if (year == null || month == null) return false;
    return _resolver.canBeLeapMonth(deathYear: year, lunarMonth: month);
  }

  Future<void> _persist(AnniversaryDraft draft, AnniversaryDate date) async {
    final original = _original;
    if (original != null) {
      await _repository.update(_edited(original, draft, date));
      return;
    }
    await _repository.create(
      name: draft.name.trim(),
      date: date,
      note: draft.noteOrNull,
      address: draft.addressOrNull,
      reminderEnabled: draft.reminderEnabled,
      remindDaysBefore: draft.remindDaysBefore,
      remindMinuteOfDay: draft.remindMinuteOfDay,
    );
  }

  static Anniversary _edited(
    Anniversary original,
    AnniversaryDraft draft,
    AnniversaryDate date,
  ) => original.copyWith(
    name: draft.name.trim(),
    date: date,
    note: () => draft.noteOrNull,
    address: () => draft.addressOrNull,
    reminderEnabled: draft.reminderEnabled,
    remindDaysBefore: draft.remindDaysBefore,
    remindMinuteOfDay: draft.remindMinuteOfDay,
  );
}

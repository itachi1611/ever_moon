import 'dart:async';

import 'package:ever_moon/models/anniversary.dart';
import 'package:ever_moon/repositories/anniversary_repository.dart';
import 'package:ever_moon/utils/app_logger.dart' as logger;
import 'package:flutter_bloc/flutter_bloc.dart';

import 'calendar_builder.dart';
import 'calendar_models.dart';
import 'calendar_state.dart';

/// Drives the calendar tab: view, selected day and the period around it
/// (plan 0005, U5; UI-9, UI-13, UI-14).
class CalendarCubit extends Cubit<CalendarState> {
  /// Creates the Cubit; tests inject [today].
  CalendarCubit(this._repository, this._builder, {DateTime Function()? today})
    : _today = today ?? DateTime.now,
      super(const CalendarLoading());

  final AnniversaryRepository _repository;
  final CalendarBuilder _builder;
  final DateTime Function() _today;
  StreamSubscription<List<Anniversary>>? _subscription;
  List<Anniversary>? _records;
  CalendarView _view = CalendarView.month;
  DateTime? _selected;

  static const _week = Duration(days: DateTime.daysPerWeek);

  /// Starts following the stored anniversaries; calling it again retries.
  void start() {
    final previous = _subscription;
    _records = null;
    emit(const CalendarLoading());
    _subscription = _repository.watchAll().listen(_onData, onError: _onError);
    if (previous != null) unawaited(previous.cancel());
  }

  /// Recomputes "today" and the shown period without re-reading storage;
  /// the page calls it when the app returns to the foreground.
  void refresh() => _publish();

  /// Switches the layout, keeping the selected day.
  void showView(CalendarView view) {
    _view = view;
    _publish();
  }

  /// Selects [day]; in the month view its events show below the grid.
  void select(DateTime day) {
    _selected = DateTime.utc(day.year, day.month, day.day);
    _publish();
  }

  /// Opens [month] of the shown year in the month view (year tile tap).
  void openMonth(int month) {
    _view = CalendarView.month;
    _selected = _firstOrToday(DateTime.utc(_selectedDay.year, month));
    _publish();
  }

  /// Moves to the previous year, month or week.
  void previous() => _step(-1);

  /// Moves to the next year, month or week.
  void next() => _step(1);

  /// Soft-deletes the anniversary [id] after the page asked (UI-13).
  /// Returns whether it worked; the stream then removes it from view.
  Future<bool> delete(String id) async {
    try {
      await _repository.delete(id);
      return true;
    } catch (error, stackTrace) {
      logger.err(
        'Anniversary $id not deleted from calendar',
        error,
        stackTrace,
      );
      return false;
    }
  }

  void _step(int direction) {
    final day = _selectedDay;
    _selected = switch (_view) {
      CalendarView.year => _firstOrToday(DateTime.utc(day.year + direction)),
      CalendarView.month => _firstOrToday(
        DateTime.utc(day.year, day.month + direction),
      ),
      CalendarView.week => day.add(_week * direction),
    };
    _publish();
  }

  /// [first] (day 1 of a month or year), or today when today is in that
  /// same month or year, so coming back lands on today.
  DateTime _firstOrToday(DateTime first) {
    final today = _todayUtc();
    final sameYear = today.year == first.year;
    final inPeriod = _view == CalendarView.year
        ? sameYear
        : sameYear && today.month == first.month;
    return inPeriod ? today : first;
  }

  void _onData(List<Anniversary> records) {
    _records = records;
    _publish();
  }

  void _onError(Object error, StackTrace stackTrace) {
    logger.err('Calendar could not read anniversaries', error, stackTrace);
    _records = null;
    emit(const CalendarFailure());
  }

  void _publish() {
    final records = _records;
    if (records == null || isClosed) return;
    final selected = _selectedDay;
    emit(
      CalendarReady(
        today: _todayUtc(),
        selected: selected,
        period: _period(selected, records),
      ),
    );
  }

  CalendarPeriod _period(DateTime day, List<Anniversary> records) =>
      switch (_view) {
        CalendarView.year => YearPeriod(
          year: day.year,
          months: _builder.year(day.year, records),
        ),
        CalendarView.month => _monthOf(day, records),
        CalendarView.week => WeekPeriod(
          days: _builder.days(
            _monday(day),
            _monday(day).add(_lastWeekday),
            records,
          ),
        ),
      };

  static const _lastWeekday = Duration(days: DateTime.daysPerWeek - 1);

  MonthPeriod _monthOf(DateTime day, List<Anniversary> records) {
    final first = DateTime.utc(day.year, day.month);
    final last = DateTime.utc(day.year, day.month + 1, 0);
    final lead = first.weekday - DateTime.monday;
    final days = _builder.days(first, last, records);
    final trail = (-(lead + days.length)) % DateTime.daysPerWeek;
    return MonthPeriod(
      year: day.year,
      month: day.month,
      cells: [
        ...List<CalendarDay?>.filled(lead, null),
        ...days,
        ...List<CalendarDay?>.filled(trail, null),
      ],
    );
  }

  static DateTime _monday(DateTime day) =>
      day.subtract(Duration(days: day.weekday - DateTime.monday));

  DateTime get _selectedDay => _selected ?? _todayUtc();

  DateTime _todayUtc() {
    final now = _today();
    return DateTime.utc(now.year, now.month, now.day);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

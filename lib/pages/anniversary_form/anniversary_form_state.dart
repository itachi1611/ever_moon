import 'package:equatable/equatable.dart';
import 'package:ever_moon/services/lunar/anniversary_resolver.dart';

import 'anniversary_draft.dart';

/// A one-off problem the page reports with a snack bar.
enum AnniversaryFormNotice {
  /// Nothing to report.
  none,

  /// Writing the record failed; the input is kept.
  saveFailed,

  /// Deleting the record failed; the record is kept.
  deleteFailed,
}

/// State of the add/edit form (plan 0005, U3).
sealed class AnniversaryFormState extends Equatable {
  const AnniversaryFormState();

  @override
  List<Object?> get props => [];
}

/// Reading the record to edit.
final class AnniversaryFormLoading extends AnniversaryFormState {
  /// Creates the loading state.
  const AnniversaryFormLoading();
}

/// The record to edit is missing, deleted or could not be read.
final class AnniversaryFormUnavailable extends AnniversaryFormState {
  /// Creates the unavailable state.
  const AnniversaryFormUnavailable();
}

/// The user is filling the form in.
final class AnniversaryFormEditing extends AnniversaryFormState {
  /// Creates the editing state; the Cubit is the producer.
  const AnniversaryFormEditing({
    required this.draft,
    required this.isEdit,
    required this.canBeLeapMonth,
    this.nextHolding,
    this.daysUntilNext,
    this.submitted = false,
    this.busy = false,
    this.notice = AnniversaryFormNotice.none,
  });

  /// The current input.
  final AnniversaryDraft draft;

  /// Whether an existing record is edited (offers delete).
  final bool isEdit;

  /// Whether the leap-month toggle is shown (UI-5).
  final bool canBeLeapMonth;

  /// Next holding of the drafted date, when day and month are valid.
  final AnniversaryHolding? nextHolding;

  /// Whole days from today to [nextHolding]; 0 means today.
  final int? daysUntilNext;

  /// Whether the reminder for [nextHolding] is still ahead; `false` when the
  /// lead time reaches back before today, so no past date is promised.
  bool get reminderStillAhead {
    final days = daysUntilNext;
    return days != null && draft.remindDaysBefore <= days;
  }

  /// Whether the user tried to save; errors show only after that.
  final bool submitted;

  /// Whether a save or delete is running; another save or delete is
  /// blocked meanwhile, but input is still taken.
  final bool busy;

  /// Problem to report once.
  final AnniversaryFormNotice notice;

  /// Errors to show under the fields.
  Set<AnniversaryFormError> get visibleErrors =>
      submitted ? draft.errors : const {};

  /// Copy with the run flags replaced.
  AnniversaryFormEditing copyWith({
    bool? submitted,
    bool? busy,
    AnniversaryFormNotice? notice,
  }) => AnniversaryFormEditing(
    draft: draft,
    isEdit: isEdit,
    canBeLeapMonth: canBeLeapMonth,
    nextHolding: nextHolding,
    daysUntilNext: daysUntilNext,
    submitted: submitted ?? this.submitted,
    busy: busy ?? this.busy,
    notice: notice ?? this.notice,
  );

  @override
  List<Object?> get props => [
    draft,
    isEdit,
    canBeLeapMonth,
    nextHolding,
    daysUntilNext,
    submitted,
    busy,
    notice,
  ];
}

/// The record was saved or deleted; the page closes.
final class AnniversaryFormDone extends AnniversaryFormState {
  /// Creates the done state.
  const AnniversaryFormDone();
}

import 'package:equatable/equatable.dart';
import 'package:ever_moon/models/anniversary_date.dart';

/// A registered anniversary (giỗ) for one person.
///
/// [id] is a client-generated UUID that never changes, so records can be
/// synced later without a rewrite (offline-first rule).
class Anniversary extends Equatable {
  /// Creates the entity; repositories are the intended producers.
  const Anniversary({
    required this.id,
    required this.name,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.note,
    this.address,
    this.reminderEnabled = true,
    this.remindDaysBefore = 0,
    this.remindMinuteOfDay = defaultRemindMinuteOfDay,
  });

  /// Reminder time used when the family does not choose one: 07:00.
  static const int defaultRemindMinuteOfDay = 7 * 60;

  /// Stable UUID v4.
  final String id;

  /// Name of the person the anniversary is held for.
  final String name;

  /// Lunar date of the death as the family records it.
  final AnniversaryDate date;

  /// Free-text note from the family.
  final String? note;

  /// Where the family gathers, when given.
  final String? address;

  /// Whether a reminder is scheduled.
  final bool reminderEnabled;

  /// Days before the anniversary the reminder fires; 0 means on the day.
  final int remindDaysBefore;

  /// Reminder time as minutes after local midnight (420 is 07:00).
  final int remindMinuteOfDay;

  /// Creation time, UTC.
  final DateTime createdAt;

  /// Last change time, UTC.
  final DateTime updatedAt;

  /// Copy with the editable fields replaced; identity and timestamps stay.
  ///
  /// [note] and [address] take a function so a caller can clear them:
  /// `copyWith(address: () => null)`. Leaving them out keeps the value.
  Anniversary copyWith({
    String? name,
    AnniversaryDate? date,
    String? Function()? note,
    String? Function()? address,
    bool? reminderEnabled,
    int? remindDaysBefore,
    int? remindMinuteOfDay,
  }) => Anniversary(
    id: id,
    name: name ?? this.name,
    date: date ?? this.date,
    note: note == null ? this.note : note(),
    address: address == null ? this.address : address(),
    reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    remindDaysBefore: remindDaysBefore ?? this.remindDaysBefore,
    remindMinuteOfDay: remindMinuteOfDay ?? this.remindMinuteOfDay,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    date,
    note,
    address,
    reminderEnabled,
    remindDaysBefore,
    remindMinuteOfDay,
    createdAt,
    updatedAt,
  ];
}

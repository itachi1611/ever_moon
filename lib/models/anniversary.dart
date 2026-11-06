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
    this.reminderEnabled = true,
  });

  /// Stable UUID v4.
  final String id;

  /// Name of the person the anniversary is held for.
  final String name;

  /// Lunar date of the death as the family records it.
  final AnniversaryDate date;

  /// Free-text note from the family.
  final String? note;

  /// Whether a reminder is scheduled.
  final bool reminderEnabled;

  /// Creation time, UTC.
  final DateTime createdAt;

  /// Last change time, UTC.
  final DateTime updatedAt;

  /// Copy with the editable fields replaced; identity and timestamps stay.
  Anniversary copyWith({
    String? name,
    AnniversaryDate? date,
    String? note,
    bool? reminderEnabled,
  }) =>
      Anniversary(
        id: id,
        name: name ?? this.name,
        date: date ?? this.date,
        note: note ?? this.note,
        reminderEnabled: reminderEnabled ?? this.reminderEnabled,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  @override
  List<Object?> get props =>
      [id, name, date, note, reminderEnabled, createdAt, updatedAt];
}

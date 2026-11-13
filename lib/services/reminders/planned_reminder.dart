import 'package:equatable/equatable.dart';
import 'package:ever_moon/services/lunar/lunar_calendar_service.dart';
import 'package:ever_moon/services/lunar/lunar_holidays.dart';

/// What a [PlannedReminder] is about.
enum ReminderKind {
  /// A user event (a death anniversary).
  anniversary,

  /// mùng 1, rằm or a Tết festival, switched on in Settings.
  systemEvent,
}

/// One notification the app wants the operating system to show.
///
/// A plain value: the planner produces it, the gateway turns it into a real
/// notification. It holds no localized text; the text is built from these
/// fields at schedule time, in the language chosen in Settings.
class PlannedReminder extends Equatable {
  /// Creates a planned reminder.
  const PlannedReminder({
    required this.id,
    required this.kind,
    required this.fireAt,
    required this.eventDay,
    required this.lunar,
    this.daysBefore = 0,
    this.anniversaryId,
    this.anniversaryName,
    this.holiday,
  });

  /// Stable notification id: the same event and day always get the same id.
  final int id;

  /// Whether this is a user event or a system event.
  final ReminderKind kind;

  /// Wall-clock time to fire, in the device's local time zone. The gateway
  /// converts it to a zoned time; the planner never reads the time zone.
  final DateTime fireAt;

  /// Gregorian day of the event itself (UTC midnight), which is later than
  /// [fireAt] when the reminder is sent days ahead.
  final DateTime eventDay;

  /// Lunar date the event is held on that year.
  final LunarDate lunar;

  /// Days between [fireAt] and [eventDay]; 0 means on the day.
  final int daysBefore;

  /// Id of the anniversary (anniversary reminders only).
  final String? anniversaryId;

  /// Name of the anniversary at planning time (anniversary reminders only).
  final String? anniversaryName;

  /// The system event (system reminders only).
  final LunarHoliday? holiday;

  @override
  List<Object?> get props => [
    id,
    kind,
    fireAt,
    eventDay,
    lunar,
    daysBefore,
    anniversaryId,
    anniversaryName,
    holiday,
  ];
}

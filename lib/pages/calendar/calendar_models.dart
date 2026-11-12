import 'package:equatable/equatable.dart';
import 'package:ever_moon/models/anniversary.dart';
import 'package:ever_moon/services/lunar/lunar_calendar_service.dart';
import 'package:ever_moon/services/lunar/lunar_holidays.dart';

/// The three calendar layouts (plan 0005, UI-9).
enum CalendarView {
  /// Twelve month tiles.
  year,

  /// A month grid with the selected day's events below.
  month,

  /// Seven day rows.
  week,
}

/// One Gregorian day with what the calendar shows on it.
class CalendarDay extends Equatable {
  /// Creates the day; the calendar builder is the producer.
  const CalendarDay({
    required this.solar,
    required this.lunar,
    required this.holidays,
    required this.anniversaries,
  });

  /// The day, UTC midnight.
  final DateTime solar;

  /// Its lunar date; `null` outside the supported range.
  final LunarDate? lunar;

  /// Holidays of the day: Tết Thanh Minh can share a day with a lunar
  /// festival or rằm, so there may be more than one.
  final List<LunarHoliday> holidays;

  /// Whether the day carries a holiday mark.
  bool get hasHoliday => holidays.isNotEmpty;

  /// Anniversaries held that day, by name.
  final List<Anniversary> anniversaries;

  /// Whether at least one anniversary falls that day.
  bool get hasAnniversary => anniversaries.isNotEmpty;

  @override
  List<Object?> get props => [solar, lunar, holidays, anniversaries];
}

/// Counts for one Gregorian month in the year view (D16).
class MonthSummary extends Equatable {
  /// Creates the summary.
  const MonthSummary({
    required this.month,
    required this.anniversaries,
    required this.festivals,
  });

  /// Gregorian month, 1 to 12.
  final int month;

  /// Anniversaries held that month.
  final int anniversaries;

  /// Named festivals that month; plain mùng 1 and rằm are not counted.
  final int festivals;

  @override
  List<Object?> get props => [month, anniversaries, festivals];
}

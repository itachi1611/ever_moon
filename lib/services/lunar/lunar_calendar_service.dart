import 'package:ever_moon/services/lunar/engine_lunar_calendar_service.dart';
import 'package:lunar_calendar/lunar_calendar.dart' show LunarDate;

export 'package:lunar_calendar/lunar_calendar.dart' show LunarDate;

/// Global getter for the app's lunar calendar.
///
/// Features call this instead of importing `package:lunar_calendar`, so the
/// engine can be replaced or faked in one place (ADR 0002).
LunarCalendarService get lunarCalendarService =>
    EngineLunarCalendarService.instance;

/// Vietnamese lunar calendar (UTC+7) as the app sees it.
///
/// Every method returns `null` for dates outside the supported lunar years
/// or for dates that do not exist; none of them guesses or shifts a date.
abstract interface class LunarCalendarService {
  /// Whether [lunarYear] is inside the engine's supported range.
  bool isSupportedYear(int lunarYear);

  /// Lunar date of the Gregorian day [solarDate] (time and zone ignored).
  LunarDate? toLunar(DateTime solarDate);

  /// Gregorian date (UTC midnight) of [date], or `null` if it does not exist.
  DateTime? toSolar(LunarDate date);

  /// Number of the leap month of [lunarYear], or `null` if there is none.
  int? leapMonthOf(int lunarYear);
}

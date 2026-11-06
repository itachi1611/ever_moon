/// Vietnamese lunar calendar engine (UTC+7).
///
/// Converts between Gregorian dates and Vietnamese lunar dates for lunar
/// years [minLunarYear] to [maxLunarYear], and answers which month of a year
/// is the leap month. The app reaches this package only through its own
/// `LunarCalendarService` interface.
library lunar_calendar;

export 'src/calendar/lunar_date.dart';
export 'src/calendar/lunar_month.dart';
export 'src/calendar/vietnamese_lunar_calendar.dart';
export 'src/supported_range.dart';

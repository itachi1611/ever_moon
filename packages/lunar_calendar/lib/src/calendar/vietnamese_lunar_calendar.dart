import '../astronomy/julian_day.dart';
import '../astronomy/principal_term.dart';
import '../supported_range.dart';
import 'lunar_date.dart';
import 'lunar_month.dart';
import 'month_builder.dart';

/// Converts between Gregorian dates and the Vietnamese lunar calendar (UTC+7).
///
/// Supports lunar years [minLunarYear] to [maxLunarYear]. Every query outside
/// that range, or for a date that does not exist, returns `null` (or an
/// empty list) instead of a guessed value.
///
/// Months are computed on demand and cached for the life of the instance;
/// share one instance (for example [VietnameseLunarCalendar.shared]).
class VietnameseLunarCalendar {
  /// Creates a calendar with its own cache.
  VietnameseLunarCalendar();

  /// Process-wide instance.
  static final VietnameseLunarCalendar shared = VietnameseLunarCalendar();

  final MonthBuilder _builder = MonthBuilder();

  /// Months of [lunarYear] in order, including its leap month.
  ///
  /// Empty when [lunarYear] is outside the supported range.
  List<LunarMonth> monthsOf(int lunarYear) => isSupportedLunarYear(lunarYear)
      ? _builder.monthsOfYear(lunarYear)
      : const [];

  /// Number of the leap month of [lunarYear], or `null` if the year has no
  /// leap month or is outside the supported range.
  int? leapMonthOf(int lunarYear) {
    for (final month in monthsOf(lunarYear)) {
      if (month.isLeap) return month.month;
    }
    return null;
  }

  /// Lunar date of the Gregorian day [solarDate].
  ///
  /// Only the year, month and day fields of [solarDate] are used; its time
  /// and time zone are ignored. Returns `null` outside the supported range.
  LunarDate? toLunar(DateTime solarDate) {
    // A lunar year spans at most two Gregorian years; skip the astronomy
    // for dates that cannot be in range.
    final year = solarDate.year;
    if (year < minLunarYear || year > maxLunarYear + 1) return null;
    final jdn = jdnFromCivil(solarDate.year, solarDate.month, solarDate.day);
    final month = _monthContaining(jdn, solarDate.year);
    if (month == null || !isSupportedLunarYear(month.lunarYear)) return null;
    return LunarDate(
      month.lunarYear,
      month.month,
      jdn - month.startJdn + 1,
      isLeapMonth: month.isLeap,
    );
  }

  /// Gregorian date (UTC midnight) of [date], or `null` if it does not exist.
  ///
  /// A date does not exist when the year is outside the supported range, the
  /// year has no such (leap) month, or the month is shorter than [date.day].
  /// No fallback is applied here; callers decide how to handle day 30.
  DateTime? toSolar(LunarDate date) {
    if (date.day < 1) return null;
    for (final month in monthsOf(date.year)) {
      if (month.month == date.month && month.isLeap == date.isLeapMonth) {
        if (date.day > month.length) return null;
        return civilFromJdn(month.startJdn + date.day - 1);
      }
    }
    return null;
  }

  /// Sun longitude of the Thanh Minh solar term, in degrees.
  static const double thanhMinhLongitude = 15;

  /// Gregorian date (UTC midnight) of Tết Thanh Minh in Gregorian [year]:
  /// the UTC+7 day on which the Sun reaches 15 degrees of longitude.
  ///
  /// Returns `null` outside the supported range.
  DateTime? thanhMinhOf(int year) {
    if (year < minLunarYear || year > maxLunarYear) return null;
    final jde = solarTermJde(year, thanhMinhLongitude);
    return civilFromJdn(localDayNumber(jdeToJdUt(jde)));
  }

  /// The month containing civil day [jdn] of Gregorian [year].
  ///
  /// Month 11 starts in late November or December, so the day lies in the
  /// span that starts in [year] or in the one that starts in [year] - 1.
  LunarMonth? _monthContaining(int jdn, int year) {
    for (final spanYear in [year, year - 1]) {
      for (final month in _builder.span(spanYear)) {
        if (month.containsJdn(jdn)) return month;
      }
    }
    return null;
  }
}

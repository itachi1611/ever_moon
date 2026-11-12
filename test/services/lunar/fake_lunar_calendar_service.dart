import 'package:ever_moon/services/lunar/lunar_calendar_service.dart';

/// Synthetic calendar for rule tests; its dates mean nothing astronomically.
///
/// Lunar year Y occupies consecutive days from `DateTime.utc(Y)`. Every month
/// has 30 days unless listed in [shortMonths] (29 days). A year listed in
/// [leapMonths] has a 30-day leap month right after the regular one.
class FakeLunarCalendarService implements LunarCalendarService {
  /// Creates the fake for lunar years [firstYear] to [lastYear].
  FakeLunarCalendarService({
    this.firstYear = 2000,
    this.lastYear = 2010,
    this.leapMonths = const {},
    this.shortMonths = const {},
  });

  /// First supported lunar year.
  final int firstYear;

  /// Last supported lunar year.
  final int lastYear;

  /// Leap month number by lunar year.
  final Map<int, int> leapMonths;

  /// Regular months with 29 days, as (year, month).
  final Set<(int, int)> shortMonths;

  @override
  bool isSupportedYear(int lunarYear) =>
      lunarYear >= firstYear && lunarYear <= lastYear;

  @override
  int? leapMonthOf(int lunarYear) =>
      isSupportedYear(lunarYear) ? leapMonths[lunarYear] : null;

  @override
  DateTime? toSolar(LunarDate date) {
    for (final month in _months(date.year)) {
      if (month.month == date.month && month.isLeap == date.isLeapMonth) {
        if (date.day < 1 || date.day > month.length) return null;
        return month.start.add(Duration(days: date.day - 1));
      }
    }
    return null;
  }

  @override
  LunarDate? toLunar(DateTime solarDate) {
    final day = DateTime.utc(solarDate.year, solarDate.month, solarDate.day);
    for (final month in _months(solarDate.year)) {
      final offset = day.difference(month.start).inDays;
      if (offset >= 0 && offset < month.length) {
        return LunarDate(
          solarDate.year,
          month.month,
          offset + 1,
          isLeapMonth: month.isLeap,
        );
      }
    }
    return null;
  }

  List<_FakeMonth> _months(int year) {
    if (!isSupportedYear(year)) return const [];
    final months = <_FakeMonth>[];
    var start = DateTime.utc(year);
    for (var number = 1; number <= 12; number++) {
      final length = shortMonths.contains((year, number)) ? 29 : 30;
      months.add(_FakeMonth(number, false, start, length));
      start = start.add(Duration(days: length));
      if (leapMonths[year] == number) {
        months.add(_FakeMonth(number, true, start, 30));
        start = start.add(const Duration(days: 30));
      }
    }
    return months;
  }
}

class _FakeMonth {
  const _FakeMonth(this.month, this.isLeap, this.start, this.length);

  final int month;
  final bool isLeap;
  final DateTime start;
  final int length;
}

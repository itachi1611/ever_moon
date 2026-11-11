import 'package:ever_moon/models/anniversary_date.dart';
import 'package:ever_moon/services/lunar/lunar_calendar_service.dart';

/// One holding of an anniversary: the lunar date it falls on that year and
/// the matching Gregorian day (UTC midnight).
typedef AnniversaryHolding = ({LunarDate lunar, DateTime solar});

/// Turns an [AnniversaryDate] into real dates, following ADR 0001.
///
/// All leap-month and day-30 decisions live here so the rule can change in
/// one place if the family's custom turns out to differ.
class AnniversaryResolver {
  /// Creates a resolver over [calendar] (inject a fake in tests).
  const AnniversaryResolver(this._calendar);

  final LunarCalendarService _calendar;

  /// Longest lunar month; the only day that may fall back.
  static const int _lastDay = 30;

  /// Whether the "died in a leap month" choice applies: [deathYear] has a
  /// leap month with the number [lunarMonth]. The UI shows the toggle only
  /// in that case.
  bool canBeLeapMonth({required int deathYear, required int lunarMonth}) =>
      _calendar.leapMonthOf(deathYear) == lunarMonth;

  /// [date] with [AnniversaryDate.diedInLeapMonth] cleared when it cannot
  /// apply, so stored values are always meaningful.
  AnniversaryDate normalize(AnniversaryDate date) {
    final deathYear = date.deathYear;
    final applies =
        deathYear != null &&
        canBeLeapMonth(deathYear: deathYear, lunarMonth: date.lunarMonth);
    return applies ? date : date.withDiedInLeapMonth(false);
  }

  /// The lunar date the anniversary is held on in [lunarYear], or `null`
  /// when [lunarYear] is outside the supported range.
  LunarDate? lunarDateIn(AnniversaryDate date, int lunarYear) {
    if (!_calendar.isSupportedYear(lunarYear)) return null;
    final candidate = LunarDate(
      lunarYear,
      date.lunarMonth,
      date.lunarDay,
      isLeapMonth: _usesLeapMonth(date, lunarYear),
    );
    if (_calendar.toSolar(candidate) != null) return candidate;
    if (date.lunarDay != _lastDay) return null;
    // Day 30 in a 29-day month is held on day 29 (ADR 0001).
    return LunarDate(
      lunarYear,
      candidate.month,
      _lastDay - 1,
      isLeapMonth: candidate.isLeapMonth,
    );
  }

  /// Gregorian date (UTC midnight) of the anniversary in [lunarYear].
  DateTime? solarDateIn(AnniversaryDate date, int lunarYear) {
    final lunar = lunarDateIn(date, lunarYear);
    return lunar == null ? null : _calendar.toSolar(lunar);
  }

  /// First occurrence on or after the Gregorian day [today] (time ignored),
  /// as UTC midnight; `null` outside the supported range.
  DateTime? nextOccurrence(AnniversaryDate date, DateTime today) =>
      nextHolding(date, today)?.solar;

  /// Like [nextOccurrence], with the lunar date it is held on that year
  /// (which may be the leap month or day 29, see ADR 0001).
  AnniversaryHolding? nextHolding(AnniversaryDate date, DateTime today) {
    final currentYear = _calendar.toLunar(today)?.year;
    if (currentYear == null) return null;
    final day = DateTime.utc(today.year, today.month, today.day);
    for (final year in [currentYear, currentYear + 1]) {
      final lunar = lunarDateIn(date, year);
      final solar = lunar == null ? null : _calendar.toSolar(lunar);
      if (lunar != null && solar != null && !solar.isBefore(day)) {
        return (lunar: lunar, solar: solar);
      }
    }
    return null;
  }

  /// ADR 0001: the leap month is used only when the death was in a leap
  /// month (a flag that survives normalization) and [lunarYear] repeats that
  /// same month number.
  bool _usesLeapMonth(AnniversaryDate date, int lunarYear) =>
      normalize(date).diedInLeapMonth &&
      _calendar.leapMonthOf(lunarYear) == date.lunarMonth;
}

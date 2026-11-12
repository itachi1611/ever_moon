import 'package:ever_moon/models/anniversary.dart';
import 'package:ever_moon/services/lunar/anniversary_resolver.dart';
import 'package:ever_moon/services/lunar/lunar_calendar_service.dart';
import 'package:ever_moon/services/lunar/lunar_holidays.dart';

import 'calendar_models.dart';

/// Puts lunar dates, holidays and anniversaries on Gregorian days
/// (plan 0005, U5). Pure: same input, same output.
///
/// Anniversary dates come only from [AnniversaryResolver] (ADR 0001) and
/// lunar dates only from [LunarCalendarService] (UI-9).
class CalendarBuilder {
  /// Creates the builder.
  const CalendarBuilder(this._calendar, this._resolver);

  final LunarCalendarService _calendar;
  final AnniversaryResolver _resolver;

  static const _oneDay = Duration(days: 1);

  /// Every day from [first] to [last] (UTC midnights, inclusive).
  List<CalendarDay> days(
    DateTime first,
    DateTime last,
    List<Anniversary> records,
  ) {
    final held = _heldBetween(first, last, records);
    return [
      for (var day = first; !day.isAfter(last); day = day.add(_oneDay))
        _day(day, held[day] ?? const []),
    ];
  }

  /// Anniversary and festival counts for each month of [solarYear].
  List<MonthSummary> year(int solarYear, List<Anniversary> records) {
    final first = DateTime.utc(solarYear);
    final last = DateTime.utc(solarYear, 12, 31);
    final held = _heldBetween(first, last, records);
    final festivals = _festivalsBetween(first, last);
    return [
      for (var month = 1; month <= 12; month++)
        MonthSummary(
          month: month,
          anniversaries: _countIn(month, held),
          festivals: festivals.where((d) => d.month == month).length,
        ),
    ];
  }

  CalendarDay _day(DateTime solar, List<Anniversary> held) {
    final lunar = _calendar.toLunar(solar);
    final onLunarDay = lunar == null ? null : LunarHoliday.on(lunar);
    return CalendarDay(
      solar: solar,
      lunar: lunar,
      holidays: [?onLunarDay],
      anniversaries: [...held]..sort((a, b) => a.name.compareTo(b.name)),
    );
  }

  /// Anniversaries by the day they are held, within [first]..[last].
  Map<DateTime, List<Anniversary>> _heldBetween(
    DateTime first,
    DateTime last,
    List<Anniversary> records,
  ) {
    final held = <DateTime, List<Anniversary>>{};
    for (final year in _lunarYears(first, last)) {
      for (final record in records) {
        final solar = _resolver.solarDateIn(record.date, year);
        if (solar != null && _within(solar, first, last)) {
          (held[solar] ??= []).add(record);
        }
      }
    }
    return held;
  }

  /// Days with a named festival within [first]..[last].
  Set<DateTime> _festivalsBetween(DateTime first, DateTime last) => {
    for (final year in _lunarYears(first, last))
      for (final festival in LunarFestival.values)
        ?_inRange(
          _calendar.toSolar(LunarDate(year, festival.month, festival.day)),
          first,
          last,
        ),
  };

  /// Lunar years that overlap [first]..[last]; a Gregorian range spans at
  /// most two, plus one more when the start is before Tết.
  List<int> _lunarYears(DateTime first, DateTime last) {
    final from = _calendar.toLunar(first)?.year ?? first.year - 1;
    final to = _calendar.toLunar(last)?.year ?? last.year;
    return [for (var year = from; year <= to; year++) year];
  }

  static int _countIn(int month, Map<DateTime, List<Anniversary>> held) => held
      .entries
      .where((entry) => entry.key.month == month)
      .fold(0, (sum, entry) => sum + entry.value.length);

  static DateTime? _inRange(DateTime? day, DateTime first, DateTime last) =>
      day != null && _within(day, first, last) ? day : null;

  static bool _within(DateTime day, DateTime first, DateTime last) =>
      !day.isBefore(first) && !day.isAfter(last);
}

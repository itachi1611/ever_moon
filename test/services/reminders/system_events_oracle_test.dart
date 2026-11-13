// System-event reminders over a whole lunar year on the real engine (plan
// 0006, N4; RS-6). Expected dates come from the oracle month table of
// packages/lunar_calendar, never from the planner or the engine under test.
// Years whose months differ by convention are skipped, as in the resolver's
// engine test.
import 'dart:convert';
import 'dart:io';

import 'package:ever_moon/models/app_settings.dart';
import 'package:ever_moon/services/lunar/anniversary_resolver.dart';
import 'package:ever_moon/services/lunar/lunar_calendar_service.dart';
import 'package:ever_moon/services/lunar/lunar_holidays.dart';
import 'package:ever_moon/services/reminders/planned_reminder.dart';
import 'package:ever_moon/services/reminders/reminder_planner.dart';
import 'package:flutter_test/flutter_test.dart';

const _fixtures = 'packages/lunar_calendar/test/fixtures';

/// Oracle month row: lunar year, month, leap flag, start day (UTC), days.
typedef _Row = (int year, int month, bool isLeap, DateTime start, int days);

Map<String, Object?> _load(String name) =>
    jsonDecode(File('$_fixtures/$name').readAsStringSync())
        as Map<String, Object?>;

List<_Row> _rows() {
  final pinned = {
    for (final item
        in (_load('convention_differences.json')['differences']!
                as List<Object?>)
            .cast<Map<String, Object?>>())
      ((item['month']! as List<Object?>)[0] as int),
  };
  return [
    for (final raw
        in (_load('oracle_months.json')['months']! as List<Object?>)
            .cast<List<Object?>>())
      if (!pinned.contains(raw[0]))
        (
          raw[0] as int,
          raw[1] as int,
          raw[2] == 1,
          DateTime.parse('${raw[3]}T00:00:00Z'),
          raw[4] as int,
        ),
  ];
}

const _all = AppSettings(
  remindFirstDay: true,
  remindFullMoon: true,
  remindFestivals: true,
);

/// The reminders a lunar [year] should have, worked out from its oracle
/// month rows alone.
Map<DateTime, LunarHoliday> _expected(List<_Row> rows, int year) {
  final result = <DateTime, LunarHoliday>{};
  for (final (_, month, isLeap, start, days) in rows.where(
    (r) => r.$1 == year,
  )) {
    LunarFestival? festivalOn(int day) => isLeap
        ? null
        : LunarFestival.values
              .where((f) => f.month == month && f.day == day)
              .firstOrNull;
    for (final day in [1, 15]) {
      final festival = festivalOn(day);
      result[start.add(Duration(days: day - 1))] = festival != null
          ? FestivalHoliday(festival)
          : day == 1
          ? FirstDayHoliday(month, isLeap)
          : FullMoonHoliday(month, isLeap);
    }
    for (final festival in LunarFestival.values) {
      final onFixedDay = !isLeap && festival.month == month;
      if (onFixedDay && festival.day <= days) {
        result[start.add(Duration(days: festival.day - 1))] = FestivalHoliday(
          festival,
        );
      }
    }
  }
  return result;
}

void main() {
  final rows = _rows();
  final planner = ReminderPlanner(
    resolver: AnniversaryResolver(lunarCalendarService),
    calendar: lunarCalendarService,
  );

  /// Rows of [year], oldest first; the year ends on the last row's last day.
  List<_Row> yearRows(int year) => rows.where((r) => r.$1 == year).toList();

  /// Reminders planned from the eve of [year] up to its last day.
  List<PlannedReminder> planned(int year) {
    final first = yearRows(year).first.$4;
    final last = yearRows(year).last;
    final end = last.$4.add(Duration(days: last.$5 - 1));
    final result = planner.plan(
      anniversaries: const [],
      settings: _all,
      now: DateTime(first.year, first.month, first.day - 1, 6),
    );
    return [
      for (final r in result)
        if (!r.eventDay.isAfter(end)) r,
    ];
  }

  // A year of 12 months is at most 355 days, so the 365-day window covers
  // all of it; a leap year can be longer and is checked as far as it reaches.
  final plainYear = [
    for (var y = 2020; y <= 2100; y++)
      if (yearRows(y).length == 12) y,
  ].first;
  final leapYear = [
    for (var y = 2020; y <= 2100; y++)
      if (yearRows(y).length == 13) y,
  ].first;

  test('RS-6 a 12-month year: every mùng 1, rằm and festival, once each', () {
    final expected = _expected(rows, plainYear);

    final result = {for (final r in planned(plainYear)) r.eventDay: r.holiday};

    expect(planned(plainYear), hasLength(result.length));
    expect(result, expected);
  });

  test('RS-6 reminders fire at 07:00 on the day itself', () {
    for (final r in planned(plainYear)) {
      expect(
        r.fireAt,
        DateTime(r.eventDay.year, r.eventDay.month, r.eventDay.day, 7),
      );
      expect(r.kind, ReminderKind.systemEvent);
    }
  });

  test('RS-6 a leap year adds the leap month days, not its festivals', () {
    final expected = _expected(rows, leapYear);
    final leapRow = yearRows(leapYear).firstWhere((r) => r.$3);

    final result = {for (final r in planned(leapYear)) r.eventDay: r.holiday};

    // Everything planned is expected, and nothing expected is missing before
    // the 365-day window ends.
    final windowEnd = DateTime.utc(
      yearRows(leapYear).first.$4.year,
      yearRows(leapYear).first.$4.month,
      yearRows(leapYear).first.$4.day - 1 + 365,
    );
    expect(result.entries.every((e) => expected[e.key] == e.value), isTrue);
    expect({
      for (final e in expected.entries)
        if (e.key.isBefore(windowEnd)) e.key: e.value,
    }, result);
    expect(result[leapRow.$4], FirstDayHoliday(leapRow.$2, true));
    expect(
      result[leapRow.$4.add(const Duration(days: 14))],
      FullMoonHoliday(leapRow.$2, true),
    );
  });
}

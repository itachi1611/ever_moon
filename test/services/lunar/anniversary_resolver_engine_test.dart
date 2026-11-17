// Integration of the resolver with the real engine (plan 0003, AR-2 to AR-4,
// AR-8). Years, months and expected dates are taken from the oracle
// fixtures of packages/lunar_calendar, never written by hand. Years whose
// months differ by convention (convention_differences.json) are skipped.
import 'dart:convert';
import 'dart:io';

import 'package:ever_moon/models/anniversary_date.dart';
import 'package:ever_moon/services/lunar/anniversary_resolver.dart';
import 'package:ever_moon/services/lunar/lunar_calendar_service.dart';
import 'package:flutter_test/flutter_test.dart';

const _fixtures = 'packages/lunar_calendar/test/fixtures';

/// Oracle month row: lunar year, month, leap flag, ISO start date, days.
typedef _Row = (int year, int month, bool isLeap, DateTime start, int days);

Map<String, Object?> _load(String name) =>
    jsonDecode(File('$_fixtures/$name').readAsStringSync())
        as Map<String, Object?>;

List<_Row> _rows() {
  final pinned = {
    for (final item
        in (_load('convention_differences.json')['differences']
                as List<Object?>)
            .cast<Map<String, Object?>>())
      ((item['month'] as List<Object?>)[0] as int),
  };
  return [
    for (final raw
        in (_load('oracle_months.json')['months'] as List<Object?>)
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

void main() {
  final resolver = AnniversaryResolver(lunarCalendarService);
  final rows = _rows();

  _Row rowOf(int year, int month, {bool isLeap = false}) =>
      rows.firstWhere((r) => r.$1 == year && r.$2 == month && r.$3 == isLeap);

  test('AR-2 and AR-3 a leap-month death across leap and plain years', () {
    final leapRow = rows.firstWhere((r) => r.$3 && r.$1 >= 2000);
    final (leapYear, month, _, leapStart, _) = leapRow;
    final date = resolver.normalize(
      AnniversaryDate(
        lunarDay: 1,
        lunarMonth: month,
        deathYear: leapYear,
        diedInLeapMonth: true,
      ),
    );
    expect(date.diedInLeapMonth, isTrue);
    expect(resolver.solarDateIn(date, leapYear), leapStart);
    final plainYear = leapYear + 1;
    expect(lunarCalendarService.leapMonthOf(plainYear), isNot(month));
    expect(resolver.solarDateIn(date, plainYear), rowOf(plainYear, month).$4);
  });

  test('AR-4 day 30 in real 29- and 30-day months', () {
    final short = rows.firstWhere((r) => !r.$3 && r.$5 == 29 && r.$1 >= 2000);
    final long = rows.firstWhere((r) => !r.$3 && r.$5 == 30 && r.$1 >= 2000);
    final onShort = AnniversaryDate(lunarDay: 30, lunarMonth: short.$2);
    final onLong = AnniversaryDate(lunarDay: 30, lunarMonth: long.$2);
    expect(
      resolver.solarDateIn(onShort, short.$1),
      short.$4.add(const Duration(days: 28)),
    );
    expect(
      resolver.solarDateIn(onLong, long.$1),
      long.$4.add(const Duration(days: 29)),
    );
  });

  test('AR-7 the service answers through the app interface', () {
    final first = rows.first;
    expect(
      lunarCalendarService.toLunar(first.$4),
      LunarDate(first.$1, first.$2, 1, isLeapMonth: first.$3),
    );
  });
}

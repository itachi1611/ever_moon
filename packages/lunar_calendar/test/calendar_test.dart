// Slice S3c: public API against published anchors and range rules
// (plan 0001, LC-2 and LC-4). Expected dates come only from fixtures.
import 'package:lunar_calendar/lunar_calendar.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  final calendar = VietnameseLunarCalendar();
  final anchors = loadFixture('anchors.json');

  group('LC-2 published anchors', () {
    test('Tết dates', () {
      final tet = anchors['tet_vietnam'] as Map<String, Object?>;
      for (final MapEntry(:key, :value) in tet.entries) {
        final solar = calendar.toSolar(LunarDate(int.parse(key), 1, 1));
        expect(solar == null ? null : isoDate(solar), value, reason: key);
      }
    });

    test('month spans from the 1984 and 1985 tables', () {
      final spans = (anchors['month_spans'] as List<Object?>)
          .cast<Map<String, Object?>>();
      for (final span in spans) {
        final month = calendar
            .monthsOf(span['lunar_year'] as int)
            .firstWhere(
              (m) =>
                  m.month == span['month'] &&
                  (m.isLeap ? 1 : 0) == span['is_leap'],
            );
        expect(isoDate(month.start), span['start'], reason: '$span');
        final last = month.start.add(Duration(days: month.length - 1));
        expect(isoDate(last), span['end'], reason: '$span');
      }
    });

    test('1984 has no leap month and the 1985 leap month span', () {
      final noLeap = (anchors['years_without_leap_month'] as List<Object?>)
          .cast<int>();
      for (final year in noLeap) {
        expect(calendar.leapMonthOf(year), isNull, reason: '$year');
      }
      final leap = (anchors['leap_month_spans_without_number'] as List<Object?>)
          .cast<Map<String, Object?>>()
          .first;
      final month = calendar
          .monthsOf(leap['lunar_year'] as int)
          .firstWhere((m) => m.isLeap);
      expect(isoDate(month.start), leap['start']);
      final last = month.start.add(Duration(days: month.length - 1));
      expect(isoDate(last), leap['end']);
    });
  });

  group('round trip over every expected month', () {
    test('first and last day convert both ways', () {
      for (final MapEntry(key: (year, month, leap), value: (start, days))
          in expectedMonths().entries) {
        final first = LunarDate(year, month, 1, isLeapMonth: leap == 1);
        final last = LunarDate(year, month, days, isLeapMonth: leap == 1);
        final firstSolar = DateTime.parse('${start}T00:00:00Z');
        final lastSolar = firstSolar.add(Duration(days: days - 1));
        expect(calendar.toLunar(firstSolar), first);
        expect(calendar.toLunar(lastSolar), last);
        expect(calendar.toSolar(first), firstSolar);
        expect(calendar.toSolar(last), lastSolar);
      }
    });
  });

  group('LC-4 out of range or non-existent input returns null', () {
    late List<LunarMonth> firstYear;
    setUpAll(() => firstYear = calendar.monthsOf(minLunarYear));

    test('years outside the supported range', () {
      expect(calendar.monthsOf(minLunarYear - 1), isEmpty);
      expect(calendar.monthsOf(maxLunarYear + 1), isEmpty);
      expect(calendar.leapMonthOf(maxLunarYear + 1), isNull);
      expect(calendar.toSolar(const LunarDate(maxLunarYear + 1, 1, 1)), isNull);
      final dayBeforeFirst = firstYear.first.start.subtract(
        const Duration(days: 1),
      );
      expect(calendar.toLunar(dayBeforeFirst), isNull);
      expect(calendar.toLunar(DateTime.utc(maxLunarYear + 2)), isNull);
    });

    test('impossible month, day or leap flag', () {
      expect(calendar.toSolar(const LunarDate(minLunarYear, 13, 1)), isNull);
      expect(calendar.toSolar(const LunarDate(minLunarYear, 1, 0)), isNull);
      expect(calendar.toSolar(const LunarDate(minLunarYear, 1, 31)), isNull);
      final regular = firstYear.firstWhere((m) => !m.isLeap);
      final noLeap = LunarDate(
        minLunarYear,
        regular.month,
        1,
        isLeapMonth: true,
      );
      if (calendar.leapMonthOf(minLunarYear) != regular.month) {
        expect(calendar.toSolar(noLeap), isNull);
      }
    });

    test('day 30 of a 29-day month is not shifted', () {
      final short = firstYear.firstWhere((m) => m.length == 29);
      final date = LunarDate(
        short.lunarYear,
        short.month,
        30,
        isLeapMonth: short.isLeap,
      );
      expect(calendar.toSolar(date), isNull);
    });
  });
}

// Slice S3b: lunar months against the oracle fixtures (plan 0001, LC-1, LC-3).
import 'package:lunar_calendar/lunar_calendar.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  final calendar = VietnameseLunarCalendar();
  late Map<MonthKey, MonthValue> expected;
  late Map<MonthKey, MonthValue> actual;

  setUpAll(() {
    expected = expectedMonths();
    actual = {
      for (var year = minLunarYear; year <= maxLunarYear; year++)
        for (final m in calendar.monthsOf(year))
          (m.lunarYear, m.month, m.isLeap ? 1 : 0): (isoDate(m.start), m.length),
    };
  });

  test('LC-1 every month matches the oracle, pinned months follow D7', () {
    final missing = expected.keys.where((k) => !actual.containsKey(k));
    final extra = actual.keys.where((k) => !expected.containsKey(k));
    final wrong = expected.keys
        .where((k) => actual.containsKey(k) && actual[k] != expected[k]);
    expect(missing, isEmpty, reason: 'months the engine did not produce');
    expect(extra, isEmpty, reason: 'months the oracle does not have');
    expect(wrong.map((k) => (k, actual[k], expected[k])), isEmpty);
  });

  test('LC-1 months of a year are contiguous', () {
    for (var year = minLunarYear; year <= maxLunarYear; year++) {
      final months = calendar.monthsOf(year);
      for (var i = 1; i < months.length; i++) {
        final previous = months[i - 1];
        expect(months[i].startJdn, previous.startJdn + previous.length,
            reason: '$year: $previous then ${months[i]}');
      }
    }
  });

  test('LC-3 leapMonthOf matches the leap rows of the expected months', () {
    final leapByYear = {
      for (final (year, month, isLeap) in expected.keys)
        if (isLeap == 1) year: month,
    };
    for (var year = minLunarYear; year <= maxLunarYear; year++) {
      expect(calendar.leapMonthOf(year), leapByYear[year], reason: '$year');
    }
  });

  test('LC-3 leap months equal the oracle outside the pinned years', () {
    final oracle = loadFixture('oracle_months.json')['leap_months']
        as Map<String, Object?>;
    final pinned = pinnedLeapYears();
    for (var year = minLunarYear; year <= maxLunarYear; year++) {
      if (pinned.contains(year)) continue;
      expect(calendar.leapMonthOf(year), oracle['$year'], reason: '$year');
    }
  });
}

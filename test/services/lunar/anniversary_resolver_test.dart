// Rule tests for ADR 0001 on a synthetic calendar (plan 0003, AR-1 to AR-6).
// The fake's dates are arbitrary; only the month and day choices matter.
import 'package:ever_moon/models/anniversary_date.dart';
import 'package:ever_moon/services/lunar/anniversary_resolver.dart';
import 'package:ever_moon/services/lunar/lunar_calendar_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_lunar_calendar_service.dart';

void main() {
  // 2001 and 2004 repeat month 4; 2002 repeats month 6.
  final calendar = FakeLunarCalendarService(
    leapMonths: const {2001: 4, 2002: 6, 2004: 4},
    shortMonths: const {(2003, 4), (2004, 4)},
  );
  final resolver = AnniversaryResolver(calendar);

  const diedInLeap4 = AnniversaryDate(
      lunarDay: 10, lunarMonth: 4, deathYear: 2001, diedInLeapMonth: true);

  group('month choice', () {
    test('AR-1 no death year uses the regular month', () {
      const date = AnniversaryDate(lunarDay: 10, lunarMonth: 4);
      expect(resolver.lunarDateIn(date, 2004), const LunarDate(2004, 4, 10));
    });

    test('AR-1 not died in a leap month uses the regular month', () {
      const date = AnniversaryDate(lunarDay: 10, lunarMonth: 4, deathYear: 2001);
      expect(resolver.lunarDateIn(date, 2004), const LunarDate(2004, 4, 10));
    });

    test('AR-2 leap death in a year with the same leap month uses it', () {
      expect(resolver.lunarDateIn(diedInLeap4, 2004),
          const LunarDate(2004, 4, 10, isLeapMonth: true));
    });

    test('AR-3 leap death in a year without that leap month uses regular', () {
      expect(resolver.lunarDateIn(diedInLeap4, 2002), const LunarDate(2002, 4, 10));
      expect(resolver.lunarDateIn(diedInLeap4, 2003), const LunarDate(2003, 4, 10));
    });

    test('AR-5 a flag that cannot apply is ignored', () {
      // 2002 repeats month 6, not month 4.
      const wrongFlag = AnniversaryDate(
          lunarDay: 10, lunarMonth: 4, deathYear: 2002, diedInLeapMonth: true);
      expect(resolver.lunarDateIn(wrongFlag, 2004), const LunarDate(2004, 4, 10));
    });
  });

  group('day 30', () {
    test('AR-4 day 30 in a 29-day month falls back to day 29', () {
      const date = AnniversaryDate(lunarDay: 30, lunarMonth: 4);
      expect(resolver.lunarDateIn(date, 2003), const LunarDate(2003, 4, 29));
    });

    test('AR-4 day 30 stays in a 30-day month', () {
      const date = AnniversaryDate(lunarDay: 30, lunarMonth: 4);
      expect(resolver.lunarDateIn(date, 2002), const LunarDate(2002, 4, 30));
    });

    test('AR-4 day 30 in a 30-day leap month is not shifted', () {
      const date = AnniversaryDate(
          lunarDay: 30, lunarMonth: 4, deathYear: 2001, diedInLeapMonth: true);
      expect(resolver.lunarDateIn(date, 2004),
          const LunarDate(2004, 4, 30, isLeapMonth: true));
    });
  });

  group('leap toggle and normalization', () {
    test('AR-5 canBeLeapMonth only for the death year leap month', () {
      expect(resolver.canBeLeapMonth(deathYear: 2001, lunarMonth: 4), isTrue);
      expect(resolver.canBeLeapMonth(deathYear: 2001, lunarMonth: 5), isFalse);
      expect(resolver.canBeLeapMonth(deathYear: 2003, lunarMonth: 4), isFalse);
    });

    test('AR-5 normalize keeps a valid flag and clears the others', () {
      expect(resolver.normalize(diedInLeap4), diedInLeap4);
      const noYear =
          AnniversaryDate(lunarDay: 1, lunarMonth: 4, diedInLeapMonth: true);
      expect(resolver.normalize(noYear).diedInLeapMonth, isFalse);
      const noLeap = AnniversaryDate(
          lunarDay: 1, lunarMonth: 4, deathYear: 2003, diedInLeapMonth: true);
      expect(resolver.normalize(noLeap).diedInLeapMonth, isFalse);
    });
  });

  group('solar dates and next occurrence', () {
    const date = AnniversaryDate(lunarDay: 10, lunarMonth: 4);

    test('solarDateIn converts the chosen lunar date', () {
      expect(resolver.solarDateIn(date, 2002),
          calendar.toSolar(const LunarDate(2002, 4, 10)));
    });

    test('AR-6 today, later this year, or next year', () {
      final thisYear = resolver.solarDateIn(date, 2002);
      final nextYear = resolver.solarDateIn(date, 2003);
      expect(thisYear, isNotNull);
      final onDay = thisYear ?? DateTime.utc(0);
      expect(resolver.nextOccurrence(date, onDay), thisYear);
      expect(resolver.nextOccurrence(
          date, onDay.subtract(const Duration(days: 1))), thisYear);
      expect(resolver.nextOccurrence(date, onDay.add(const Duration(days: 1))),
          nextYear);
    });

    test('AR-6 null outside the supported range', () {
      expect(resolver.lunarDateIn(date, 2011), isNull);
      expect(resolver.nextOccurrence(date, DateTime.utc(1990)), isNull);
    });
  });
}

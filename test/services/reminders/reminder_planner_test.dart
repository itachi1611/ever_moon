// Reminder planner (plan 0006, N1; RS-1 to RS-6).
//
// Rule tests run on the synthetic FakeLunarCalendarService, where lunar year
// Y is 12 months of 30 days starting on 1 January of Y, so expected dates are
// worked out by hand from that definition. One test uses the real engine and
// takes its expected date from the oracle fixtures, never from the planner.
import 'dart:convert';
import 'dart:io';

import 'package:ever_moon/models/anniversary.dart';
import 'package:ever_moon/models/anniversary_date.dart';
import 'package:ever_moon/models/app_settings.dart';
import 'package:ever_moon/services/lunar/anniversary_resolver.dart';
import 'package:ever_moon/services/lunar/lunar_calendar_service.dart';
import 'package:ever_moon/services/lunar/lunar_holidays.dart';
import 'package:ever_moon/services/reminders/planned_reminder.dart';
import 'package:ever_moon/services/reminders/reminder_planner.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lunar/fake_lunar_calendar_service.dart';

final _stamp = DateTime.utc(2000);

Anniversary _anniversary(
  String id, {
  int day = 10,
  int month = 1,
  int? deathYear,
  bool leap = false,
  bool enabled = true,
  int daysBefore = 0,
  int minute = 7 * 60,
}) => Anniversary(
  id: id,
  name: 'Name $id',
  date: AnniversaryDate(
    lunarDay: day,
    lunarMonth: month,
    deathYear: deathYear,
    diedInLeapMonth: leap,
  ),
  reminderEnabled: enabled,
  remindDaysBefore: daysBefore,
  remindMinuteOfDay: minute,
  createdAt: _stamp,
  updatedAt: _stamp,
);

const _noSystemEvents = AppSettings(
  remindFirstDay: false,
  remindFullMoon: false,
  remindFestivals: false,
);

ReminderPlanner _planner(LunarCalendarService calendar) => ReminderPlanner(
  resolver: AnniversaryResolver(calendar),
  calendar: calendar,
);

void main() {
  final fake = FakeLunarCalendarService();
  final planner = _planner(fake);
  final morning = DateTime(2005, 1, 1, 6);

  List<PlannedReminder> plan(
    List<Anniversary> items, {
    AppSettings settings = _noSystemEvents,
    DateTime? now,
    ReminderPlanner? using,
  }) => (using ?? planner).plan(
    anniversaries: items,
    settings: settings,
    now: now ?? morning,
  );

  group('anniversaries', () {
    test('RS-1 fires the lead time before the day, at the stored time', () {
      final result = plan([
        _anniversary('a', daysBefore: 3, minute: 8 * 60 + 30),
      ]);

      expect(result, hasLength(1));
      expect(result.single.fireAt, DateTime(2005, 1, 7, 8, 30));
      expect(result.single.eventDay, DateTime.utc(2005, 1, 10));
      expect(result.single.daysBefore, 3);
      expect(result.single.anniversaryId, 'a');
    });

    test('RS-1 a lead time can cross into the previous month', () {
      final result = plan([_anniversary('a', day: 2, daysBefore: 7)]);

      // The 2005-01-02 event is reminded on 2004-12-26, already past; the
      // 2006-01-02 event is reminded on 2005-12-26, inside the window.
      expect(result.single.fireAt, DateTime(2005, 12, 26, 7));
      expect(result.single.eventDay, DateTime.utc(2006, 1, 2));
      final later = plan([
        _anniversary('a', day: 2, month: 2, daysBefore: 7),
      ], now: DateTime(2005, 1, 1, 6));
      // Lunar month 2 starts 2005-01-31, so day 2 is 2005-02-01.
      expect(later.single.fireAt, DateTime(2005, 1, 25, 7));
    });

    test('RS-2 a disabled reminder produces nothing', () {
      expect(plan([_anniversary('a', enabled: false)]), isEmpty);
    });

    test('RS-2 a date the engine cannot resolve does not stop the others', () {
      final lastYear = DateTime(2010, 1, 1, 6);
      final result = plan([
        _anniversary('off', enabled: false),
        _anniversary('on', day: 20),
      ], now: lastYear);

      // Lunar year 2011 is unsupported: only the 2010 occurrence remains.
      expect(result.map((r) => r.anniversaryId), ['on']);
      expect(result.single.eventDay, DateTime.utc(2010, 1, 20));
    });

    test('RS-2 outside the supported years plans nothing', () {
      expect(plan([_anniversary('a')], now: DateTime(1990, 6, 1)), isEmpty);
    });

    test('RS-3 a time that has passed today moves to the next year', () {
      final result = plan([
        _anniversary('a', day: 1),
      ], now: DateTime(2005, 1, 1, 8));

      expect(result.single.fireAt, DateTime(2006, 1, 1, 7));
      expect(result.single.eventDay, DateTime.utc(2006, 1, 1));
    });

    test('RS-3 a time exactly equal to now is skipped', () {
      final result = plan([
        _anniversary('a', day: 1),
      ], now: DateTime(2005, 1, 1, 7));

      // Nothing at 07:00 today; next year's is exactly 365 days away, which
      // the window excludes.
      expect(result, isEmpty);
    });

    test('RS-3 an occurrence beyond the window is not planned', () {
      // 2006-01-10 is 374 days after 2005-01-01.
      final result = plan([_anniversary('a', day: 10)]);

      expect(result.map((r) => r.eventDay.year), [2005]);
    });

    test('RS-4 day 30 in a 29-day month is held on day 29', () {
      final calendar = FakeLunarCalendarService(shortMonths: {(2005, 1)});
      final result = plan([
        _anniversary('a', day: 30),
      ], using: _planner(calendar));

      expect(result.single.eventDay, DateTime.utc(2005, 1, 29));
    });

    test('RS-4 the leap month is used exactly as the resolver says', () {
      final calendar = FakeLunarCalendarService(leapMonths: {2005: 2});
      final resolver = AnniversaryResolver(calendar);
      final item = _anniversary(
        'a',
        day: 5,
        month: 2,
        deathYear: 2005,
        leap: true,
      );

      final result = plan([item], using: _planner(calendar));

      final leapDay = resolver.solarDateIn(item.date, 2005);
      final regularDay = resolver.solarDateIn(
        item.date.withDiedInLeapMonth(false),
        2005,
      );
      expect(leapDay, isNot(regularDay));
      expect(result.first.eventDay, leapDay);
      expect(result.first.lunar.isLeapMonth, isTrue);
    });
  });

  group('plan shape', () {
    // 120 anniversaries, one per (day 1 to 30, month 1 to 4), all in 2005.
    final many = [
      for (var m = 1; m <= 4; m++)
        for (var d = 1; d <= 30; d++) _anniversary('m$m-d$d', day: d, month: m),
    ];

    test('RS-5 keeps the nearest 60, earliest first', () {
      final result = plan(many);

      expect(result, hasLength(ReminderPlanner.maxPlanned));
      final times = result.map((r) => r.fireAt).toList();
      expect(times, [...times]..sort());
      // Months 1 and 2 hold exactly the 60 nearest days.
      expect(result.map((r) => r.lunar.month).toSet(), {1, 2});
    });

    test('RS-5 is deterministic, with unique ids', () {
      final first = plan(many.reversed.toList());
      final second = plan(many);

      expect(first, second);
      expect(first.map((r) => r.id).toSet(), hasLength(first.length));
    });

    test('RS-5 ids stay the same when only the lead time changes', () {
      final before = plan([_anniversary('a', daysBefore: 0)]).single.id;
      final after = plan([_anniversary('a', daysBefore: 3)]).single.id;

      expect(after, before);
    });
  });

  group('system events', () {
    List<PlannedReminder> system(AppSettings settings) =>
        plan(const [], settings: settings);

    test('RS-6 nothing when every switch is off', () {
      expect(system(_noSystemEvents), isEmpty);
    });

    test('RS-6 mùng 1 only: the first day of each month at 07:00', () {
      final result = system(
        const AppSettings(
          remindFirstDay: true,
          remindFullMoon: false,
          remindFestivals: false,
        ),
      );

      expect(result, hasLength(12));
      expect(result.first.fireAt, DateTime(2005, 1, 1, 7));
      expect(result.every((r) => r.lunar.day == 1), isTrue);
      expect(result.every((r) => r.holiday is FirstDayHoliday), isTrue);
    });

    test('RS-6 rằm only: day 15 of each month, festivals included', () {
      final result = system(
        const AppSettings(
          remindFirstDay: false,
          remindFullMoon: true,
          remindFestivals: false,
        ),
      );

      expect(result, hasLength(12));
      expect(result.first.fireAt, DateTime(2005, 1, 15, 7));
      expect(result.every((r) => r.holiday is FullMoonHoliday), isTrue);
    });

    test('RS-6 festivals only: the eight festival days', () {
      final result = system(
        const AppSettings(
          remindFirstDay: false,
          remindFullMoon: false,
          remindFestivals: true,
        ),
      );

      final festivals = result.map(
        (r) => (r.holiday as FestivalHoliday).festival,
      );
      expect(festivals.toSet(), LunarFestival.values.toSet());
      expect(result, hasLength(LunarFestival.values.length));
    });

    test('RS-6 a festival on mùng 1 or rằm is reminded once', () {
      final result = system(
        const AppSettings(
          remindFirstDay: true,
          remindFullMoon: true,
          remindFestivals: true,
        ),
      );

      final days = result.map((r) => r.eventDay).toList();
      expect(days.toSet(), hasLength(days.length));
      // Nguyên Đán (1/1) shows as a festival, not as mùng 1.
      expect(result.first.holiday, isA<FestivalHoliday>());
    });
  });

  group('real engine', () {
    test('RS-1 the solar date comes from the oracle fixtures', () {
      final raw =
          jsonDecode(
                File(
                  'packages/lunar_calendar/test/fixtures/oracle_months.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;
      final pinned = {
        for (final item
            in (jsonDecode(
                      File(
                        'packages/lunar_calendar/test/fixtures/'
                        'convention_differences.json',
                      ).readAsStringSync(),
                    )
                    as Map<String, Object?>)['differences']!
                as List<Object?>)
          (((item! as Map<String, Object?>)['month']! as List<Object?>)[0]
              as int),
      };
      final row = (raw['months']! as List<Object?>)
          .cast<List<Object?>>()
          .firstWhere(
            (r) =>
                r[0] == 2030 &&
                r[1] == 3 &&
                r[2] == 0 &&
                !pinned.contains(2030),
          );
      final start = DateTime.parse('${row[3]}T00:00:00Z');

      final result = _planner(lunarCalendarService).plan(
        anniversaries: [_anniversary('a', day: 5, month: 3, daysBefore: 1)],
        settings: _noSystemEvents,
        now: DateTime(2030, 1, 15, 6),
      );

      final expectedDay = start.add(const Duration(days: 4));
      final hit = result.firstWhere((r) => r.eventDay == expectedDay);
      expect(
        hit.fireAt,
        DateTime(expectedDay.year, expectedDay.month, expectedDay.day - 1, 7),
      );
    });
  });
}

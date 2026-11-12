// Plan 0005, U5: UI-9 (views, navigation, dates from the services) and the
// year counts of UI-14, with a synthetic calendar.
import 'package:ever_moon/pages/calendar/calendar_builder.dart';
import 'package:ever_moon/pages/calendar/calendar_cubit.dart';
import 'package:ever_moon/pages/calendar/calendar_models.dart';
import 'package:ever_moon/pages/calendar/calendar_state.dart';
import 'package:ever_moon/services/lunar/anniversary_resolver.dart';
import 'package:ever_moon/services/lunar/lunar_calendar_service.dart';
import 'package:ever_moon/services/lunar/lunar_holidays.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../services/lunar/fake_lunar_calendar_service.dart';
import '../anniversary_list/fake_anniversary_repository.dart';

void main() {
  final calendar = FakeLunarCalendarService();
  final resolver = AnniversaryResolver(calendar);
  final today = calendar.toSolar(const LunarDate(2002, 4, 5)) ?? DateTime(0);
  late FakeAnniversaryRepository repository;
  late CalendarCubit cubit;

  CalendarReady ready() => cubit.state as CalendarReady;

  Future<void> load() async {
    repository.emit([
      anniversary('a', 'Bà nội', 9, 4),
      anniversary('b', 'Ông nội', 5, 4),
    ]);
    await pumpEventQueue();
  }

  setUp(() {
    repository = FakeAnniversaryRepository();
    cubit = CalendarCubit(
      repository,
      CalendarBuilder(calendar, resolver),
      today: () => today,
    )..start();
  });
  tearDown(() => cubit.close());

  test('UI-9 opens on the month of today with today selected', () async {
    await load();
    final period = ready().period as MonthPeriod;
    expect(ready().selected, today);
    expect(period.month, today.month);
    expect(period.cells.length % DateTime.daysPerWeek, 0);
    final first = period.cells.whereType<CalendarDay>().first;
    // Monday-first grid: the empty cells before day 1 match its weekday.
    expect(period.cells.indexOf(first), first.solar.weekday - 1);
  });

  test('UI-9 anniversaries sit on the dates the resolver returns', () async {
    await load();
    final days = (ready().period as MonthPeriod).days;
    final expected = resolver.solarDateIn(
      anniversary('a', 'Bà nội', 9, 4).date,
      2002,
    );
    final held = days.where((d) => d.hasAnniversary).toList();
    expect(held.map((d) => d.solar), contains(expected));
    final day = held.firstWhere((d) => d.solar == expected);
    expect(day.anniversaries.single.name, 'Bà nội');
  });

  test('UI-9 lunar days come from the calendar service', () async {
    await load();
    for (final day in (ready().period as MonthPeriod).days) {
      expect(day.lunar, calendar.toLunar(day.solar));
      final lunar = day.lunar;
      final onLunarDay = lunar == null ? null : LunarHoliday.on(lunar);
      expect(day.holidays, [
        if (calendar.thanhMinhOf(day.solar.year) == day.solar)
          const ThanhMinhHoliday(),
        ?onLunarDay,
      ]);
    }
  });

  test('Tết Thanh Minh is marked on the day the service gives', () async {
    await load();
    final thanhMinh = calendar.thanhMinhOf(2002);
    final day = (ready().period as MonthPeriod).days.firstWhere(
      (d) => d.solar == thanhMinh,
    );
    expect(day.holidays, contains(const ThanhMinhHoliday()));
    expect(day.hasHoliday, isTrue);
  });

  test('UI-9 previous and next move a month, back to today', () async {
    await load();
    cubit.next();
    expect((ready().period as MonthPeriod).month, today.month + 1);
    expect(ready().selected.day, 1);
    cubit.previous();
    expect(ready().selected, today);
  });

  test('UI-9 the week view shows Monday to Sunday and steps a week', () async {
    await load();
    cubit.showView(CalendarView.week);
    final days = (ready().period as WeekPeriod).days;
    expect(days, hasLength(7));
    expect(days.first.solar.weekday, DateTime.monday);
    expect(days.map((d) => d.solar), contains(today));
    cubit.next();
    final next = (ready().period as WeekPeriod).days;
    expect(next.first.solar, days.first.solar.add(const Duration(days: 7)));
  });

  test('UI-14 the year view counts anniversaries and festivals only', () async {
    await load();
    cubit.showView(CalendarView.year);
    final period = ready().period as YearPeriod;
    expect(period.months, hasLength(12));
    expect(period.anniversaryCount, 2);
    // Distinct festival days, as the tiles say "ngày lễ".
    final festivalDays = {
      for (final f in LunarFestival.values)
        ?calendar.toSolar(LunarDate(2002, f.month, f.day)),
      ?calendar.thanhMinhOf(2002),
    };
    for (final summary in period.months) {
      expect(
        summary.festivals,
        festivalDays.where((d) => d.month == summary.month).length,
      );
    }
  });

  test('a year tile opens that month in the month view', () async {
    await load();
    cubit
      ..showView(CalendarView.year)
      ..openMonth(9);
    expect(ready().view, CalendarView.month);
    expect((ready().period as MonthPeriod).month, 9);
    expect(ready().selected, DateTime.utc(today.year, 9));
  });

  test('refresh moves today when the day changes', () async {
    var now = today;
    final rolling = CalendarCubit(
      repository,
      CalendarBuilder(calendar, resolver),
      today: () => now,
    )..start();
    await load();
    now = now.add(const Duration(days: 1));
    rolling.refresh();
    expect((rolling.state as CalendarReady).today, now);
    await rolling.close();
  });

  test('UI-13 delete goes through the repository', () async {
    await load();
    expect(await cubit.delete('a'), isTrue);
  });

  test('a read error shows the failure, retry listens again', () async {
    repository.fail(StateError('disk'));
    await pumpEventQueue();
    expect(cubit.state, const CalendarFailure());
    cubit.start();
    await load();
    expect(cubit.state, isA<CalendarReady>());
  });
}

// Plan 0005, U2: UI-1 (order and countdown) and UI-2 (empty) in the Cubit.
// Dates come from the synthetic calendar, so expected values are computed
// through it, never typed in.
import 'package:ever_moon/pages/anniversary_list/anniversary_list_cubit.dart';
import 'package:ever_moon/pages/anniversary_list/anniversary_list_state.dart';
import 'package:ever_moon/services/lunar/anniversary_resolver.dart';
import 'package:ever_moon/services/lunar/lunar_calendar_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../services/lunar/fake_lunar_calendar_service.dart';
import 'fake_anniversary_repository.dart';

void main() {
  final calendar = FakeLunarCalendarService();
  final resolver = AnniversaryResolver(calendar);
  // Lunar 5/4/2002 in the fake calendar.
  final today = calendar.toSolar(const LunarDate(2002, 4, 5)) ?? DateTime(0);
  late FakeAnniversaryRepository repository;
  late AnniversaryListCubit cubit;

  setUp(() {
    repository = FakeAnniversaryRepository();
    cubit = AnniversaryListCubit(repository, resolver, today: () => today);
  });

  tearDown(() => cubit.close());

  Future<AnniversaryListState> after(void Function() action) async {
    cubit.start();
    action();
    await pumpEventQueue();
    return cubit.state;
  }

  test('starts in loading', () {
    expect(cubit.state, const AnniversaryListLoading());
  });

  test('UI-2 an empty store gives the empty state', () async {
    expect(
      await after(() => repository.emit(const [])),
      const AnniversaryListEmpty(),
    );
  });

  test('UI-1 soonest first, ties by name, today counted as 0 days', () async {
    final state = await after(
      () => repository.emit([
        anniversary('a', 'Bác cả', 20, 4),
        anniversary('b', 'Ông nội', 5, 4),
        anniversary('c', 'Bà nội', 20, 4),
        anniversary('d', 'Cô Ba', 1, 4),
      ]),
    );
    expect(state, isA<AnniversaryListLoaded>());
    final items = (state as AnniversaryListLoaded).items;
    expect(items.map((i) => i.anniversary.name), [
      'Ông nội',
      'Bà nội',
      'Bác cả',
      'Cô Ba',
    ]);
    expect(items.first.isToday, isTrue);
    expect(state.today.length, 1);
    final day20 = calendar.toSolar(const LunarDate(2002, 4, 20));
    expect(items[1].solarDate, day20);
    expect(items[1].daysLeft, day20?.difference(today).inDays);
    // Day 1 of month 4 has passed, so it is next lunar year's.
    expect(items.last.lunarDate, const LunarDate(2003, 4, 1));
  });

  test('UI-1 the list follows every write', () async {
    await after(() => repository.emit([anniversary('a', 'A', 10, 4)]));
    repository.emit(const []);
    await pumpEventQueue();
    expect(cubit.state, const AnniversaryListEmpty());
  });

  test('a read error gives the failure state, retry listens again', () async {
    expect(
      await after(() => repository.fail(StateError('disk'))),
      const AnniversaryListFailure(),
    );
    cubit.start();
    repository.emit([anniversary('a', 'A', 10, 4)]);
    await pumpEventQueue();
    expect(cubit.state, isA<AnniversaryListLoaded>());
    expect(repository.watchCount, 2);
  });

  test('a refresh after a read error keeps the failure visible', () async {
    await after(() => repository.emit([anniversary('a', 'A', 10, 4)]));
    repository.fail(StateError('disk'));
    await pumpEventQueue();
    cubit.refresh();
    expect(cubit.state, const AnniversaryListFailure());
  });

  test('a record with no holding in range is left out, not "empty"', () async {
    final lastYear =
        calendar.toSolar(const LunarDate(2010, 12, 30)) ?? DateTime(0);
    final outOfRange = AnniversaryListCubit(
      repository,
      resolver,
      today: () => lastYear.add(const Duration(days: 1)),
    );
    outOfRange.start();
    repository.emit([anniversary('a', 'A', 10, 4)]);
    await pumpEventQueue();
    expect(outOfRange.state, const AnniversaryListLoaded([]));
    await outOfRange.close();
  });

  test('UI-1 refresh moves the countdown when the day changes', () async {
    var now = today;
    final rolling = AnniversaryListCubit(
      repository,
      resolver,
      today: () => now,
    );
    rolling.start();
    repository.emit([anniversary('a', 'A', 6, 4)]);
    await pumpEventQueue();
    expect((rolling.state as AnniversaryListLoaded).items.single.daysLeft, 1);
    now = now.add(const Duration(days: 1));
    rolling.refresh();
    final item = (rolling.state as AnniversaryListLoaded).items.single;
    expect(item.daysLeft, 0);
    expect(item.isToday, isTrue);
    await rolling.close();
  });
}

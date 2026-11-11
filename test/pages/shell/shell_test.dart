// Plan 0005, U4: drawer header (today's lunar date and count) and the menu
// button that opens the shell drawer.
import 'package:ever_moon/common/app_themes.dart';
import 'package:ever_moon/generated/l10n.dart';
import 'package:ever_moon/pages/shell/app_drawer.dart';
import 'package:ever_moon/pages/shell/shell_cubit.dart';
import 'package:ever_moon/pages/shell/shell_scope.dart';
import 'package:ever_moon/pages/shell/shell_state.dart';
import 'package:ever_moon/services/lunar/anniversary_resolver.dart';
import 'package:ever_moon/services/lunar/lunar_calendar_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../services/lunar/fake_lunar_calendar_service.dart';
import '../anniversary_list/fake_anniversary_repository.dart';

void main() {
  final calendar = FakeLunarCalendarService();
  final today = calendar.toSolar(const LunarDate(2002, 4, 5)) ?? DateTime(0);
  late FakeAnniversaryRepository repository;
  late ShellCubit cubit;

  setUp(() {
    repository = FakeAnniversaryRepository();
    cubit = ShellCubit(
      repository,
      calendar,
      AnniversaryResolver(calendar),
      today: () => today,
    )..start();
  });
  tearDown(() => cubit.close());

  test(
    'the header knows today and how many anniversaries fall today',
    () async {
      expect(
        cubit.state,
        ShellReady(
          solarToday: today,
          lunarToday: const LunarDate(2002, 4, 5),
          todayCount: 0,
        ),
      );
      repository.emit([
        anniversary('a', 'Ông nội', 5, 4),
        anniversary('b', 'Bà nội', 6, 4),
      ]);
      await pumpEventQueue();
      expect((cubit.state as ShellReady).todayCount, 1);
    },
  );

  test('a read error drops the count to 0 instead of a stale one', () async {
    repository.emit([anniversary('a', 'Ông nội', 5, 4)]);
    await pumpEventQueue();
    repository.fail(StateError('disk'));
    await pumpEventQueue();
    expect((cubit.state as ShellReady).todayCount, 0);
  });

  Widget app(Widget home) => MaterialApp(
    theme: const M3Theme().light,
    locale: const Locale('vi'),
    supportedLocales: const [Locale('en'), Locale('vi')],
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: BlocProvider.value(value: cubit, child: home),
  );

  testWidgets('the drawer shows today and picks a destination', (tester) async {
    int? picked;
    await tester.pumpWidget(
      app(
        Scaffold(
          body: AppDrawer(selectedIndex: 0, onSelected: (i) => picked = i),
        ),
      ),
    );
    expect(find.text('Evermoon'), findsOneWidget);
    expect(find.text('HÔM NAY'), findsOneWidget);
    expect(find.text('5 tháng 4 âm lịch'), findsOneWidget);
    expect(find.text('Ngày giỗ'), findsOneWidget);
    await tester.tap(find.text('Lịch'));
    expect(picked, 1);
    await tester.tap(find.text('Cài đặt'));
    expect(picked, 2);
  });

  testWidgets('the menu button opens the shell drawer', (tester) async {
    final key = GlobalKey<ScaffoldState>();
    await tester.pumpWidget(
      app(
        Scaffold(
          key: key,
          drawer: AppDrawer(selectedIndex: 0, onSelected: (_) {}),
          body: ShellScope(
            openDrawer: () => key.currentState?.openDrawer(),
            child: Builder(
              builder: (context) =>
                  Scaffold(appBar: AppBar(leading: MenuButton.maybe(context))),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.text('HÔM NAY'), findsOneWidget);
  });

  testWidgets('outside the shell there is no menu button', (tester) async {
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) =>
              Scaffold(appBar: AppBar(leading: MenuButton.maybe(context))),
        ),
      ),
    );
    expect(find.byIcon(Icons.menu), findsNothing);
  });
}

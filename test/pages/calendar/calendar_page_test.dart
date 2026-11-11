// Plan 0005, U5: UI-11, UI-13 and UI-14 on the rendered calendar.
import 'package:ever_moon/common/app_themes.dart';
import 'package:ever_moon/generated/l10n.dart';
import 'package:ever_moon/pages/calendar/calendar_page.dart';
import 'package:ever_moon/pages/calendar/widgets/event_items.dart';
import 'package:ever_moon/pages/calendar/widgets/year_view.dart';
import 'package:ever_moon/services/lunar/lunar_calendar_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../services/lunar/fake_lunar_calendar_service.dart';
import '../anniversary_form/memory_anniversary_repository.dart';

void main() {
  final calendar = FakeLunarCalendarService();
  // Lunar 4/9 of 2002: an anniversary is stored for that day.
  final today = calendar.toSolar(const LunarDate(2002, 4, 9)) ?? DateTime(0);
  late MemoryAnniversaryRepository repository;
  late List<String> edited;
  late int added;

  setUp(() {
    repository = MemoryAnniversaryRepository([
      storedAnniversary(day: 9, month: 4),
    ]);
    edited = [];
    added = 0;
  });

  Future<void> pumpCalendar(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: const M3Theme().light,
        locale: const Locale('vi'),
        supportedLocales: const [Locale('en'), Locale('vi')],
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: CalendarPage(
          onAdd: () => added++,
          onEdit: edited.add,
          repository: repository,
          calendar: calendar,
          today: () => today,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('UI-11 the add button opens the empty form', (tester) async {
    await pumpCalendar(tester);
    await tester.tap(find.byType(FloatingActionButton));
    expect(added, 1);
  });

  testWidgets('UI-13 swiping left opens edit', (tester) async {
    await pumpCalendar(tester);
    expect(find.text('Bà nội'), findsOneWidget);
    await tester.drag(find.text('Bà nội'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(edited, ['a']);
    expect(repository.deleted, isEmpty);
  });

  testWidgets('UI-13 swiping right asks, then deletes', (tester) async {
    await pumpCalendar(tester);
    await tester.drag(find.text('Bà nội'), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Xoá ngày giỗ của Bà nội?'), findsOneWidget);
    await tester.tap(
      find.descendant(of: find.byType(AlertDialog), matching: find.text('Xoá')),
    );
    await tester.pumpAndSettle();
    expect(repository.deleted, ['a']);
    expect(edited, isEmpty);
  });

  testWidgets('UI-13 TalkBack offers Sửa and Xoá on an anniversary', (
    tester,
  ) async {
    await pumpCalendar(tester);
    final semantics = tester.widget<Semantics>(
      find.descendant(
        of: find.byType(AnniversaryItem),
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.customSemanticsActions != null,
        ),
      ),
    );
    final actions = semantics.properties.customSemanticsActions ?? {};
    expect(actions.keys.map((a) => a.label).toSet(), {'Sửa', 'Xoá'});
    actions.entries.firstWhere((e) => e.key.label == 'Sửa').value();
    expect(edited, ['a']);
  });

  testWidgets('UI-13 holidays do not move', (tester) async {
    await pumpCalendar(tester);
    final firstDay = calendar.toSolar(const LunarDate(2002, 4, 1));
    expect(firstDay, isNotNull);
    await tester.tap(find.bySemanticsLabel(RegExp('Mùng 1 tháng 4')).first);
    await tester.pumpAndSettle();
    expect(find.byType(HolidayItem), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(HolidayItem),
        matching: find.byType(Dismissible),
      ),
      findsNothing,
    );
  });

  testWidgets('UI-14 every year tile has the same height', (tester) async {
    await pumpCalendar(tester);
    await tester.tap(find.text('Năm'));
    await tester.pumpAndSettle();
    final tiles = find.byType(MonthTile);
    expect(tiles, findsNWidgets(12));
    final heights = {
      for (var i = 0; i < 12; i++) tester.getSize(tiles.at(i)).height,
    };
    expect(heights, hasLength(1));
    await tester.tap(tiles.at(5));
    await tester.pumpAndSettle();
    expect(find.byType(MonthTile), findsNothing);
  });
}

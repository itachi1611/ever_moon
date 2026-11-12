// Plan 0005, U2: UI-1, UI-2, UI-7 and UI-8 on the rendered page.
import 'package:ever_moon/common/app_themes.dart';
import 'package:ever_moon/generated/l10n.dart';
import 'package:ever_moon/pages/anniversary_list/anniversary_list_page.dart';
import 'package:ever_moon/pages/widgets/add_anniversary_launcher.dart';
import 'package:ever_moon/services/lunar/anniversary_resolver.dart';
import 'package:ever_moon/services/lunar/lunar_calendar_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../services/lunar/fake_lunar_calendar_service.dart';
import 'fake_anniversary_repository.dart';

void main() {
  final calendar = FakeLunarCalendarService();
  final today = calendar.toSolar(const LunarDate(2002, 4, 5)) ?? DateTime(0);
  late FakeAnniversaryRepository repository;

  setUp(() => repository = FakeAnniversaryRepository());

  Future<void> pumpPage(
    WidgetTester tester, {
    Locale locale = const Locale('vi'),
    AddFormBuilder? addForm,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: const M3Theme().light,
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('vi')],
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: AnniversaryListPage(
          repository: repository,
          resolver: AnniversaryResolver(calendar),
          today: () => today,
          addForm: addForm,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('UI-2 empty store shows the empty state without add action', (
    tester,
  ) async {
    await pumpPage(tester);
    repository.emit(const []);
    await tester.pump();
    expect(find.text('Chưa có ngày giỗ nào'), findsOneWidget);
    expect(find.text('Thêm ngày giỗ'), findsNothing);
    expect(find.byType(AddAnniversaryFab), findsNothing);
  });

  testWidgets('UI-2 the empty state button and the add button open the form', (
    tester,
  ) async {
    await pumpPage(
      tester,
      addForm: (close) =>
          TextButton(onPressed: close, child: const Text('the form')),
    );
    repository.emit(const []);
    await tester.pump();
    await tester.tap(find.text('Thêm ngày giỗ'));
    await tester.pumpAndSettle();
    expect(find.text('the form'), findsOneWidget);
    await tester.tap(find.text('the form'));
    await tester.pumpAndSettle();
    expect(find.text('the form'), findsNothing);
    await tester.tap(find.byType(AddAnniversaryFab));
    await tester.pumpAndSettle();
    expect(find.text('the form'), findsOneWidget);
  });

  testWidgets('UI-1 today first with its chip, then the countdown', (
    tester,
  ) async {
    await pumpPage(tester);
    repository.emit([
      anniversary('a', 'Bà nội', 9, 4),
      anniversary('b', 'Ông nội', 5, 4),
    ]);
    await tester.pump();
    expect(find.text('Ngày giỗ sắp tới'), findsOneWidget);
    expect(find.text('2 người · 1 ngày giỗ hôm nay'), findsOneWidget);
    expect(find.text('5 tháng 4 âm lịch'), findsOneWidget);
    expect(find.text('Hôm nay'), findsNWidgets(2)); // section + chip
    expect(find.text('Sắp tới'), findsOneWidget);
    expect(find.text('4'), findsOneWidget); // 9/4 is four days away
    expect(find.text('ngày nữa'), findsOneWidget);
    final today = tester.getTopLeft(find.text('Ông nội'));
    final later = tester.getTopLeft(find.text('Bà nội'));
    expect(today.dy, lessThan(later.dy));
  });

  testWidgets('UI-8 a card reads as one sentence', (tester) async {
    await pumpPage(tester);
    repository.emit([anniversary('a', 'Bà nội', 9, 4)]);
    await tester.pump();
    final solar = calendar.toSolar(const LunarDate(2002, 4, 9));
    expect(solar, isNotNull);
    expect(
      find.bySemanticsLabel(
        RegExp(r'^Bà nội, 9 tháng 4 âm lịch, .+, còn 4 ngày$'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('UI-7 English strings come from the ARB file', (tester) async {
    await pumpPage(tester, locale: const Locale('en'));
    repository.emit([anniversary('a', 'Bà nội', 6, 4)]);
    await tester.pump();
    expect(find.text('Upcoming anniversaries'), findsOneWidget);
    expect(find.text('1 person'), findsOneWidget);
    expect(find.text('6/4 lunar'), findsOneWidget);
    expect(find.text('day left'), findsOneWidget);
  });

  testWidgets('a read error offers a retry that listens again', (tester) async {
    await pumpPage(tester);
    repository.fail(StateError('disk'));
    await tester.pump();
    expect(find.text('Không tải được danh sách.'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    expect(repository.watchCount, 2);
  });
}

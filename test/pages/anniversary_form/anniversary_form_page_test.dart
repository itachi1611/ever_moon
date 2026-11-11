// Plan 0005, U3: UI-3 to UI-7 and UI-10 on the rendered form.
import 'package:ever_moon/common/app_themes.dart';
import 'package:ever_moon/generated/l10n.dart';
import 'package:ever_moon/pages/anniversary_form/anniversary_form_page.dart';
import 'package:ever_moon/services/lunar/anniversary_resolver.dart';
import 'package:ever_moon/services/lunar/lunar_calendar_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../services/lunar/fake_lunar_calendar_service.dart';
import 'memory_anniversary_repository.dart';

void main() {
  final calendar = FakeLunarCalendarService(leapMonths: {2005: 9});
  final today = calendar.toSolar(const LunarDate(2002, 4, 5)) ?? DateTime(0);
  late MemoryAnniversaryRepository repository;
  late int closed;

  setUp(() {
    repository = MemoryAnniversaryRepository();
    closed = 0;
  });

  Future<void> pumpForm(
    WidgetTester tester, {
    String? id,
    Locale locale = const Locale('vi'),
  }) async {
    // Tall enough that the whole form is on screen without scrolling.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
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
        home: AnniversaryFormPage(
          anniversaryId: id,
          onClose: () => closed++,
          repository: repository,
          resolver: AnniversaryResolver(calendar),
          today: () => today,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pick(WidgetTester tester, String label, String value) async {
    await tester.tap(find.widgetWithText(DropdownMenu<int>, label));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MenuItemButton, value).hitTestable());
    await tester.pumpAndSettle();
  }

  testWidgets('UI-4 saving an empty form shows the ARB messages', (
    tester,
  ) async {
    await pumpForm(tester);
    expect(find.text('Thêm ngày giỗ'), findsOneWidget);
    await tester.tap(find.text('Lưu ngày giỗ'));
    await tester.pumpAndSettle();
    expect(find.text('Vui lòng nhập tên người mất.'), findsOneWidget);
    expect(find.text('Chọn ngày âm.'), findsOneWidget);
    expect(find.text('Chọn tháng âm.'), findsOneWidget);
    expect(closed, 0);
  });

  testWidgets('UI-3 a valid form saves and closes', (tester) async {
    await pumpForm(tester);
    await tester.enterText(find.byType(TextField).first, 'Ông nội');
    await pick(tester, 'Ngày', '3');
    await pick(tester, 'Tháng', '2');
    await tester.tap(find.text('Lưu ngày giỗ'));
    await tester.pumpAndSettle();
    expect(closed, 1);
    final saved = repository.records.values.single;
    expect(saved.name, 'Ông nội');
    expect(saved.date.lunarDay, 3);
    expect(saved.date.lunarMonth, 2);
  });

  testWidgets('UI-5 the leap question follows the death year', (tester) async {
    repository = MemoryAnniversaryRepository([
      storedAnniversary(day: 9, month: 9),
    ]);
    await pumpForm(tester, id: 'a');
    final year = find.widgetWithText(TextField, 'Ví dụ: 1998');
    expect(find.text('Mất vào tháng 9 nhuận'), findsNothing);
    await tester.enterText(year, '2005');
    await tester.pumpAndSettle();
    expect(find.text('Mất vào tháng 9 nhuận'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(1), '2004');
    await tester.pumpAndSettle();
    expect(find.text('Mất vào tháng 9 nhuận'), findsNothing);
  });

  testWidgets('UI-10 turning the reminder off hides lead time and time', (
    tester,
  ) async {
    repository = MemoryAnniversaryRepository([storedAnniversary()]);
    await pumpForm(tester, id: 'a');
    expect(find.text('Nhắc trước'), findsOneWidget);
    expect(find.text('Giờ nhắc'), findsOneWidget);
    expect(find.textContaining('1 ngày trước'), findsOneWidget);
    await tester.tap(find.widgetWithText(SwitchListTile, 'Nhắc tôi'));
    await tester.pumpAndSettle();
    expect(find.text('Nhắc trước'), findsNothing);
    expect(find.text('Giờ nhắc'), findsNothing);
  });

  testWidgets('UI-6 delete asks first; Giữ lại keeps the record', (
    tester,
  ) async {
    repository = MemoryAnniversaryRepository([storedAnniversary()]);
    await pumpForm(tester, id: 'a');
    expect(find.text('Sửa ngày giỗ'), findsOneWidget);
    await tester.tap(find.text('Xoá ngày giỗ'));
    await tester.pumpAndSettle();
    expect(find.text('Xoá ngày giỗ của Bà nội?'), findsOneWidget);
    await tester.tap(find.text('Giữ lại'));
    await tester.pumpAndSettle();
    expect(repository.deleted, isEmpty);
    await tester.tap(find.text('Xoá ngày giỗ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xoá'));
    await tester.pumpAndSettle();
    expect(repository.deleted, ['a']);
    expect(closed, 1);
  });

  testWidgets('a failed save shows a snack bar and stays open', (tester) async {
    repository = MemoryAnniversaryRepository([storedAnniversary()])
      ..failWrites = true;
    await pumpForm(tester, id: 'a');
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    expect(find.text('Không lưu được. Vui lòng thử lại.'), findsOneWidget);
    expect(closed, 0);
  });

  testWidgets('UI-7 English strings come from the ARB file', (tester) async {
    await pumpForm(tester, locale: const Locale('en'));
    expect(find.text('Add anniversary'), findsOneWidget);
    await tester.tap(find.text('Save anniversary'));
    await tester.pumpAndSettle();
    expect(find.text('Enter the name of the deceased.'), findsOneWidget);
    expect(find.text('Choose the lunar day.'), findsOneWidget);
  });
}

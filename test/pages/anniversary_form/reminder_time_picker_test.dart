// Reminder time picker (found on a Pixel 8 with the font size set to 85%).
// Switching the picker to keyboard entry threw "BoxConstraints has
// non-normalized height constraints (216 <= h <= 214.2)": Flutter's input
// mode has a 216 px minimum and a 252 px maximum that the text scale (0.85)
// shrinks below the minimum.
import 'package:ever_moon/pages/anniversary_form/widgets/reminder_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpPicker(WidgetTester tester, double textScale) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => showReminderTimePicker(
                context,
                const TimeOfDay(hour: 7, minute: 0),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  for (final scale in [0.85, 1.0, 1.3]) {
    testWidgets('keyboard entry opens without a layout error at x$scale', (
      tester,
    ) async {
      await _pumpPicker(tester, scale);

      await tester.tap(find.byIcon(Icons.keyboard_outlined));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(TextField), findsNWidgets(2));
    });
  }
}

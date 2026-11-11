// Plan 0005, D7: the theme uses Fox's scheme and the two bundled fonts.
import 'package:ever_moon/common/app_config.dart';
import 'package:ever_moon/common/app_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const theme = M3Theme();

  for (final (name, data) in [('light', theme.light), ('dark', theme.dark)]) {
    group(name, () {
      test('display, headline and title use the display font', () {
        final t = data.textTheme;
        for (final style in [t.displayLarge, t.headlineSmall, t.titleLarge]) {
          expect(style?.fontFamily, AppConfig.kDisplayFont);
        }
      });

      test('body and label use the body font', () {
        final t = data.textTheme;
        for (final style in [t.bodyLarge, t.bodyMedium, t.labelLarge]) {
          expect(style?.fontFamily, AppConfig.kBodyFont);
        }
      });

      test('keeps the M3 type scale sizes', () {
        // Sizes come from the typography geometry that Theme.of merges in.
        final t = ThemeData.localize(
          data,
          data.typography.englishLike,
        ).textTheme;
        final m3 = Typography.material2021().englishLike;
        expect(t.headlineSmall?.fontSize, m3.headlineSmall?.fontSize);
        expect(t.bodyLarge?.fontSize, m3.bodyLarge?.fontSize);
      });
    });
  }

  test('every theme registers the calendar holiday colors', () {
    final themes = [
      theme.light,
      theme.lightMediumContrast,
      theme.lightHighContrast,
      theme.dark,
      theme.darkMediumContrast,
      theme.darkHighContrast,
    ];
    for (final data in themes) {
      final expected = data.brightness == Brightness.dark
          ? CalendarColorExtension.dark
          : CalendarColorExtension.light;
      expect(data.extension<CalendarColorExtension>(), expected);
    }
  });

  test('holiday mark is not the error color', () {
    expect(
      CalendarColorExtension.light.holidayMark,
      isNot(M3Theme.lightScheme.error),
    );
  });

  test('light primary comes from the Theme Builder export', () {
    expect(M3Theme.lightScheme.primary, const Color(0xff5354ad));
  });
}

// Guards the gen-l10n migration and the template's inverted empty check.
// Expected messages come from the generated S class, not from literals.
import 'package:ever_moon/common/app_enums.dart';
import 'package:ever_moon/generated/l10n.dart';
import 'package:ever_moon/utils/app_validator.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final languageCode in ['en', 'vi']) {
    group('onValidate ($languageCode)', () {
      final strings = lookupS(Locale(languageCode));

      test('empty or null input is a required-field error', () {
        expect(onValidate(strings, ValidatorType.email, null),
            strings.er_required_field);
        expect(onValidate(strings, ValidatorType.email, ''),
            strings.er_required_field);
      });

      test('well-formed input passes', () {
        expect(onValidate(strings, ValidatorType.email, 'a@b.vn'), isNull);
        expect(onValidate(strings, ValidatorType.phone, '0912345678'), isNull);
      });

      test('malformed input gets the type error', () {
        expect(onValidate(strings, ValidatorType.email, 'not-an-email'),
            strings.er_email_field);
        expect(onValidate(strings, ValidatorType.phone, '123'),
            strings.er_phone_field);
      });
    });
  }

  test('Vietnamese strings are not the English fallback', () {
    final en = lookupS(const Locale('en'));
    final vi = lookupS(const Locale('vi'));
    expect(vi.er_required_field, isNot(en.er_required_field));
  });
}

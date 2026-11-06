import '../common/app_enums.dart' show ValidatorType;
import '../generated/l10n.dart';

/// Validates [value] against the regex pattern defined by [type].
///
/// Returns `null` if [value] passes validation, or an error from [strings]
/// otherwise. An empty or null [value] always returns the required-field
/// error regardless of [type]. [strings] is passed in because gen-l10n has
/// no context-free `S.current`.
///
/// ```dart
/// TextFormField(
///   validator: (v) => onValidate(S.of(context), ValidatorType.email, v),
/// )
/// ```
String? onValidate(S strings, ValidatorType type, String? value) {
  // The template checked `isValidate`, which is true for non-empty input,
  // so every filled field failed. Empty input is what must fail.
  if (value == null || value.isEmpty) {
    return strings.er_required_field;
  }

  if (!RegExp(type.rawReg).hasMatch(value)) {
    return switch (type) {
      ValidatorType.email => strings.er_email_field,
      ValidatorType.password => strings.er_password_field,
      ValidatorType.name => strings.er_name_field,
      ValidatorType.phone => strings.er_phone_field,
    };
  }

  return null;
}

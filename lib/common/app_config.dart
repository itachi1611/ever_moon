/// Static configuration constants shared across the app.
///
/// Values here are compile-time constants that do not vary by flavor.
/// For environment-specific values, see [AppEnv].
class AppConfig {
  /// Font for M3 body and label styles (dates, buttons, form text).
  ///
  /// Must match a `family` declared under `flutter > fonts` in pubspec.yaml.
  static const String kBodyFont = 'BeVietnamPro';

  /// Font for M3 display, headline and title styles (screen titles, names).
  ///
  /// Must match a `family` declared under `flutter > fonts` in pubspec.yaml.
  static const String kDisplayFont = 'Lora';
}

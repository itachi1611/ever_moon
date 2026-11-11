import 'package:flutter/material.dart';

import 'app_config.dart' show AppConfig;

/// Reusable [TextStyle] definitions built on the bundled body font
/// [AppConfig.kBodyFont]. Prefer `Theme.of(context).textTheme` in widgets.
class AppTextStyle {
  /// Base text style using the app's local font family.
  static const body = TextStyle(fontFamily: AppConfig.kBodyFont);

  /// Black, size 14, medium weight (500) style.
  static final blackS14W500 = body.copyWith(
    fontWeight: FontWeight.w500,
    fontSize: 14,
  );
}

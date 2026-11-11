import 'package:flutter/material.dart';

/// Material 3 elevation levels, in dp, for the `elevation` of Material
/// widgets (plan 0005, D7).
///
/// M3 shows depth mainly with tonal surface colors (`surfaceContainer*`);
/// a shadow is drawn only where the component spec asks for one (FAB,
/// elevated card, menus, snackbar). Prefer the component defaults of the
/// M3 theme and use these constants only for custom surfaces.
class AppElevation {
  /// Level 0: flat surfaces, filled and outlined cards, app bar at rest.
  static const double level0 = 0;

  /// Level 1: elevated card, modal bottom sheet.
  static const double level1 = 1;

  /// Level 2: menus, app bar while content scrolls under it.
  static const double level2 = 3;

  /// Level 3: FAB at rest, dialogs, snackbar.
  static const double level3 = 6;

  /// Level 4: FAB hovered or focused.
  static const double level4 = 8;

  /// Level 5: highest emphasis; not used in v1.
  static const double level5 = 12;
}

/// Reusable [BoxShadow] lists for custom widgets that are not Material
/// components. Values follow the Material 3 elevation shadows.
class AppShadows {
  /// Level 3 shadow (6 dp), matching the FAB at rest.
  static const List<BoxShadow> level3 = [
    BoxShadow(color: Color(0x4D000000), offset: Offset(0, 1), blurRadius: 3),
    BoxShadow(
      color: Color(0x26000000),
      offset: Offset(0, 4),
      blurRadius: 8,
      spreadRadius: 3,
    ),
  ];
}

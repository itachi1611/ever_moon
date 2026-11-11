/// Material 3 layout tokens: spacing, shape and component sizes, in logical
/// pixels (plan 0005, D7). Widgets read these instead of hardcoding numbers.
class AppDimensions {
  // SPACING (4 dp grid)

  /// Base spacing unit of the 4 dp grid.
  static const double spacing = 4;

  /// 4 dp.
  static const double space4 = 4;

  /// 8 dp.
  static const double space8 = 8;

  /// 12 dp.
  static const double space12 = 12;

  /// 16 dp: screen margin on compact windows (phones).
  static const double space16 = 16;

  /// 24 dp.
  static const double space24 = 24;

  /// 32 dp.
  static const double space32 = 32;

  /// Default screen padding on phones (M3 compact window margin).
  static const double padding = space16;

  // SHAPE (M3 corner scale)

  /// Extra small corner: outlined text fields.
  static const double cornerExtraSmall = 4;

  /// Small corner: chips.
  static const double cornerSmall = 8;

  /// Medium corner: cards.
  static const double cornerMedium = 12;

  /// Large corner: FAB, navigation drawer.
  static const double cornerLarge = 16;

  /// Extra large corner: dialogs, bottom sheets.
  static const double cornerExtraLarge = 28;

  // COMPONENT SIZES

  /// Minimum touch target for anything tappable.
  static const double minTouchTarget = 48;

  /// Small top app bar height.
  static const double topAppBarHeight = 64;

  /// Modal navigation drawer width (M3 allows up to 360).
  static const double navigationDrawerWidth = 316;

  /// Navigation drawer destination height.
  static const double drawerItemHeight = 56;

  /// FAB container size.
  static const double fabSize = 56;

  /// Text field container height.
  static const double textFieldHeight = 56;

  /// Common button container height (the touch target is still 48).
  static const double buttonHeight = 40;

  /// Lunar date badge on an anniversary card.
  static const double dateBadgeWidth = 56;

  /// Lunar date badge height on an anniversary card.
  static const double dateBadgeHeight = 64;

  /// Disc behind the illustration of an empty state.
  static const double emptyStateDisc = 96;

  /// Icon inside the empty-state disc.
  static const double emptyStateIcon = 48;
}

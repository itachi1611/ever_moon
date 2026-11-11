import 'package:flutter/material.dart';

/// Lets pages inside the shell open its navigation drawer.
///
/// Each page has its own [Scaffold], so `Scaffold.of` would find the page's
/// scaffold, not the shell's one that owns the drawer.
class ShellScope extends InheritedWidget {
  /// Creates the scope.
  const ShellScope({super.key, required this.openDrawer, required super.child});

  /// Opens the shell's drawer.
  final VoidCallback openDrawer;

  /// The nearest scope, or `null` outside the shell (tests, full-screen
  /// routes).
  static ShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>();

  @override
  bool updateShouldNotify(ShellScope oldWidget) =>
      openDrawer != oldWidget.openDrawer;
}

/// The top-bar button that opens the drawer (design: Main).
class MenuButton extends StatelessWidget {
  /// Creates the button for [scope].
  const MenuButton({super.key, required this.scope});

  /// The shell to open.
  final ShellScope scope;

  /// The button when inside the shell, otherwise `null` so an app bar shows
  /// no empty leading slot.
  static Widget? maybe(BuildContext context) {
    final scope = ShellScope.maybeOf(context);
    return scope == null ? null : MenuButton(scope: scope);
  }

  @override
  Widget build(BuildContext context) => IconButton(
    icon: const Icon(Icons.menu),
    tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
    onPressed: scope.openDrawer,
  );
}

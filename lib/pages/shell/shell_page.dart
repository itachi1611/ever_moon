import 'package:ever_moon/repositories/anniversary_repository.dart';
import 'package:ever_moon/services/lunar/anniversary_resolver.dart';
import 'package:ever_moon/services/lunar/lunar_calendar_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../widgets/animated_bottom_navigation_widget.dart';
import '../widgets/transition_shell_widget.dart' show ShellTransitionType;
import 'app_drawer.dart';
import 'shell_cubit.dart';
import 'shell_scope.dart';

/// Root scaffold of the shell: the branch on screen plus the modal
/// navigation drawer (plan 0005, D13).
///
/// Pages open the drawer through [ShellScope] (their menu button). Picking
/// the current destination again returns that branch to its first page.
///
/// Built by `router_config.dart`'s `navigatorContainerBuilder`; not
/// instantiated directly in app code.
class ShellPage extends StatefulWidget {
  /// Creates the shell for [shell] with its prebuilt branch [children].
  const ShellPage({super.key, required this.shell, required this.children});

  /// The [StatefulNavigationShell] provided by GoRouter.
  final StatefulNavigationShell shell;

  /// Prebuilt branch widgets from GoRouter's navigator container builder.
  final List<Widget> children;

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final ShellCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = ShellCubit(
      anniversaryRepository,
      lunarCalendarService,
      AnniversaryResolver(lunarCalendarService),
    )..start();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  /// Dates in the header are recomputed each time the drawer opens.
  void _onDrawerChanged(bool open) {
    if (open) _cubit.refresh();
  }

  void _select(int index) {
    _scaffoldKey.currentState?.closeDrawer();
    widget.shell.goBranch(
      index,
      initialLocation: index == widget.shell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _cubit,
    child: _SystemBars(
      child: Scaffold(
        key: _scaffoldKey,
        onDrawerChanged: _onDrawerChanged,
        drawer: AppDrawer(
          selectedIndex: widget.shell.currentIndex,
          onSelected: _select,
        ),
        body: ShellScope(
          openDrawer: _openDrawer,
          child: _Branches(
            currentIndex: widget.shell.currentIndex,
            children: widget.children,
          ),
        ),
      ),
    ),
  );
}

class _Branches extends StatelessWidget {
  const _Branches({required this.currentIndex, required this.children});

  final int currentIndex;
  final List<Widget> children;

  // Each page's app bar handles the top inset.
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: AnimatedBranchContainer(
      currentIndex: currentIndex,
      // Slide and fade toward the side the tab sits on in the drawer. Fade
      // through alone was too faint to notice on a phone.
      transitionType: ShellTransitionType.slideFade,
      duration: const Duration(milliseconds: 400),
      children: children,
    ),
  );
}

/// Status bar icons that stay legible on the current brightness.
class _SystemBars extends StatelessWidget {
  const _SystemBars({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: theme.scaffoldBackgroundColor,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: child,
    );
  }
}

import 'package:ever_moon/common/app_config.dart';
import 'package:ever_moon/common/app_dimensions.dart';
import 'package:ever_moon/generated/l10n.dart';
import 'package:ever_moon/pages/widgets/localized_dates.dart';
import 'package:ever_moon/pages/widgets/lunar_texts.dart';
import 'package:ever_moon/services/lunar/lunar_calendar_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'shell_cubit.dart';
import 'shell_state.dart';

/// Modal navigation drawer (plan 0005, D13; design: DrawerOpen): the mark,
/// today's lunar date, then one destination per shell branch.
///
/// Destination index [selectedIndex] equals the shell branch index.
class AppDrawer extends StatelessWidget {
  /// Creates the drawer.
  const AppDrawer({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  /// The branch on screen.
  final int selectedIndex;

  /// Called with the chosen branch index.
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => BlocBuilder<ShellCubit, ShellState>(
    builder: (context, state) => NavigationDrawer(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      children: [
        _DrawerHeader(state: state),
        ..._destinations(S.of(context), state),
      ],
    ),
  );

  // NavigationDrawer only counts direct NavigationDrawerDestination
  // children, so these cannot be wrapped in widget classes.
  List<Widget> _destinations(S s, ShellState state) => [
    NavigationDrawerDestination(
      icon: _TodayBadge(
        state: state,
        child: const Icon(Icons.dark_mode_outlined),
      ),
      selectedIcon: _TodayBadge(
        state: state,
        child: const Icon(Icons.dark_mode),
      ),
      label: Text(s.lb_nav_anniversaries),
    ),
    NavigationDrawerDestination(
      icon: const Icon(Icons.calendar_month_outlined),
      selectedIcon: const Icon(Icons.calendar_month),
      label: Text(s.lb_nav_calendar),
    ),
    NavigationDrawerDestination(
      icon: const Icon(Icons.settings_outlined),
      selectedIcon: const Icon(Icons.settings),
      label: Text(s.lb_settings),
    ),
  ];
}

/// Marks the anniversaries destination with how many fall today.
class _TodayBadge extends StatelessWidget {
  const _TodayBadge({required this.state, required this.child});

  final ShellState state;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final count = switch (state) {
      ShellReady(:final todayCount) => todayCount,
      ShellStarting() => 0,
    };
    return Badge(
      isLabelVisible: count > 0,
      // The Semantics label below says the count in words; read it once.
      label: ExcludeSemantics(child: Text('$count')),
      child: Semantics(
        label: count > 0 ? S.of(context).lb_today_count(count) : null,
        child: child,
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.state});

  final ShellState state;

  @override
  Widget build(BuildContext context) {
    final current = state;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.space16,
        AppDimensions.space24,
        AppDimensions.space16,
        AppDimensions.space12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppDimensions.space16,
        children: [
          const _Brand(),
          if (current is ShellReady) _TodayCard(state: current),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) => Row(
    spacing: AppDimensions.space12,
    children: [
      Image.asset(
        AppConfig.kMarkImage,
        width: AppDimensions.drawerMark,
        height: AppDimensions.drawerMark,
        excludeFromSemantics: true,
      ),
      Text(
        S.of(context).lb_app_name,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    ],
  );
}

/// Today's lunar and solar dates (design: drawer header "Hôm nay").
class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.state});

  final ShellReady state;

  @override
  Widget build(BuildContext context) {
    final lunar = state.lunarToday;
    if (lunar == null) return const SizedBox.shrink();
    final s = S.of(context);
    final lunarText = lunarDateText(s, lunar);
    final solarText = formatLocalizedDate(
      context,
      state.solarToday,
      s.lb_solar_date_pattern,
    );
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: s.lb_today_card_semantics(lunarText, solarText),
      child: _TodayCardFrame(
        lunar: lunar,
        lunarText: lunarText,
        solarText: solarText,
      ),
    );
  }
}

class _TodayCardFrame extends StatelessWidget {
  const _TodayCardFrame({
    required this.lunar,
    required this.lunarText,
    required this.solarText,
  });

  final LunarDate lunar;
  final String lunarText;
  final String solarText;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(AppDimensions.cornerLarge),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: AppDimensions.space12,
      ),
      child: Row(
        spacing: AppDimensions.space16,
        children: [
          _LunarBadge(lunar: lunar),
          Expanded(
            child: _TodayLines(lunarText: lunarText, solarText: solarText),
          ),
        ],
      ),
    ),
  );
}

class _LunarBadge extends StatelessWidget {
  const _LunarBadge({required this.lunar});

  final LunarDate lunar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final month = lunarMonthText(
      S.of(context),
      lunar.month,
      isLeapMonth: lunar.isLeapMonth,
    );
    return _BadgeBox(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${lunar.day}',
            style: text.titleLarge?.copyWith(color: scheme.onPrimary),
          ),
          Text(
            month,
            style: text.labelSmall?.copyWith(color: scheme.onPrimary),
          ),
        ],
      ),
    );
  }
}

class _BadgeBox extends StatelessWidget {
  const _BadgeBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: AppDimensions.dateBadgeWidth,
    height: AppDimensions.dateBadgeHeight,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary,
      borderRadius: BorderRadius.circular(AppDimensions.cornerMedium),
    ),
    child: child,
  );
}

class _TodayLines extends StatelessWidget {
  const _TodayLines({required this.lunarText, required this.solarText});

  final String lunarText;
  final String solarText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).lb_today_caps,
          style: theme.textTheme.labelSmall?.copyWith(color: muted),
        ),
        Text(lunarText, style: theme.textTheme.titleMedium),
        Text(
          solarText,
          style: theme.textTheme.bodyMedium?.copyWith(color: muted),
        ),
      ],
    );
  }
}

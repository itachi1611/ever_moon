import 'package:ever_moon/common/app_dimensions.dart';
import 'package:ever_moon/common/app_themes.dart';
import 'package:ever_moon/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../calendar_cubit.dart';
import '../calendar_models.dart';
import '../calendar_state.dart';
import 'calendar_texts.dart';

/// Year / Month / Week switch and the period with its arrows (design:
/// CalendarMonth header).
class CalendarHeader extends StatelessWidget {
  /// Creates the header for [state].
  const CalendarHeader({super.key, required this.state});

  /// What is shown.
  final CalendarReady state;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppDimensions.space16,
      AppDimensions.space8,
      AppDimensions.space16,
      AppDimensions.space8,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppDimensions.space12,
      children: [
        _ViewSwitch(view: state.view),
        _PeriodNavigator(state: state),
      ],
    ),
  );
}

class _ViewSwitch extends StatelessWidget {
  const _ViewSwitch({required this.view});

  final CalendarView view;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return SegmentedButton<CalendarView>(
      showSelectedIcon: false,
      selected: {view},
      onSelectionChanged: (views) =>
          context.read<CalendarCubit>().showView(views.first),
      segments: [
        ButtonSegment(value: CalendarView.year, label: Text(s.lb_view_year)),
        ButtonSegment(value: CalendarView.month, label: Text(s.lb_view_month)),
        ButtonSegment(value: CalendarView.week, label: Text(s.lb_view_week)),
      ],
    );
  }
}

class _PeriodNavigator extends StatelessWidget {
  const _PeriodNavigator({required this.state});

  final CalendarReady state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CalendarCubit>();
    final tips = _tooltips(S.of(context), state.view);
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: tips.previous,
          onPressed: cubit.previous,
        ),
        Expanded(child: _PeriodTitle(texts: periodTexts(context, state))),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: tips.next,
          onPressed: cubit.next,
        ),
      ],
    );
  }

  static ({String previous, String next}) _tooltips(S s, CalendarView view) =>
      switch (view) {
        CalendarView.year => (previous: s.lb_prev_year, next: s.lb_next_year),
        CalendarView.month => (
          previous: s.lb_prev_month,
          next: s.lb_next_month,
        ),
        CalendarView.week => (previous: s.lb_prev_week, next: s.lb_next_week),
      };
}

class _PeriodTitle extends StatelessWidget {
  const _PeriodTitle({required this.texts});

  final PeriodTexts texts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Semantics(
      liveRegion: true,
      child: Column(
        children: [
          Text(texts.title, style: theme.textTheme.titleMedium),
          if (texts.subtitle.isNotEmpty)
            Text(
              texts.subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

/// Purple dot for anniversaries, red for mùng 1, rằm and festivals (D16).
///
/// Sighted users only: every cell and item says the same in words.
class CalendarLegend extends StatelessWidget {
  /// Creates the legend.
  const CalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ExcludeSemantics(
      child: Wrap(
        spacing: AppDimensions.space16,
        runSpacing: AppDimensions.space4,
        children: [
          _LegendEntry(
            color: Theme.of(context).colorScheme.primary,
            text: s.lb_legend_anniversary,
          ),
          _LegendEntry(
            color: CalendarColorExtension.of(context).holidayMark,
            text: s.lb_legend_holiday,
          ),
        ],
      ),
    );
  }
}

class _LegendEntry extends StatelessWidget {
  const _LegendEntry({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppDimensions.space8,
      children: [
        MarkDot(color: color, size: AppDimensions.legendDot),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// A round colour mark.
class MarkDot extends StatelessWidget {
  /// Creates a dot of [size] in [color].
  const MarkDot({super.key, required this.color, required this.size});

  /// Fill colour.
  final Color color;

  /// Diameter.
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

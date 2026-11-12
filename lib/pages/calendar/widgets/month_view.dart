import 'package:ever_moon/common/app_dimensions.dart';
import 'package:ever_moon/common/app_themes.dart';
import 'package:ever_moon/generated/l10n.dart';
import 'package:ever_moon/pages/widgets/localized_dates.dart';
import 'package:ever_moon/pages/widgets/lunar_texts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../calendar_cubit.dart';
import '../calendar_models.dart';
import '../calendar_state.dart';
import 'calendar_header.dart';
import 'calendar_texts.dart';
import 'event_items.dart';

/// Month grid, legend, then the selected day's events (design:
/// CalendarMonth; UI-9, UI-14).
class MonthView extends StatelessWidget {
  /// Creates the view.
  const MonthView({
    super.key,
    required this.state,
    required this.period,
    required this.actions,
    required this.bottomPadding,
  });

  /// Today and the selected day.
  final CalendarReady state;

  /// The month.
  final MonthPeriod period;

  /// Edit and delete handlers.
  final CalendarActions actions;

  /// Room for the FAB.
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final rows = _rows();
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.space16,
        0,
        AppDimensions.space16,
        AppDimensions.space16 + bottomPadding,
      ),
      itemCount: rows.length,
      itemBuilder: (context, index) => rows[index](),
    );
  }

  List<Widget Function()> _rows() {
    final selected = period.days
        .where((day) => day.solar == state.selected)
        .firstOrNull;
    return [
      () => const WeekdayHeader(),
      () => MonthGrid(period: period, state: state),
      () => const _Spaced(child: CalendarLegend()),
      if (selected != null) () => _DayTitle(day: selected),
      if (selected != null)
        () => _SelectedDayEvents(day: selected, actions: actions),
    ];
  }
}

/// T2 … CN, Monday first.
class WeekdayHeader extends StatelessWidget {
  /// Creates the header.
  const WeekdayHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final names = S.of(context).lb_weekdays_short.split(',');
    return ExcludeSemantics(
      child: Row(
        children: [
          for (var i = 0; i < names.length; i++)
            Expanded(
              child: _WeekdayLabel(
                text: names[i],
                isSunday: i == names.length - 1,
              ),
            ),
        ],
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel({required this.text, required this.isSunday});

  final String text;
  final bool isSunday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      textAlign: TextAlign.center,
      style: theme.textTheme.labelMedium?.copyWith(
        color: isSunday
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Seven columns of [DayCell]s.
class MonthGrid extends StatelessWidget {
  /// Creates the grid.
  const MonthGrid({super.key, required this.period, required this.state});

  /// The month.
  final MonthPeriod period;

  /// Today and the selected day.
  final CalendarReady state;

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: EdgeInsets.zero,
    itemCount: period.cells.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: DateTime.daysPerWeek,
      mainAxisExtent: AppDimensions.dayCellHeight,
    ),
    itemBuilder: (context, index) {
      final day = period.cells[index];
      if (day == null) return const SizedBox.shrink();
      return DayCell(
        day: day,
        isToday: day.solar == state.today,
        isSelected: day.solar == state.selected,
      );
    },
  );
}

/// One day: solar and lunar numbers and the two marks (design system:
/// LunarDayCell).
class DayCell extends StatelessWidget {
  /// Creates the cell.
  const DayCell({
    super.key,
    required this.day,
    required this.isToday,
    required this.isSelected,
  });

  /// The day.
  final CalendarDay day;

  /// Whether it is today (filled).
  final bool isToday;

  /// Whether it is selected (outlined).
  final bool isSelected;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: isSelected,
    label: dayCellSemantics(context, day, isToday: isToday),
    excludeSemantics: true,
    child: _CellSurface(
      isToday: isToday,
      isSelected: isSelected,
      onTap: () => context.read<CalendarCubit>().select(day.solar),
      child: _CellNumbers(day: day, isToday: isToday),
    ),
  );
}

/// Filled for today, outlined when selected, with a ripple.
class _CellSurface extends StatelessWidget {
  const _CellSurface({
    required this.isToday,
    required this.isSelected,
    required this.onTap,
    required this.child,
  });

  static const _shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(AppDimensions.cornerMedium)),
  );

  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      type: isToday ? MaterialType.canvas : MaterialType.transparency,
      color: isToday ? primary : null,
      shape: _shape.copyWith(
        side: isSelected && !isToday
            ? BorderSide(color: primary, width: AppDimensions.borderThick)
            : BorderSide.none,
      ),
      child: InkWell(customBorder: _shape, onTap: onTap, child: child),
    );
  }
}

class _CellNumbers extends StatelessWidget {
  const _CellNumbers({required this.day, required this.isToday});

  final CalendarDay day;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isSunday = day.solar.weekday == DateTime.sunday;
    final solarColor = isToday
        ? scheme.onPrimary
        : (isSunday ? scheme.primary : scheme.onSurface);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${day.solar.day}',
          style: theme.textTheme.bodyLarge?.copyWith(color: solarColor),
        ),
        _LunarNumber(day: day, isToday: isToday),
        _CellMarks(day: day, isToday: isToday),
      ],
    );
  }
}

class _LunarNumber extends StatelessWidget {
  const _LunarNumber({required this.day, required this.isToday});

  final CalendarDay day;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final lunar = day.lunar;
    if (lunar == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    // Red for mùng 1, rằm and festivals (UI-14).
    final marked = day.hasHoliday;
    final color = isToday
        ? theme.colorScheme.onPrimary
        : marked
        ? CalendarColorExtension.of(context).holidayMark
        : theme.colorScheme.onSurfaceVariant;
    // Day 1 shows its month, as paper calendars do: "1/10".
    return Text(
      lunar.day == 1 ? '1/${lunar.month}' : '${lunar.day}',
      style: theme.textTheme.labelSmall?.copyWith(
        color: color,
        fontWeight: marked ? FontWeight.w700 : null,
      ),
    );
  }
}

class _CellMarks extends StatelessWidget {
  const _CellMarks({required this.day, required this.isToday});

  final CalendarDay day;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: AppDimensions.markDot,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: AppDimensions.space4,
        children: [
          if (day.hasAnniversary)
            MarkDot(
              color: isToday ? scheme.onPrimary : scheme.primary,
              size: AppDimensions.markDot,
            ),
          if (day.hasHoliday)
            MarkDot(
              color: CalendarColorExtension.of(context).holidayMark,
              size: AppDimensions.markDot,
            ),
        ],
      ),
    );
  }
}

class _DayTitle extends StatelessWidget {
  const _DayTitle({required this.day});

  final CalendarDay day;

  String _title(BuildContext context) {
    final s = S.of(context);
    final lunar = day.lunar;
    final solar = formatLocalizedDate(
      context,
      day.solar,
      s.lb_short_date_pattern,
    );
    return lunar == null
        ? solar
        : s.lb_day_title(solar, lunarDateText(s, lunar));
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(
      top: AppDimensions.space16,
      bottom: AppDimensions.space8,
    ),
    child: Semantics(
      header: true,
      child: Text(
        _title(context),
        style: Theme.of(context).textTheme.titleSmall,
      ),
    ),
  );
}

class _SelectedDayEvents extends StatelessWidget {
  const _SelectedDayEvents({required this.day, required this.actions});

  final CalendarDay day;
  final CalendarActions actions;

  @override
  Widget build(BuildContext context) {
    if (!day.hasHoliday && !day.hasAnniversary) {
      return Text(
        S.of(context).lb_day_empty,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppDimensions.space8,
      children: [
        DayEvents(day: day, actions: actions),
        if (day.hasAnniversary) const SwipeHint(),
      ],
    );
  }
}

/// How to edit or delete an item.
class SwipeHint extends StatelessWidget {
  /// Creates the hint.
  const SwipeHint({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      S.of(context).lb_swipe_hint,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _Spaced extends StatelessWidget {
  const _Spaced({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppDimensions.space8),
    child: child,
  );
}

import 'package:ever_moon/common/app_dimensions.dart';
import 'package:ever_moon/common/app_themes.dart';
import 'package:ever_moon/generated/l10n.dart';
import 'package:ever_moon/pages/widgets/lunar_texts.dart';
import 'package:ever_moon/services/lunar/lunar_calendar_service.dart';
import 'package:flutter/material.dart';

import '../calendar_models.dart';
import '../calendar_state.dart';
import 'calendar_header.dart';
import 'calendar_texts.dart';
import 'event_items.dart';
import 'month_view.dart' show SwipeHint;

/// Seven day rows with their events (design: CalendarWeek; UI-9).
class WeekView extends StatelessWidget {
  /// Creates the view.
  const WeekView({
    super.key,
    required this.state,
    required this.period,
    required this.actions,
    required this.bottomPadding,
  });

  /// Today.
  final CalendarReady state;

  /// The week, Monday first.
  final WeekPeriod period;

  /// Edit and delete handlers.
  final CalendarActions actions;

  /// Room for the FAB.
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final days = period.days;
    // Legend, seven days, hint.
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.space16,
        0,
        AppDimensions.space16,
        AppDimensions.space16 + bottomPadding,
      ),
      itemCount: days.length + 2,
      itemBuilder: (context, index) => _row(index, days),
    );
  }

  Widget _row(int index, List<CalendarDay> days) {
    if (index == 0) return const CalendarLegend();
    if (index > days.length) return const SwipeHint();
    final day = days[index - 1];
    return WeekDayCard(
      day: day,
      isToday: day.solar == state.today,
      actions: actions,
    );
  }
}

/// One day of the week: weekday, number, lunar date, then its events.
class WeekDayCard extends StatelessWidget {
  /// Creates the card.
  const WeekDayCard({
    super.key,
    required this.day,
    required this.isToday,
    required this.actions,
  });

  /// The day.
  final CalendarDay day;

  /// Whether it is today (outlined in primary).
  final bool isToday;

  /// Edit and delete handlers.
  final CalendarActions actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.space8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppDimensions.cornerLarge),
          border: Border.all(
            color: isToday ? scheme.primary : scheme.outlineVariant,
            width: isToday
                ? AppDimensions.borderThick
                : AppDimensions.borderThin,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space8),
          child: _WeekDayContent(day: day, isToday: isToday, actions: actions),
        ),
      ),
    );
  }
}

class _WeekDayContent extends StatelessWidget {
  const _WeekDayContent({
    required this.day,
    required this.isToday,
    required this.actions,
  });

  final CalendarDay day;
  final bool isToday;
  final CalendarActions actions;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: AppDimensions.space8,
    children: [
      // The heading is read as one sentence, "today" included.
      Semantics(
        container: true,
        label: dayCellSemantics(context, day, isToday: isToday),
        excludeSemantics: true,
        child: _WeekDayHeading(day: day),
      ),
      if (day.hasAnniversary || day.hasHoliday)
        DayEvents(day: day, actions: actions),
    ],
  );
}

class _WeekDayHeading extends StatelessWidget {
  const _WeekDayHeading({required this.day});

  final CalendarDay day;

  @override
  Widget build(BuildContext context) {
    final names = S.of(context).lb_weekdays_short.split(',');
    final lunar = day.lunar;
    return Row(
      spacing: AppDimensions.space12,
      children: [
        _WeekdayNumber(
          weekday: names[day.solar.weekday - DateTime.monday],
          number: day.solar.day,
          isSunday: day.solar.weekday == DateTime.sunday,
        ),
        if (lunar != null)
          Expanded(
            child: _LunarLine(day: day, lunar: lunar),
          ),
      ],
    );
  }
}

class _LunarLine extends StatelessWidget {
  const _LunarLine({required this.day, required this.lunar});

  final CalendarDay day;
  final LunarDate lunar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Red for mùng 1, rằm and festivals (UI-14).
    return Text(
      lunarDateText(S.of(context), lunar),
      style: theme.textTheme.bodyMedium?.copyWith(
        color: day.hasHoliday
            ? CalendarColorExtension.of(context).holidayMark
            : theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _WeekdayNumber extends StatelessWidget {
  const _WeekdayNumber({
    required this.weekday,
    required this.number,
    required this.isSunday,
  });

  final String weekday;
  final int number;
  final bool isSunday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: AppDimensions.dateBadgeWidth,
      child: Column(
        children: [
          Text(
            weekday,
            style: theme.textTheme.labelMedium?.copyWith(
              color: isSunday
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text('$number', style: theme.textTheme.titleLarge),
        ],
      ),
    );
  }
}

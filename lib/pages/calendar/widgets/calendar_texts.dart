import 'package:ever_moon/generated/l10n.dart';
import 'package:ever_moon/models/anniversary.dart';
import 'package:ever_moon/pages/widgets/localized_dates.dart';
import 'package:ever_moon/pages/widgets/lunar_texts.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../calendar_models.dart';
import '../calendar_state.dart';

/// Title and subtitle above the shown period.
typedef PeriodTexts = ({String title, String subtitle});

/// Texts for the period header of [state].
PeriodTexts periodTexts(BuildContext context, CalendarReady state) {
  final s = S.of(context);
  return switch (state.period) {
    YearPeriod(:final year) && final p => (
      title: s.lb_year_title(year),
      subtitle: s.lb_year_summary(p.anniversaryCount, p.festivalCount),
    ),
    MonthPeriod(:final year, :final month) && final p => (
      title: monthTitle(context, year, month),
      subtitle: lunarSpanText(s, p.days),
    ),
    WeekPeriod(:final days) => (
      title: weekTitle(context, days),
      subtitle: lunarSpanText(s, days),
    ),
  };
}

/// "Tháng 11, 2026".
String monthTitle(BuildContext context, int year, int month) =>
    formatLocalizedDate(
      context,
      DateTime.utc(year, month),
      S.of(context).lb_month_year_pattern,
    );

/// "23/11 – 29/11/2026".
String weekTitle(BuildContext context, List<CalendarDay> days) {
  final s = S.of(context);
  return s.lb_week_range(
    formatLocalizedDate(context, days.first.solar, s.lb_week_start_pattern),
    formatLocalizedDate(context, days.last.solar, s.lb_week_end_pattern),
  );
}

/// The lunar months [days] cover: "Tháng 9 – tháng 10 âm lịch".
String lunarSpanText(S s, List<CalendarDay> days) {
  final first = days.first.lunar;
  final last = days.last.lunar;
  if (first == null || last == null) return '';
  final from = lunarMonthText(s, first.month, isLeapMonth: first.isLeapMonth);
  final to = lunarMonthText(s, last.month, isLeapMonth: last.isLeapMonth);
  final text = from == to
      ? s.lb_lunar_single(from)
      : s.lb_lunar_range(from, to);
  return toBeginningOfSentenceCase(text);
}

/// Spoken description of a day: today, date, lunar date, marks.
String dayCellSemantics(
  BuildContext context,
  CalendarDay day, {
  required bool isToday,
}) {
  final s = S.of(context);
  final lunar = day.lunar;
  final holiday = day.holiday;
  return [
    if (isToday) s.lb_today_chip,
    formatLocalizedDate(context, day.solar, s.lb_solar_date_pattern),
    if (lunar != null) lunarDateText(s, lunar),
    if (day.hasAnniversary) s.lb_has_anniversary,
    if (holiday != null) holidayName(s, holiday),
  ].join(', ');
}

/// Reminder line under an anniversary item.
String reminderText(BuildContext context, Anniversary anniversary) {
  final s = S.of(context);
  if (!anniversary.reminderEnabled) return s.lb_remind_off;
  final time = formatMinuteOfDay(context, anniversary.remindMinuteOfDay);
  final days = anniversary.remindDaysBefore;
  return days == 0
      ? s.lb_remind_item_on_day(time)
      : s.lb_remind_item_before(days, time);
}

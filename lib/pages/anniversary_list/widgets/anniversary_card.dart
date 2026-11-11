import 'package:ever_moon/common/app_dimensions.dart';
import 'package:ever_moon/generated/l10n.dart';
import 'package:ever_moon/models/upcoming_anniversary.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// One anniversary in the upcoming list: date badge, name, lunar and solar
/// dates, and the countdown or the "today" chip (design: AnniversaryCard).
///
/// Read-only (plan 0005, D15); screen readers hear one sentence.
class AnniversaryCard extends StatelessWidget {
  /// Creates the card for [item].
  const AnniversaryCard({super.key, required this.item});

  /// The entry to show.
  final UpcomingAnniversary item;

  @override
  Widget build(BuildContext context) {
    final texts = _CardTexts.of(context, item);
    return Semantics(
      container: true,
      label: texts.sentence,
      excludeSemantics: true,
      child: _CardFrame(
        isToday: item.isToday,
        children: [
          _DateBadge(item: item),
          Expanded(
            child: _CardLines(texts: texts, isToday: item.isToday),
          ),
          item.isToday
              ? const _TodayChip()
              : _Countdown(daysLeft: item.daysLeft),
        ],
      ),
    );
  }
}

/// Localized strings of one card, computed once per build.
class _CardTexts {
  const _CardTexts(this.name, this.lunar, this.solar, this.sentence);

  factory _CardTexts.of(BuildContext context, UpcomingAnniversary item) {
    final s = S.of(context);
    final lunar = item.lunarDate;
    final lunarText = lunar.isLeapMonth
        ? s.lb_lunar_date_leap(lunar.day, lunar.month)
        : s.lb_lunar_date(lunar.day, lunar.month);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final solarText = toBeginningOfSentenceCase(
      DateFormat(s.lb_solar_date_pattern, locale).format(item.solarDate),
    );
    final countdown = item.isToday
        ? s.lb_today_chip
        : s.lb_countdown_semantics(item.daysLeft);
    final name = item.anniversary.name;
    final sentence = s.lb_anniversary_semantics(
      name,
      lunarText,
      solarText,
      countdown,
    );
    return _CardTexts(name, lunarText, solarText, sentence);
  }

  final String name;
  final String lunar;
  final String solar;
  final String sentence;
}

class _CardFrame extends StatelessWidget {
  const _CardFrame({required this.isToday, required this.children});

  final bool isToday;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isToday ? scheme.tertiaryContainer : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppDimensions.cornerMedium),
        border: isToday ? null : Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space16),
        child: Row(spacing: AppDimensions.space12, children: children),
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.item});

  final UpcomingAnniversary item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final foreground = item.isToday ? scheme.onPrimary : scheme.onSurface;
    final lunar = item.lunarDate;
    return Container(
      width: AppDimensions.dateBadgeWidth,
      height: AppDimensions.dateBadgeHeight,
      decoration: BoxDecoration(
        color: item.isToday ? scheme.primary : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppDimensions.cornerMedium),
      ),
      child: _BadgeNumbers(
        day: '${lunar.day}',
        month: _monthLabel(S.of(context)),
        dayStyle: text.titleLarge?.copyWith(color: foreground),
        monthStyle: text.labelMedium?.copyWith(color: foreground),
      ),
    );
  }

  String _monthLabel(S s) {
    final month = item.lunarDate.month;
    return item.lunarDate.isLeapMonth
        ? s.lb_lunar_month_short_leap(month)
        : s.lb_lunar_month_short(month);
  }
}

class _BadgeNumbers extends StatelessWidget {
  const _BadgeNumbers({
    required this.day,
    required this.month,
    required this.dayStyle,
    required this.monthStyle,
  });

  final String day;
  final String month;
  final TextStyle? dayStyle;
  final TextStyle? monthStyle;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(day, style: dayStyle?.copyWith(fontWeight: FontWeight.w700)),
      Text(month, style: monthStyle, textAlign: TextAlign.center),
    ],
  );
}

class _CardLines extends StatelessWidget {
  const _CardLines({required this.texts, required this.isToday});

  final _CardTexts texts;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    // Text on the beige today card uses the tertiary "fixed" pair so it
    // reads in both themes (design system: today-container).
    final main = isToday ? scheme.onTertiaryFixed : scheme.onSurface;
    final muted = isToday
        ? scheme.onTertiaryFixedVariant
        : scheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          texts.name,
          style: text.titleMedium?.copyWith(color: main),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Text(texts.lunar, style: text.bodyMedium?.copyWith(color: muted)),
        Text(texts.solar, style: text.bodyMedium?.copyWith(color: muted)),
      ],
    );
  }
}

class _Countdown extends StatelessWidget {
  const _Countdown({required this.daysLeft});

  final int daysLeft;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$daysLeft',
          style: text.titleLarge?.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          S.of(context).lb_days_left(daysLeft),
          style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _TodayChip extends StatelessWidget {
  const _TodayChip();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: scheme.primary,
        shape: const StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space12,
          vertical: AppDimensions.space4,
        ),
        child: Text(
          S.of(context).lb_today_chip,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: scheme.onPrimary),
        ),
      ),
    );
  }
}

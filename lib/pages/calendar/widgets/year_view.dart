import 'package:ever_moon/common/app_dimensions.dart';
import 'package:ever_moon/common/app_themes.dart';
import 'package:ever_moon/generated/l10n.dart';
import 'package:ever_moon/pages/widgets/localized_dates.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../calendar_cubit.dart';
import '../calendar_models.dart';
import '../calendar_state.dart';
import 'calendar_header.dart';

/// Twelve month tiles with anniversary and festival counts; a tap opens
/// the month (design: CalendarYear; D15, D16, UI-14).
class YearView extends StatelessWidget {
  /// Creates the view.
  const YearView({
    super.key,
    required this.state,
    required this.period,
    required this.bottomPadding,
  });

  /// Today.
  final CalendarReady state;

  /// The year.
  final YearPeriod period;

  /// Room for the FAB.
  final double bottomPadding;

  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.fromLTRB(
      AppDimensions.space16,
      0,
      AppDimensions.space16,
      AppDimensions.space16 + bottomPadding,
    ),
    // Three fixed parts; the tiles themselves are built by a builder.
    children: [
      const CalendarLegend(),
      _MonthTiles(state: state, period: period),
      const _YearHint(),
    ],
  );
}

class _MonthTiles extends StatelessWidget {
  const _MonthTiles({required this.state, required this.period});

  final CalendarReady state;
  final YearPeriod period;

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.symmetric(vertical: AppDimensions.space12),
    itemCount: period.months.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      mainAxisExtent: AppDimensions.yearTileHeight,
      mainAxisSpacing: AppDimensions.space8,
      crossAxisSpacing: AppDimensions.space8,
    ),
    itemBuilder: (context, index) {
      final summary = period.months[index];
      return MonthTile(
        year: period.year,
        summary: summary,
        isCurrent:
            state.today.year == period.year &&
            state.today.month == summary.month,
      );
    },
  );
}

/// One month of the year view. Three lines are always reserved so every
/// tile has the same height (UI-14).
class MonthTile extends StatelessWidget {
  /// Creates the tile.
  const MonthTile({
    super.key,
    required this.year,
    required this.summary,
    required this.isCurrent,
  });

  /// Gregorian year.
  final int year;

  /// Counts of the month.
  final MonthSummary summary;

  /// Whether today is in this month (outlined in primary).
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final texts = _TileTexts.of(context, year, summary);
    return Semantics(
      button: true,
      label: texts.spoken,
      excludeSemantics: true,
      child: _TileSurface(
        isCurrent: isCurrent,
        onTap: () => context.read<CalendarCubit>().openMonth(summary.month),
        child: _TileContent(texts: texts, summary: summary),
      ),
    );
  }
}

class _TileSurface extends StatelessWidget {
  const _TileSurface({
    required this.isCurrent,
    required this.onTap,
    required this.child,
  });

  final bool isCurrent;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.cornerLarge),
        side: BorderSide(
          color: isCurrent ? scheme.primary : scheme.outlineVariant,
          width: isCurrent
              ? AppDimensions.borderThick
              : AppDimensions.borderThin,
        ),
      ),
      child: InkWell(onTap: onTap, child: child),
    );
  }
}

class _TileTexts {
  const _TileTexts(this.name, this.anniversaries, this.festivals, this.spoken);

  factory _TileTexts.of(BuildContext context, int year, MonthSummary m) {
    final s = S.of(context);
    final name = formatLocalizedDate(
      context,
      DateTime.utc(year, m.month),
      s.lb_month_name_pattern,
    );
    final anniversaries = m.anniversaries == 0
        ? s.lb_month_tile_none
        : s.lb_month_tile_count(m.anniversaries);
    final festivals = m.festivals == 0
        ? ''
        : s.lb_month_tile_festivals(m.festivals);
    final spoken = [
      name,
      anniversaries,
      festivals,
      s.lb_open_month,
    ].where((part) => part.isNotEmpty).join(', ');
    return _TileTexts(name, anniversaries, festivals, spoken);
  }

  final String name;
  final String anniversaries;
  final String festivals;
  final String spoken;
}

class _TileContent extends StatelessWidget {
  const _TileContent({required this.texts, required this.summary});

  final _TileTexts texts;
  final MonthSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final holiday = CalendarColorExtension.of(context).holidayMark;
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(texts.name, style: theme.textTheme.titleSmall, maxLines: 1),
          _OneLine(text: texts.anniversaries, color: muted),
          // Reserved even when empty so the tiles line up.
          _OneLine(text: texts.festivals, color: holiday),
          const Spacer(),
          _TileDots(summary: summary),
        ],
      ),
    );
  }
}

class _OneLine extends StatelessWidget {
  const _OneLine({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
  );
}

class _TileDots extends StatelessWidget {
  const _TileDots({required this.summary});

  /// At most this many dots of each colour.
  static const _maxDots = 3;

  final MonthSummary summary;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final holiday = CalendarColorExtension.of(context).holidayMark;
    final anniversaries = summary.anniversaries.clamp(0, _maxDots);
    final festivals = summary.festivals.clamp(0, _maxDots);
    return Row(
      spacing: AppDimensions.space4,
      children: [
        for (var i = 0; i < anniversaries; i++)
          MarkDot(color: primary, size: AppDimensions.markDot),
        for (var i = 0; i < festivals; i++)
          MarkDot(color: holiday, size: AppDimensions.markDot),
      ],
    );
  }
}

class _YearHint extends StatelessWidget {
  const _YearHint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      S.of(context).lb_year_view_hint,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

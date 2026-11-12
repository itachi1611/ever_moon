import 'package:ever_moon/common/app_dimensions.dart';
import 'package:ever_moon/common/app_themes.dart';
import 'package:ever_moon/generated/l10n.dart';
import 'package:ever_moon/models/anniversary.dart';
import 'package:ever_moon/pages/widgets/lunar_texts.dart';
import 'package:ever_moon/services/lunar/lunar_holidays.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../calendar_models.dart';
import 'calendar_header.dart';
import 'calendar_texts.dart';

/// What the page does when an anniversary is edited or deleted.
class CalendarActions {
  /// Creates the actions.
  const CalendarActions({required this.edit, required this.delete});

  /// Opens the edit form.
  final ValueChanged<Anniversary> edit;

  /// Asks, then deletes.
  final ValueChanged<Anniversary> delete;
}

/// The holiday (if any) and the anniversaries of [day], as items.
class DayEvents extends StatelessWidget {
  /// Creates the items of [day].
  const DayEvents({super.key, required this.day, required this.actions});

  /// The day.
  final CalendarDay day;

  /// Edit and delete handlers.
  final CalendarActions actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppDimensions.space8,
      children: [
        for (final holiday in day.holidays) HolidayItem(holiday: holiday),
        for (final anniversary in day.anniversaries)
          AnniversaryItem(
            key: ValueKey('${anniversary.id}@${day.solar}'),
            anniversary: anniversary,
            actions: actions,
          ),
      ],
    );
  }
}

/// A holiday: not editable, so it does not move (UI-13).
class HolidayItem extends StatelessWidget {
  /// Creates the item.
  const HolidayItem({super.key, required this.holiday});

  /// The holiday.
  final LunarHoliday holiday;

  @override
  Widget build(BuildContext context) {
    final colors = CalendarColorExtension.of(context);
    final s = S.of(context);
    return _ItemFrame(
      color: colors.holidayContainer,
      textColor: colors.onHolidayContainer,
      dot: colors.holidayMark,
      title: holidayName(s, holiday),
      subtitle: holidayKindText(s, holiday),
      chip: s.lb_holiday_chip,
    );
  }
}

/// An anniversary: swipe left to edit, right to delete; TalkBack offers the
/// same two actions (UI-13, D17).
class AnniversaryItem extends StatelessWidget {
  /// Creates the item.
  const AnniversaryItem({
    super.key,
    required this.anniversary,
    required this.actions,
  });

  /// The anniversary.
  final Anniversary anniversary;

  /// Edit and delete handlers.
  final CalendarActions actions;

  /// Share of the item width a swipe must pass to count.
  static const _swipeThreshold = 0.2;

  void _edit() => actions.edit(anniversary);

  void _delete() => actions.delete(anniversary);

  /// The item never leaves by itself: the form opens, or the stream drops
  /// it once the delete is confirmed.
  Future<bool> _onSwipe(DismissDirection direction) async {
    direction == DismissDirection.startToEnd ? _delete() : _edit();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    // A container, so the two actions belong to this item only.
    return Semantics(
      container: true,
      customSemanticsActions: {
        CustomSemanticsAction(label: s.lb_edit): _edit,
        CustomSemanticsAction(label: s.lb_delete): _delete,
      },
      child: Dismissible(
        key: ValueKey(anniversary.id),
        background: _SwipeAction.delete(),
        secondaryBackground: _SwipeAction.edit(),
        // The default 40% of the width needs a long drag; a normal short
        // swipe sprang back and looked like the gesture did nothing.
        dismissThresholds: const {
          DismissDirection.startToEnd: _swipeThreshold,
          DismissDirection.endToStart: _swipeThreshold,
        },
        confirmDismiss: _onSwipe,
        child: _AnniversaryFace(anniversary: anniversary),
      ),
    );
  }
}

class _AnniversaryFace extends StatelessWidget {
  const _AnniversaryFace({required this.anniversary});

  final Anniversary anniversary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _ItemFrame(
      color: scheme.surfaceContainerLow,
      textColor: scheme.onSurface,
      dot: scheme.primary,
      border: scheme.outlineVariant,
      title: anniversary.name,
      subtitle: reminderText(context, anniversary),
      chip: S.of(context).lb_anniversary_chip,
    );
  }
}

/// The colored action behind a swiped item.
class _SwipeAction extends StatelessWidget {
  const _SwipeAction({required this.isDelete});

  factory _SwipeAction.delete() => const _SwipeAction(isDelete: true);

  factory _SwipeAction.edit() => const _SwipeAction(isDelete: false);

  final bool isDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);
    final background = isDelete ? scheme.error : scheme.primary;
    final foreground = isDelete ? scheme.onError : scheme.onPrimary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppDimensions.cornerMedium),
      ),
      child: Align(
        alignment: isDelete
            ? AlignmentDirectional.centerStart
            : AlignmentDirectional.centerEnd,
        child: _ActionLabel(
          icon: isDelete ? Icons.delete_outline : Icons.edit_outlined,
          text: isDelete ? s.lb_delete : s.lb_edit,
          color: foreground,
        ),
      ),
    );
  }
}

class _ActionLabel extends StatelessWidget {
  const _ActionLabel({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color),
        Text(text, style: TextStyle(color: color)),
      ],
    ),
  );
}

/// Shared layout of event items: dot, two lines, chip.
class _ItemFrame extends StatelessWidget {
  const _ItemFrame({
    required this.color,
    required this.textColor,
    required this.dot,
    required this.title,
    required this.subtitle,
    required this.chip,
    this.border,
  });

  final Color color;
  final Color textColor;
  final Color dot;
  final Color? border;
  final String title;
  final String subtitle;
  final String chip;

  @override
  Widget build(BuildContext context) {
    final edge = border;
    return Container(
      constraints: const BoxConstraints(
        minHeight: AppDimensions.eventItemHeight,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: AppDimensions.space8,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppDimensions.cornerMedium),
        border: edge == null ? null : Border.all(color: edge),
      ),
      child: _ItemRow(frame: this),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.frame});

  final _ItemFrame frame;

  @override
  Widget build(BuildContext context) => Row(
    spacing: AppDimensions.space12,
    children: [
      MarkDot(color: frame.dot, size: AppDimensions.legendDot),
      Expanded(child: _ItemLines(frame: frame)),
      _Chip(text: frame.chip, color: frame.textColor),
    ],
  );
}

class _ItemLines extends StatelessWidget {
  const _ItemLines({required this.frame});

  final _ItemFrame frame;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = frame.textColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(frame.title, style: text.titleMedium?.copyWith(color: color)),
        Text(frame.subtitle, style: text.bodyMedium?.copyWith(color: color)),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(color: color),
      borderRadius: BorderRadius.circular(AppDimensions.cornerSmall),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space8,
        vertical: AppDimensions.space4,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    ),
  );
}

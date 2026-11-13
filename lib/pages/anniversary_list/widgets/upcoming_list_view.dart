import 'package:ever_moon/common/app_dimensions.dart';
import 'package:ever_moon/generated/l10n.dart';
import 'package:ever_moon/models/upcoming_anniversary.dart';
import 'package:flutter/material.dart';

import 'anniversary_card.dart';

/// The loaded list: title, summary, then "Hôm nay" and "Sắp tới" sections.
class UpcomingListView extends StatelessWidget {
  /// Creates the list from [today] and [upcoming] entries in display order.
  const UpcomingListView({
    super.key,
    required this.today,
    required this.upcoming,
    this.onEdit,
    this.bottomPadding = 0,
  });

  /// Entries that fall today.
  final List<UpcomingAnniversary> today;

  /// Entries after today.
  final List<UpcomingAnniversary> upcoming;

  /// Called with the anniversary id when a card is tapped.
  final ValueChanged<String>? onEdit;

  /// Extra space at the end so the FAB never covers the last card.
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final rows = _rows(S.of(context));
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.space16,
        AppDimensions.space16,
        AppDimensions.space16,
        AppDimensions.space16 + bottomPadding,
      ),
      itemCount: rows.length,
      // Rows are built only when they scroll into view.
      itemBuilder: (context, index) => rows[index](),
    );
  }

  List<Widget Function()> _rows(S s) => [
    () => UpcomingHeader(
      people: today.length + upcoming.length,
      today: today.length,
    ),
    if (today.isNotEmpty) () => SectionLabel(text: s.lb_section_today),
    for (final item in today)
      () => _Spaced(
        child: _EditableCard(item: item, onEdit: onEdit),
      ),
    if (upcoming.isNotEmpty) () => SectionLabel(text: s.lb_section_upcoming),
    for (final item in upcoming)
      () => _Spaced(
        child: _EditableCard(item: item, onEdit: onEdit),
      ),
  ];
}

/// A card that opens the edit form for its anniversary when [onEdit] is set.
class _EditableCard extends StatelessWidget {
  const _EditableCard({required this.item, required this.onEdit});

  final UpcomingAnniversary item;
  final ValueChanged<String>? onEdit;

  @override
  Widget build(BuildContext context) {
    final edit = onEdit;
    return AnniversaryCard(
      item: item,
      onTap: edit == null ? null : () => edit(item.anniversary.id),
    );
  }
}

/// The "N người · M ngày giỗ hôm nay" summary under the app bar title.
class UpcomingHeader extends StatelessWidget {
  /// Creates the header for [people] entries, [today] of them today.
  const UpcomingHeader({super.key, required this.people, required this.today});

  /// Number of anniversaries in the list.
  final int people;

  /// Number that fall today.
  final int today;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Text(
      today == 0
          ? s.lb_upcoming_summary(people)
          : s.lb_upcoming_summary_today(people, today),
      style: text.bodyMedium?.copyWith(color: muted),
    );
  }
}

/// "Hôm nay" / "Sắp tới" section label.
class SectionLabel extends StatelessWidget {
  /// Creates the label with [text].
  const SectionLabel({super.key, required this.text});

  /// Label text.
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        top: AppDimensions.space24,
        bottom: AppDimensions.space8,
        left: AppDimensions.space4,
      ),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _Spaced extends StatelessWidget {
  const _Spaced({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppDimensions.space12),
    child: child,
  );
}

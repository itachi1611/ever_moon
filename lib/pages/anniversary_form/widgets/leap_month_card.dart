import 'package:ever_moon/common/app_dimensions.dart';
import 'package:ever_moon/generated/l10n.dart';
import 'package:flutter/material.dart';

/// The leap-month question, shown only when the death year repeats the
/// chosen month (UI-5; design: FormNew).
class LeapMonthCard extends StatelessWidget {
  /// Creates the card for [month] with the current answer [value].
  const LeapMonthCard({
    super.key,
    required this.month,
    required this.value,
    required this.onChanged,
  });

  /// The lunar month number that repeats.
  final int month;

  /// Whether the death was in the leap month.
  final bool value;

  /// Called with the new answer.
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);
    // Text on tertiary-container uses the fixed "on" colors (design tokens).
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      tileColor: scheme.tertiaryContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(AppDimensions.cornerMedium),
        ),
      ),
      title: Text(
        s.lb_leap_title(month),
        style: TextStyle(color: scheme.onTertiaryFixed),
      ),
      subtitle: Text(
        s.lb_leap_body(month),
        style: TextStyle(color: scheme.onTertiaryFixedVariant),
      ),
    );
  }
}

import 'package:ever_moon/common/app_dimensions.dart';
import 'package:flutter/material.dart';

/// A section heading in primary colour (design: Settings).
class SectionTitle extends StatelessWidget {
  /// Creates the heading.
  const SectionTitle({super.key, required this.text});

  /// Heading text.
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppDimensions.space4,
        AppDimensions.space16,
        AppDimensions.space4,
        AppDimensions.space8,
      ),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// Rounded surface that groups the rows of one section; a Material, so
/// the tiles inside show their ripple.
class SectionCard extends StatelessWidget {
  /// Creates the card around [children].
  const SectionCard({super.key, required this.children});

  /// The rows.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    borderRadius: BorderRadius.circular(AppDimensions.cornerLarge),
    clipBehavior: Clip.antiAlias,
    child: Column(children: children),
  );
}

/// A label above a full-width control, such as a segmented button.
class LabeledControl extends StatelessWidget {
  /// Creates the row.
  const LabeledControl({super.key, required this.label, required this.child});

  /// Label text.
  final String label;

  /// The control.
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppDimensions.space16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppDimensions.space8,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        child,
      ],
    ),
  );
}

import 'package:ever_moon/common/app_dimensions.dart';
import 'package:ever_moon/generated/l10n.dart';
import 'package:flutter/material.dart';

/// Shown before the first anniversary is added (UI-2).
class EmptyUpcomingView extends StatelessWidget {
  /// Creates the empty state; [onAdd] is `null` until the form exists.
  const EmptyUpcomingView({super.key, this.onAdd});

  /// Opens the add form.
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return _CenteredColumn(
      children: [
        const _MoonDisc(),
        Text(
          s.lb_empty_title,
          style: text.headlineMedium,
          textAlign: TextAlign.center,
        ),
        Text(
          s.lb_empty_body,
          style: text.bodyLarge?.copyWith(color: muted),
          textAlign: TextAlign.center,
        ),
        if (onAdd != null)
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(s.lb_add_anniversary),
          ),
      ],
    );
  }
}

/// Shown when the list could not be read.
class FailedUpcomingView extends StatelessWidget {
  /// Creates the failure view with a [onRetry] action.
  const FailedUpcomingView({super.key, required this.onRetry});

  /// Starts reading the list again.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return _CenteredColumn(
      children: [
        Text(
          s.lb_load_failed,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        OutlinedButton(onPressed: onRetry, child: Text(s.lb_retry)),
      ],
    );
  }
}

class _CenteredColumn extends StatelessWidget {
  const _CenteredColumn({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.space32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: AppDimensions.space16,
        children: children,
      ),
    ),
  );
}

class _MoonDisc extends StatelessWidget {
  const _MoonDisc();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Container(
        width: AppDimensions.emptyStateDisc,
        height: AppDimensions.emptyStateDisc,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.nightlight_outlined,
          size: AppDimensions.emptyStateIcon,
          color: scheme.primary,
        ),
      ),
    );
  }
}

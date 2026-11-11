import 'package:ever_moon/common/app_dimensions.dart';
import 'package:flutter/material.dart';

/// Picture of an onboarding page: a large disc with an inner circle and
/// one icon (simplified from the design's illustrations). Decorative.
class IntroIllustration extends StatelessWidget {
  /// Creates the illustration around [icon].
  const IntroIllustration({super.key, required this.icon});

  /// The symbol in the middle.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Shrinks on small or landscape screens instead of overflowing.
    return ExcludeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppDimensions.introDisc),
        child: AspectRatio(
          aspectRatio: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: Center(child: _InnerCircle(icon: icon)),
          ),
        ),
      ),
    );
  }
}

class _InnerCircle extends StatelessWidget {
  const _InnerCircle({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FractionallySizedBox(
      widthFactor: AppDimensions.introInnerDisc / AppDimensions.introDisc,
      heightFactor: AppDimensions.introInnerDisc / AppDimensions.introDisc,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: AppDimensions.introIcon, color: scheme.primary),
      ),
    );
  }
}

/// Title and one line under an illustration.
class IntroTexts extends StatelessWidget {
  /// Creates the texts.
  const IntroTexts({super.key, required this.title, required this.body});

  /// Headline.
  final String title;

  /// One short line.
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      spacing: AppDimensions.space8,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
        ),
        Text(
          body,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

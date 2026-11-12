import 'package:animations/animations.dart';
import 'package:ever_moon/common/app_dimensions.dart';
import 'package:ever_moon/generated/l10n.dart';
import 'package:flutter/material.dart';

/// Builds the add form; [close] returns to the page that opened it.
typedef AddFormBuilder = Widget Function(VoidCallback close);

/// How long the add button takes to grow into the form and back.
const Duration _containerDuration = Duration(milliseconds: 400);

/// The add button, as the closed state of a Material container transform:
/// it grows into the add form and shrinks back when the form closes.
///
/// Used for the extended button on the list and the calendar (the package
/// pattern for "a FAB into a details page"). The form opens on the root
/// navigator so it covers the navigation drawer's shell.
class AddAnniversaryFab extends StatelessWidget {
  /// Creates the button; [formBuilder] builds the form it opens.
  const AddAnniversaryFab({super.key, required this.formBuilder});

  /// Builds the form shown once the container is open.
  final AddFormBuilder formBuilder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return OpenContainer<void>(
      useRootNavigator: true,
      transitionDuration: _containerDuration,
      closedColor: scheme.primary,
      closedElevation: AppDimensions.fabElevation,
      closedShape: const StadiumBorder(),
      openColor: Theme.of(context).scaffoldBackgroundColor,
      openElevation: 0,
      openShape: const RoundedRectangleBorder(),
      closedBuilder: (context, open) => _FabFace(color: scheme.onPrimary),
      openBuilder: (context, close) => formBuilder(() => close()),
    );
  }
}

class _FabFace extends StatelessWidget {
  const _FabFace({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Semantics(
      button: true,
      label: s.lb_add_anniversary,
      excludeSemantics: true,
      child: SizedBox(
        height: AppDimensions.fabSize,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space16,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppDimensions.space8,
            children: [
              Icon(Icons.add, color: color),
              Text(
                s.lb_add,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The empty state's add button, a container transform into the add form.
class AddAnniversaryButton extends StatelessWidget {
  /// Creates the button; [formBuilder] builds the form it opens.
  const AddAnniversaryButton({super.key, required this.formBuilder});

  /// Builds the form shown once the container is open.
  final AddFormBuilder formBuilder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);
    return OpenContainer<void>(
      useRootNavigator: true,
      transitionDuration: _containerDuration,
      closedColor: scheme.primary,
      closedElevation: 0,
      closedShape: const StadiumBorder(),
      openColor: Theme.of(context).scaffoldBackgroundColor,
      openElevation: 0,
      openShape: const RoundedRectangleBorder(),
      closedBuilder: (context, open) => Semantics(
        button: true,
        label: s.lb_add_anniversary,
        excludeSemantics: true,
        child: SizedBox(
          height: AppDimensions.buttonHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space24,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: AppDimensions.space8,
              children: [
                Icon(Icons.add, color: scheme.onPrimary),
                Text(
                  s.lb_add_anniversary,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: scheme.onPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
      openBuilder: (context, close) => formBuilder(() => close()),
    );
  }
}

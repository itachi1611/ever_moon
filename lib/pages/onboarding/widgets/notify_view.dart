import 'package:ever_moon/common/app_dimensions.dart';
import 'package:ever_moon/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../onboarding_cubit.dart';
import 'intro_illustration.dart';

/// Explains notifications before the system dialog (design: IntroNotify;
/// D18). "Cho phép" asks; "Để sau" does not.
class NotifyView extends StatelessWidget {
  /// Creates the view; the buttons are disabled while [busy].
  const NotifyView({super.key, required this.busy});

  /// Whether the system dialog is open.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.space24),
      child: Column(
        children: [
          const Expanded(
            child: Center(
              child: IntroIllustration(icon: Icons.notifications_outlined),
            ),
          ),
          IntroTexts(title: s.lb_notify_title, body: s.lb_notify_body),
          const SizedBox(height: AppDimensions.space24),
          _NotifyButtons(busy: busy),
        ],
      ),
    );
  }
}

class _NotifyButtons extends StatelessWidget {
  const _NotifyButtons({required this.busy});

  final bool busy;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cubit = context.read<OnboardingCubit>();
    const height = Size.fromHeight(AppDimensions.minTouchTarget);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppDimensions.space8,
      children: [
        FilledButton(
          onPressed: busy ? null : cubit.allow,
          style: FilledButton.styleFrom(minimumSize: height),
          child: Text(s.lb_allow),
        ),
        TextButton(
          onPressed: busy ? null : cubit.later,
          style: TextButton.styleFrom(minimumSize: height),
          child: Text(s.lb_later),
        ),
      ],
    );
  }
}

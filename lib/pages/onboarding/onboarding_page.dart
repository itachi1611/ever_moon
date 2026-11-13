import 'package:ever_moon/services/exact_alarm_access_service.dart';
import 'package:ever_moon/services/notification_access_service.dart';
import 'package:ever_moon/storage/app_preference.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'onboarding_cubit.dart';
import 'onboarding_state.dart';
import 'widgets/intro_pager.dart';
import 'widgets/notify_view.dart';

/// First launch: three intro pages, then the notification explanation
/// (plan 0005, U7; design page "Flow: Mở app").
class OnboardingPage extends StatefulWidget {
  /// Creates the page; tests pass [access] and [markComplete].
  const OnboardingPage({
    super.key,
    required this.onDone,
    this.onNotificationsAllowed,
    this.access,
    this.exactAlarm,
    this.markComplete,
  });

  /// Opens the list once the flow is over.
  final VoidCallback onDone;

  /// Runs once the user allowed notifications (the route passes the push
  /// token refresh).
  final Future<void> Function()? onNotificationsAllowed;

  /// Notification permission; the plugin-backed one when `null`.
  final NotificationAccessService? access;

  /// Exact alarm permission; the plugin-backed one when `null`.
  final ExactAlarmAccessService? exactAlarm;

  /// Stores the first-run flag; [AppPreference] when `null`.
  final Future<void> Function()? markComplete;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late final OnboardingCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = OnboardingCubit(
      access: widget.access ?? notificationAccessService,
      exactAlarm: widget.exactAlarm ?? exactAlarmAccessService,
      markComplete:
          widget.markComplete ??
          () => AppPreference.instance.setCompleteIntro(true),
      onNotificationsAllowed: widget.onNotificationsAllowed,
    );
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _cubit,
    child: BlocListener<OnboardingCubit, OnboardingState>(
      listenWhen: (_, next) => next is OnboardingDone,
      listener: (_, _) => widget.onDone(),
      child: Scaffold(
        body: SafeArea(
          child: BlocBuilder<OnboardingCubit, OnboardingState>(
            buildWhen: (previous, next) =>
                previous.runtimeType != next.runtimeType ||
                next is OnboardingNotify,
            builder: (context, state) => switch (state) {
              OnboardingSlides() => const IntroPager(),
              OnboardingNotify(:final busy) => NotifyView(busy: busy),
              OnboardingDone() => const SizedBox.shrink(),
            },
          ),
        ),
      ),
    ),
  );
}

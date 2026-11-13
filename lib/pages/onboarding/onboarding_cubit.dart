import 'package:ever_moon/services/exact_alarm_access_service.dart';
import 'package:ever_moon/services/notification_access_service.dart';
import 'package:ever_moon/utils/app_logger.dart' as logger;
import 'package:flutter_bloc/flutter_bloc.dart';

import 'onboarding_state.dart';

/// Runs the intro once, then asks for notifications only when the user
/// taps "Cho phép" (plan 0005, U7; D18, UI-15).
class OnboardingCubit extends Cubit<OnboardingState> {
  /// Creates the Cubit.
  ///
  /// [markComplete] stores the first-run flag; [onNotificationsAllowed]
  /// runs after the user allowed notifications (the push token refresh).
  OnboardingCubit({
    required NotificationAccessService access,
    required ExactAlarmAccessService exactAlarm,
    required Future<void> Function() markComplete,
    Future<void> Function()? onNotificationsAllowed,
  }) : _access = access,
       _exactAlarm = exactAlarm,
       _markComplete = markComplete,
       _onNotificationsAllowed = onNotificationsAllowed,
       super(const OnboardingSlides(IntroSlide.lunar));

  final NotificationAccessService _access;
  final ExactAlarmAccessService _exactAlarm;
  final Future<void> Function() _markComplete;
  final Future<void> Function()? _onNotificationsAllowed;

  /// The page the user swiped to.
  void showSlide(IntroSlide slide) {
    if (state is OnboardingSlides) emit(OnboardingSlides(slide));
  }

  /// "Tiếp tục", or "Bắt đầu" on the last page.
  void next() {
    final current = state;
    if (current is! OnboardingSlides) return;
    if (current.isLast) return skip();
    emit(OnboardingSlides(IntroSlide.values[current.slide.index + 1]));
  }

  /// "Bỏ qua": straight to the notification screen.
  void skip() {
    if (state is OnboardingSlides) emit(const OnboardingNotify());
  }

  /// "Cho phép": the system dialog, then the exact alarm page when it is
  /// still needed, then the list whatever the answers.
  Future<void> allow() async {
    final current = state;
    if (current is! OnboardingNotify || current.busy) return;
    emit(const OnboardingNotify(busy: true));
    try {
      if (await _access.request() == NotificationAccess.granted) {
        runQuietly(_onNotificationsAllowed, 'Push token refresh failed');
        await _askExactAlarm();
      }
    } catch (error, stackTrace) {
      logger.err('Notification permission request failed', error, stackTrace);
    }
    await _finish();
  }

  Future<void> _askExactAlarm() async {
    try {
      if (!await _exactAlarm.isAllowed()) await _exactAlarm.request();
    } catch (error, stackTrace) {
      // Reminders still work, only inexact.
      logger.err('Exact alarm request failed', error, stackTrace);
    }
  }

  /// "Để sau": no dialog; Settings can ask later (D18).
  Future<void> later() async {
    final current = state;
    if (current is! OnboardingNotify || current.busy) return;
    emit(const OnboardingNotify(busy: true));
    await _finish();
  }

  Future<void> _finish() async {
    try {
      await _markComplete();
    } catch (error, stackTrace) {
      // The intro shows again next time; the user still gets to the app.
      logger.err('First-run flag not stored', error, stackTrace);
    }
    if (!isClosed) emit(const OnboardingDone());
  }
}

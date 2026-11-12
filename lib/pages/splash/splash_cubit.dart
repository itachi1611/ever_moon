import 'package:ever_moon/services/notification_access_service.dart';
import 'package:ever_moon/utils/app_logger.dart' as logger;
import 'package:flutter_bloc/flutter_bloc.dart';

import 'splash_state.dart';

/// Decides the first screen (plan 0005, U7; UI-15, D18).
///
/// Never asks for the notification permission: that happens only on the
/// onboarding explanation screen or from Settings.
class SplashCubit extends Cubit<SplashState> {
  /// Creates the Cubit.
  ///
  /// [hasCompletedIntro] reads the first-run flag. [onNotificationsAllowed]
  /// runs on later launches when notifications are already allowed (the
  /// push token refresh); it must not show any dialog.
  SplashCubit({
    required bool Function() hasCompletedIntro,
    required NotificationAccessService access,
    Future<void> Function()? onNotificationsAllowed,
    this.minimumDisplay = defaultMinimumDisplay,
  }) : _hasCompletedIntro = hasCompletedIntro,
       _access = access,
       _onNotificationsAllowed = onNotificationsAllowed,
       super(const SplashChecking());

  /// Default for [minimumDisplay].
  static const defaultMinimumDisplay = Duration(milliseconds: 1500);

  final bool Function() _hasCompletedIntro;
  final NotificationAccessService _access;
  final Future<void> Function()? _onNotificationsAllowed;

  /// How long the mark stays up at least, so it is seen instead of flashing
  /// past on a fast read.
  final Duration minimumDisplay;

  /// Reads the flag and emits [SplashReady] once [minimumDisplay] has passed.
  Future<void> start() async {
    final shown = Future<void>.delayed(minimumDisplay);
    final firstRun = !_hasCompletedIntro();
    if (!firstRun) await _refreshIfAllowed();
    await shown;
    if (!isClosed) emit(SplashReady(firstRun: firstRun));
  }

  Future<void> _refreshIfAllowed() async {
    if (_onNotificationsAllowed == null) return;
    try {
      if (await _access.status() == NotificationAccess.granted) {
        runQuietly(_onNotificationsAllowed, 'Push token refresh failed');
      }
    } catch (error, stackTrace) {
      logger.err('Notification status could not be read', error, stackTrace);
    }
  }
}

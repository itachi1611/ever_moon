import 'dart:async';

import 'package:ever_moon/utils/app_logger.dart' as logger;
import 'package:permission_handler/permission_handler.dart';

/// Starts [task] without waiting and logs its failure with [message].
///
/// For side work such as the push token refresh, whose failure must not
/// reach the caller but must not go unnoticed either.
void runQuietly(Future<void> Function()? task, String message) {
  if (task == null) return;
  unawaited(
    task().catchError((Object error, StackTrace stackTrace) {
      logger.err(message, error, stackTrace);
    }),
  );
}

/// Global getter for the notification permission port.
NotificationAccessService get notificationAccessService =>
    PermissionHandlerNotificationAccess.instance;

/// Whether the app may post notifications (plan 0005, D18).
enum NotificationAccess {
  /// Notifications are allowed.
  granted,

  /// Not allowed yet; asking can show the system dialog.
  denied,

  /// Android will not show the dialog again; only the system settings can
  /// turn notifications on.
  blocked,
}

/// Reads and requests the notification permission.
///
/// The onboarding and Settings pages use this port, never the plugin, so
/// tests can fake it and the permission is only asked where D18 allows.
abstract interface class NotificationAccessService {
  /// The current state, without asking.
  Future<NotificationAccess> status();

  /// Shows the system dialog when Android still allows it.
  Future<NotificationAccess> request();

  /// Opens this app's page in the system settings.
  Future<void> openSettings();
}

/// [NotificationAccessService] on `permission_handler`.
class PermissionHandlerNotificationAccess implements NotificationAccessService {
  PermissionHandlerNotificationAccess._();

  /// The single instance; prefer the [notificationAccessService] getter.
  static final PermissionHandlerNotificationAccess instance =
      PermissionHandlerNotificationAccess._();

  @override
  Future<NotificationAccess> status() async =>
      _access(await Permission.notification.status);

  @override
  Future<NotificationAccess> request() async =>
      _access(await Permission.notification.request());

  @override
  Future<void> openSettings() async {
    if (!await openAppSettings()) {
      logger.warn('The system settings page could not be opened');
    }
  }

  static NotificationAccess _access(PermissionStatus status) =>
      switch (status) {
        PermissionStatus.granted ||
        PermissionStatus.limited ||
        PermissionStatus.provisional => NotificationAccess.granted,
        PermissionStatus.permanentlyDenied ||
        PermissionStatus.restricted => NotificationAccess.blocked,
        PermissionStatus.denied => NotificationAccess.denied,
      };
}

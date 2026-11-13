import 'dart:io' show Platform;

import 'package:ever_moon/utils/app_logger.dart' as logger;
import 'package:permission_handler/permission_handler.dart';

/// Global getter for the exact alarm permission port.
ExactAlarmAccessService get exactAlarmAccessService =>
    PermissionHandlerExactAlarmAccess.instance;

/// Reads and requests the "alarms and reminders" permission (Android 12+).
///
/// Without it Android may deliver a reminder minutes late, so Settings and
/// the onboarding send the user to the system page that grants it. The
/// reminder scheduler already schedules exactly when it is granted (plan
/// 0006, D-R5).
abstract interface class ExactAlarmAccessService {
  /// Whether reminders can be delivered at the exact minute. Always `true`
  /// where the platform has no such restriction.
  Future<bool> isAllowed();

  /// Opens the system page where the user grants the permission and returns
  /// whether it is granted when the user comes back.
  Future<bool> request();
}

/// [ExactAlarmAccessService] on `permission_handler`.
class PermissionHandlerExactAlarmAccess implements ExactAlarmAccessService {
  PermissionHandlerExactAlarmAccess._();

  /// The single instance; prefer the [exactAlarmAccessService] getter.
  static final PermissionHandlerExactAlarmAccess instance =
      PermissionHandlerExactAlarmAccess._();

  @override
  Future<bool> isAllowed() async {
    // Only Android restricts exact alarms.
    if (!Platform.isAndroid) return true;
    return Permission.scheduleExactAlarm.isGranted;
  }

  @override
  Future<bool> request() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.scheduleExactAlarm.request();
    if (!status.isGranted) {
      logger.info('Exact alarm permission not granted: $status');
    }
    return status.isGranted;
  }
}

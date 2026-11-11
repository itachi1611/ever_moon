import 'package:ever_moon/services/notification_access_service.dart';

/// Scripted notification permission; counts dialogs and settings visits.
class FakeNotificationAccess implements NotificationAccessService {
  /// Creates the fake in [current]; [afterRequest] is the dialog's answer.
  FakeNotificationAccess({
    this.current = NotificationAccess.denied,
    this.afterRequest = NotificationAccess.granted,
  });

  /// What [status] returns.
  NotificationAccess current;

  /// What the system dialog answers.
  NotificationAccess afterRequest;

  /// Times the system dialog was shown.
  int requests = 0;

  /// Times the system settings were opened.
  int settingsOpened = 0;

  @override
  Future<NotificationAccess> status() async => current;

  @override
  Future<NotificationAccess> request() async {
    requests++;
    return current = afterRequest;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;
}

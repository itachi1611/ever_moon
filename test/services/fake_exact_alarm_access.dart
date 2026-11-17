import 'package:ever_moon/services/exact_alarm_access_service.dart';

/// Scripted exact alarm permission; counts the visits to the system page.
class FakeExactAlarmAccess implements ExactAlarmAccessService {
  /// Creates the fake; [allowed] is the current state and [grantOnRequest]
  /// what the system page ends up with.
  FakeExactAlarmAccess({this.allowed = false, this.grantOnRequest = true});

  /// What [isAllowed] returns.
  bool allowed;

  /// Whether the user grants the permission on the system page.
  bool grantOnRequest;

  /// Times the system page was opened to grant the permission.
  int requests = 0;

  /// Times the system page was opened to review the permission.
  int settingsOpened = 0;

  @override
  Future<bool> isAllowed() async => allowed;

  @override
  Future<bool> request() async {
    requests++;
    return allowed = grantOnRequest;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;
}

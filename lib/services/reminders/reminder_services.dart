import 'package:ever_moon/repositories/anniversary_repository.dart';
import 'package:ever_moon/routing/app_router.dart' show appRouter;
import 'package:ever_moon/routing/routers.dart';
import 'package:ever_moon/services/firebase_notification_service.dart';
import 'package:ever_moon/services/lunar/anniversary_resolver.dart';
import 'package:ever_moon/services/lunar/lunar_calendar_service.dart';
import 'package:ever_moon/services/notification_access_service.dart';
import 'package:ever_moon/services/reminders/fln_notification_backend.dart';
import 'package:ever_moon/services/reminders/notification_gateway.dart';
import 'package:ever_moon/services/reminders/reminder_planner.dart';
import 'package:ever_moon/services/reminders/reminder_sync_service.dart';
import 'package:ever_moon/services/reminders/reminder_sync_triggers.dart';
import 'package:ever_moon/storage/settings_store.dart';

/// The app-wide reminder sync, built over the real engine, plugin, database
/// and settings.
final ReminderSyncService reminderSyncService = ReminderSyncService(
  planner: ReminderPlanner(
    resolver: AnniversaryResolver(lunarCalendarService),
    calendar: lunarCalendarService,
  ),
  gateway: BackendNotificationGateway(FlnNotificationBackend()),
  access: notificationAccessService,
  settings: settingsStore,
  repository: anniversaryRepository,
);

/// Starts keeping reminders in sync and opens the list when a reminder is
/// tapped. Call once, after storage and notifications are initialized.
ReminderSyncTriggers startReminderSync() {
  openHomeOnReminderTap(
    FirebaseNotificationService.instance.onNotificationTap,
    () => appRouter.go(Routers.home.routerPath),
  );
  return ReminderSyncTriggers(
    service: reminderSyncService,
    anniversaries: anniversaryRepository.watchAll(),
    settingsChanges: PreferenceSettingsStore.instance.changes,
  )..start();
}

import 'dart:ui' show DartPluginRegistrant;

import 'package:ever_moon/services/reminders/reminder_services.dart';
import 'package:ever_moon/storage/app_preference.dart';
import 'package:ever_moon/utils/app_logger.dart' as logger;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Channel the Android receiver listens on; the Dart side calls `done` when
/// the sync has finished so the headless engine can be destroyed.
const MethodChannel _resyncChannel = MethodChannel('com.fox.evermoon/resync');

/// Body of the headless engine that Android starts when the phone's time
/// zone changes while the app is not in the foreground. The entry point
/// itself is `resyncRemindersAfterZoneChange` in `main.dart`: a library that
/// nothing imports is left out of the program, so the entry point must live
/// in one that is.
///
/// Reminders are wall-clock times (07:00 stays 07:00 wherever the phone is),
/// so the pending alarms are wrong the moment the zone changes. This re-runs
/// the same sync as every other trigger and tells the native side when done,
/// whatever the outcome (plan 0006, N7).
Future<void> runZoneChangeResync() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  logger.info('Zone resync: engine started');
  try {
    await AppPreference.init();
    logger.info('Zone resync: preferences ready');
    await reminderSyncService.syncReminders();
    logger.info('Zone resync: done');
  } catch (error, stackTrace) {
    logger.err('Reminder resync after a zone change failed', error, stackTrace);
  } finally {
    await _resyncChannel.invokeMethod<void>('done');
  }
}

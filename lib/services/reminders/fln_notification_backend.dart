import 'dart:io';

import 'package:ever_moon/models/app_settings.dart';
import 'package:ever_moon/services/reminders/notification_gateway.dart';
import 'package:ever_moon/utils/app_logger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Android raw resource of the soft bell sound (`res/raw/soft_bell.wav`).
const String softBellResource = 'soft_bell';

/// [wallClock] read as local time in [location].
///
/// Reminders are stored as wall-clock times (07:00 stays 07:00 wherever the
/// phone is), so the same value is a different instant per zone. A time that
/// does not exist in [location] (a daylight-saving gap) is shifted forward by
/// the `timezone` package.
tz.TZDateTime zonedWallClock(DateTime wallClock, tz.Location location) =>
    tz.TZDateTime(
      location,
      wallClock.year,
      wallClock.month,
      wallClock.day,
      wallClock.hour,
      wallClock.minute,
    );

/// Old zone names that Android still reports but the `timezone` database
/// lacks (found on a Pixel 8: `Asia/Saigon`), mapped to their current names.
const Map<String, String> legacyZoneNames = {
  'Asia/Saigon': 'Asia/Ho_Chi_Minh',
  'Asia/Calcutta': 'Asia/Kolkata',
  'Asia/Katmandu': 'Asia/Kathmandu',
  'Asia/Rangoon': 'Asia/Yangon',
  'Asia/Dacca': 'Asia/Dhaka',
  'Asia/Thimbu': 'Asia/Thimphu',
  'Asia/Ulan_Bator': 'Asia/Ulaanbaatar',
  'Asia/Macao': 'Asia/Macau',
  'America/Buenos_Aires': 'America/Argentina/Buenos_Aires',
  'Europe/Kiev': 'Europe/Kyiv',
};

/// The `timezone` location for the phone's zone [zoneName].
///
/// Tries the name, then its current name from [legacyZoneNames]. If the
/// database still does not know it, returns a fixed-offset location at
/// [utcOffset]: right for every zone without daylight saving, and for the
/// others until the next clock change (the next sync corrects it). It never
/// falls back to UTC, which would shift every reminder by the phone's offset.
/// [lookup] is injectable for tests.
tz.Location resolveDeviceLocation(
  String zoneName,
  Duration utcOffset, {
  tz.Location Function(String name)? lookup,
}) {
  final find = lookup ?? tz.getLocation;
  for (final name in [zoneName, legacyZoneNames[zoneName]]) {
    if (name == null) continue;
    try {
      return find(name);
    } on Exception catch (e, s) {
      warn('Time zone "$name" is not in the database', e, s);
    }
  }
  return tz.Location('device_offset', const [], const [], [
    tz.TimeZone(utcOffset, isDst: false, abbreviation: 'DEVICE'),
  ]);
}

/// [NotificationBackend] over `flutter_local_notifications` (plan 0006, N2).
///
/// Not unit-tested: it only forwards to the plugin, so it is checked on a
/// device (RS-12 to RS-14). The replace logic lives in
/// [BackendNotificationGateway].
class FlnNotificationBackend implements NotificationBackend {
  /// Creates the backend. The plugin is a process-wide singleton, so this
  /// shares initialization with `NotificationService`.
  FlnNotificationBackend({
    FlutterLocalNotificationsPlugin? plugin,
    Future<String> Function()? localZoneName,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _localZoneName = localZoneName ?? _deviceZoneName;

  final FlutterLocalNotificationsPlugin _plugin;
  final Future<String> Function() _localZoneName;
  bool _zonesLoaded = false;

  static Future<String> _deviceZoneName() async =>
      (await FlutterTimezone.getLocalTimezone()).identifier;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> prepare(List<ReminderNotification> reminders) async {
    await _refreshTimeZone();
    final android = _android;
    if (android == null) return;
    final channels = {for (final r in reminders) r.channelId: r};
    for (final reminder in channels.values) {
      await android.createNotificationChannel(_channel(reminder));
    }
  }

  @override
  Future<bool> canScheduleExact() async {
    if (!Platform.isAndroid) return true;
    return await _android?.canScheduleExactNotifications() ?? false;
  }

  @override
  Future<Set<int>> pendingIds() async => {
    for (final p in await _plugin.pendingNotificationRequests()) p.id,
  };

  @override
  Future<void> schedule(ReminderNotification reminder, {required bool exact}) =>
      _plugin.zonedSchedule(
        id: reminder.id,
        scheduledDate: zonedWallClock(reminder.fireAt, tz.local),
        notificationDetails: _details(reminder),
        androidScheduleMode: exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        title: reminder.title,
        body: reminder.body,
        payload: reminder.payload,
      );

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  /// Points `tz.local` at the phone's current zone (see
  /// [resolveDeviceLocation] for names the database does not know). If the
  /// zone name cannot be read at all, the phone's current offset is used.
  Future<void> _refreshTimeZone() async {
    if (!_zonesLoaded) {
      tzdata.initializeTimeZones();
      _zonesLoaded = true;
    }
    var name = '';
    try {
      name = await _localZoneName();
    } on Exception catch (e, s) {
      warn('Device time zone name not readable; using its offset', e, s);
    }
    tz.setLocalLocation(
      resolveDeviceLocation(name, DateTime.now().timeZoneOffset),
    );
  }

  AndroidNotificationChannel _channel(ReminderNotification r) =>
      AndroidNotificationChannel(
        r.channelId,
        r.channelName,
        description: r.channelDescription,
        importance: Importance.high,
        playSound: r.sound != ReminderSound.silent,
        sound: _androidSound(r.sound),
        enableVibration: r.vibrate,
      );

  NotificationDetails _details(ReminderNotification r) => NotificationDetails(
    android: AndroidNotificationDetails(
      r.channelId,
      r.channelName,
      channelDescription: r.channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: r.sound != ReminderSound.silent,
      sound: _androidSound(r.sound),
      enableVibration: r.vibrate,
    ),
    // The soft bell is an Android resource only for now (plan 0006, N5);
    // iOS plays its default sound for it.
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentSound: r.sound != ReminderSound.silent,
    ),
  );

  AndroidNotificationSound? _androidSound(ReminderSound sound) =>
      sound == ReminderSound.softBell
      ? const RawResourceAndroidNotificationSound(softBellResource)
      : null;
}

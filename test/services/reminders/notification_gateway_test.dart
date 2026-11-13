// Notification gateway (plan 0006, N2; RS-10, RS-11) and the wall-clock to
// zoned conversion that RS-14 relies on. The plugin itself is only exercised
// on a device; here a hand-written fake backend stands in for it.
import 'package:ever_moon/models/app_settings.dart';
import 'package:ever_moon/services/reminders/fln_notification_backend.dart';
import 'package:ever_moon/services/reminders/notification_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class _FakeBackend implements NotificationBackend {
  _FakeBackend({
    this.exactAllowed = true,
    Set<int>? pending,
    this.failOn = const {},
  }) : pending = pending ?? <int>{};

  bool exactAllowed;
  final Set<int> pending;
  final Set<int> failOn;
  final List<({int id, bool exact})> scheduled = [];
  final List<int> cancelled = [];
  int prepareCalls = 0;

  @override
  Future<void> prepare(List<ReminderNotification> reminders) async =>
      prepareCalls++;

  @override
  Future<bool> canScheduleExact() async => exactAllowed;

  @override
  Future<Set<int>> pendingIds() async => {...pending};

  @override
  Future<void> schedule(
    ReminderNotification reminder, {
    required bool exact,
  }) async {
    if (failOn.contains(reminder.id)) throw Exception('boom ${reminder.id}');
    scheduled.add((id: reminder.id, exact: exact));
    pending.add(reminder.id);
  }

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    pending.remove(id);
  }
}

ReminderNotification _n(
  int id, {
  ReminderSound sound = ReminderSound.deviceDefault,
  bool vibrate = true,
}) => ReminderNotification(
  id: id,
  fireAt: DateTime(2030, 1, 1, 7),
  title: 'title $id',
  body: 'body $id',
  sound: sound,
  vibrate: vibrate,
  channelName: 'Reminders',
  channelDescription: 'Anniversary reminders',
);

void main() {
  group('replaceAll', () {
    test(
      'schedules every reminder and cancels the ones no longer planned',
      () async {
        final backend = _FakeBackend(pending: {1, 2, 99});
        final gateway = BackendNotificationGateway(backend);

        final result = await gateway.replaceAll([_n(1), _n(2), _n(3)]);

        expect(result, (scheduled: 3, failed: 0, cancelled: 1));
        expect(backend.pending, {1, 2, 3});
        expect(backend.cancelled, [99]);
        expect(backend.prepareCalls, 1);
      },
    );

    test('running it twice leaves the pending set unchanged', () async {
      final backend = _FakeBackend();
      final gateway = BackendNotificationGateway(backend);
      final plan = [_n(1), _n(2)];

      await gateway.replaceAll(plan);
      final second = await gateway.replaceAll(plan);

      expect(backend.pending, {1, 2});
      expect(second.cancelled, 0);
      expect(backend.cancelled, isEmpty);
    });

    test('RS-10 one failure does not stop the rest', () async {
      final backend = _FakeBackend(failOn: {2});
      final gateway = BackendNotificationGateway(backend);

      final result = await gateway.replaceAll([_n(1), _n(2), _n(3)]);

      expect(result.scheduled, 2);
      expect(result.failed, 1);
      expect(backend.scheduled.map((s) => s.id), [1, 3]);
    });

    test('a failed id keeps what was pending for it', () async {
      final backend = _FakeBackend(pending: {2}, failOn: {2});
      final gateway = BackendNotificationGateway(backend);

      await gateway.replaceAll([_n(2)]);

      expect(backend.pending, {2});
      expect(backend.cancelled, isEmpty);
    });

    test('an empty plan cancels everything pending', () async {
      final backend = _FakeBackend(pending: {1, 2});

      final result = await BackendNotificationGateway(backend).replaceAll([]);

      expect(result, (scheduled: 0, failed: 0, cancelled: 2));
      expect(backend.pending, isEmpty);
    });

    test('RS-11 the exact alarm is used only when allowed', () async {
      final allowed = _FakeBackend();
      await BackendNotificationGateway(allowed).replaceAll([_n(1)]);
      final denied = _FakeBackend(exactAllowed: false);
      await BackendNotificationGateway(denied).replaceAll([_n(1)]);

      expect(allowed.scheduled.single.exact, isTrue);
      expect(denied.scheduled.single.exact, isFalse);
    });
  });

  group('channels', () {
    test('each sound and vibration choice has its own channel id', () {
      final ids = {
        for (final sound in ReminderSound.values)
          for (final vibrate in [true, false])
            reminderChannelId(sound, vibrate),
      };

      expect(ids, hasLength(ReminderSound.values.length * 2));
      expect(ids.every((id) => id.startsWith('evermoon_reminders_')), isTrue);
      expect(
        _n(1, sound: ReminderSound.softBell, vibrate: false).channelId,
        'evermoon_reminders_bell_quiet',
      );
    });
  });

  group('resolveDeviceLocation', () {
    setUpAll(tzdata.initializeTimeZones);

    test('a known zone name is used as it is', () {
      final location = resolveDeviceLocation(
        'Asia/Tokyo',
        const Duration(hours: 9),
      );

      expect(location.name, 'Asia/Tokyo');
    });

    test('the old name Android reports for Vietnam is not UTC (Pixel 8)', () {
      // Found on a real Pixel 8: "Asia/Saigon" is missing from the database,
      // and falling back to UTC made every reminder 7 hours late.
      final location = resolveDeviceLocation(
        'Asia/Saigon',
        const Duration(hours: 7),
      );

      expect(location.name, 'Asia/Ho_Chi_Minh');
      expect(
        zonedWallClock(DateTime(2026, 11, 13, 11, 25), location).toUtc(),
        DateTime.utc(2026, 11, 13, 4, 25),
      );
    });

    test('an unknown name falls back to the phone offset, never to UTC', () {
      final location = resolveDeviceLocation(
        'Mars/Olympus_Mons',
        const Duration(hours: 7),
      );

      expect(
        zonedWallClock(DateTime(2026, 11, 13, 7), location).toUtc(),
        DateTime.utc(2026, 11, 13),
      );
    });

    test('an empty name (unreadable zone) also uses the offset', () {
      final location = resolveDeviceLocation('', const Duration(hours: -5));

      expect(
        zonedWallClock(DateTime(2026, 11, 13, 7), location).toUtc(),
        DateTime.utc(2026, 11, 13, 12),
      );
    });
  });

  group('zonedWallClock', () {
    setUpAll(tzdata.initializeTimeZones);

    test(
      'RS-14 keeps the wall-clock time and changes the instant per zone',
      () {
        final wall = DateTime(2030, 6, 1, 7, 30);

        final hanoi = zonedWallClock(wall, tz.getLocation('Asia/Ho_Chi_Minh'));
        final newYork = zonedWallClock(
          wall,
          tz.getLocation('America/New_York'),
        );

        expect([hanoi.hour, hanoi.minute], [7, 30]);
        expect([newYork.hour, newYork.minute], [7, 30]);
        expect(hanoi.toUtc(), DateTime.utc(2030, 6, 1, 0, 30));
        expect(newYork.toUtc(), DateTime.utc(2030, 6, 1, 11, 30));
      },
    );

    test('a time inside a daylight-saving gap moves forward, not back', () {
      // 2030-03-10 02:30 does not exist in New York (clocks jump 02:00 to 03:00).
      final shifted = zonedWallClock(
        DateTime(2030, 3, 10, 2, 30),
        tz.getLocation('America/New_York'),
      );

      expect(shifted.day, 10);
      expect(shifted.hour, greaterThanOrEqualTo(3));
    });
  });
}

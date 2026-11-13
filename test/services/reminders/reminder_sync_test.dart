// Texts, sync service and triggers (plan 0006, N3; RS-7, RS-8, RS-9).
// The gateway is a hand-written fake; the calendar is the synthetic fake
// where lunar year Y is 12 months of 30 days from 1 January of Y.
import 'dart:async';

import 'package:ever_moon/generated/l10n.dart';
import 'package:ever_moon/models/anniversary.dart';
import 'package:ever_moon/models/anniversary_date.dart';
import 'package:ever_moon/models/app_settings.dart';
import 'package:ever_moon/services/lunar/anniversary_resolver.dart';
import 'package:ever_moon/services/notification_access_service.dart';
import 'package:ever_moon/services/reminders/notification_gateway.dart';
import 'package:ever_moon/services/reminders/planned_reminder.dart';
import 'package:ever_moon/services/reminders/reminder_planner.dart';
import 'package:ever_moon/services/reminders/reminder_sync_service.dart';
import 'package:ever_moon/services/reminders/reminder_sync_triggers.dart';
import 'package:ever_moon/services/reminders/reminder_texts.dart';
import 'package:ever_moon/services/lunar/lunar_calendar_service.dart';
import 'package:ever_moon/services/lunar/lunar_holidays.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../pages/anniversary_form/memory_anniversary_repository.dart';
import '../../pages/setting/setting_test.dart' show MemorySettingsStore;
import '../fake_notification_access.dart';
import '../lunar/fake_lunar_calendar_service.dart';

class _RecordingGateway implements NotificationGateway {
  final List<List<ReminderNotification>> calls = [];
  Completer<void>? hold;

  @override
  Future<ReplaceResult> replaceAll(List<ReminderNotification> reminders) async {
    calls.add(reminders);
    await hold?.future;
    return (scheduled: reminders.length, failed: 0, cancelled: 0);
  }
}

Anniversary _anniversary({
  String id = 'a',
  String name = 'Nguyễn Thị Mão',
  int day = 10,
  int daysBefore = 0,
}) => Anniversary(
  id: id,
  name: name,
  date: AnniversaryDate(lunarDay: day, lunarMonth: 1),
  remindDaysBefore: daysBefore,
  createdAt: DateTime.utc(2000),
  updatedAt: DateTime.utc(2000),
);

const _off = AppSettings(
  remindFirstDay: false,
  remindFullMoon: false,
  remindFestivals: false,
);

final _now = DateTime(2005, 1, 1, 6);

Future<S> _texts(String code) async {
  await initializeDateFormatting(code);
  return S.delegate.load(Locale(code));
}

void main() {
  final calendar = FakeLunarCalendarService();
  final planner = ReminderPlanner(
    resolver: AnniversaryResolver(calendar),
    calendar: calendar,
  );

  late _RecordingGateway gateway;
  late FakeNotificationAccess access;
  late MemorySettingsStore settings;
  late MemoryAnniversaryRepository repository;

  ReminderSyncService build() => ReminderSyncService(
    planner: planner,
    gateway: gateway,
    access: access,
    settings: settings,
    repository: repository,
    loadTexts: _texts,
    now: () => _now,
  );

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    gateway = _RecordingGateway();
    access = FakeNotificationAccess(current: NotificationAccess.granted);
    settings = MemorySettingsStore()..saved = _off;
    repository = MemoryAnniversaryRepository([_anniversary()]);
  });

  group('texts', () {
    PlannedReminder planned({int daysBefore = 0}) => PlannedReminder(
      id: 7,
      kind: ReminderKind.anniversary,
      fireAt: DateTime(2005, 1, 1, 7),
      eventDay: DateTime.utc(2005, 1, 10),
      lunar: const LunarDate(2005, 1, 10),
      daysBefore: daysBefore,
      anniversaryId: 'a',
      anniversaryName: 'Nguyễn Thị Mão',
    );

    test('anniversary title and body in Vietnamese', () async {
      final s = await _texts('vi');
      final n = buildReminderNotification(planned(), s, _off, locale: 'vi');

      expect(n.title, 'Hôm nay: Nguyễn Thị Mão');
      expect(n.body, contains('10 tháng 1 âm lịch'));
      expect(n.body, contains('10/01/2005'));
      expect(n.payload, '$reminderPayload:a');
    });

    test('title counts the days ahead, in English', () async {
      final s = await _texts('en');
      String title(int days) => buildReminderNotification(
        planned(daysBefore: days),
        s,
        _off,
        locale: 'en',
      ).title;

      expect(title(1), 'Tomorrow: Nguyễn Thị Mão');
      expect(title(3), 'In 3 days: Nguyễn Thị Mão');
    });

    test(
      'a system event uses the holiday name and has no anniversary id',
      () async {
        final s = await _texts('vi');
        final n = buildReminderNotification(
          PlannedReminder(
            id: 8,
            kind: ReminderKind.systemEvent,
            fireAt: DateTime(2005, 1, 15, 7),
            eventDay: DateTime.utc(2005, 1, 15),
            lunar: const LunarDate(2005, 1, 10),
            holiday: const FullMoonHoliday(1, false),
          ),
          s,
          _off,
          locale: 'vi',
        );

        expect(n.title, 'Rằm tháng 1');
        expect(n.payload, reminderPayload);
        expect(isReminderPayload(n.payload), isTrue);
        expect(isReminderPayload('{"fcm": true}'), isFalse);
        expect(isReminderPayload(null), isFalse);
      },
    );

    test('sound, vibration and channel labels follow Settings', () async {
      final s = await _texts('vi');
      final n = buildReminderNotification(
        planned(),
        s,
        _off.copyWith(sound: ReminderSound.silent, vibrate: false),
        locale: 'vi',
      );

      expect(n.sound, ReminderSound.silent);
      expect(n.vibrate, isFalse);
      expect(n.channelName, 'Nhắc nhở');
    });
  });

  group('sync', () {
    test('RS-7 syncing twice gives the same notifications', () async {
      final service = build();

      await service.syncReminders();
      await service.syncReminders();

      expect(gateway.calls, hasLength(2));
      expect(gateway.calls.first, isNotEmpty);
      expect(gateway.calls.first, gateway.calls.last);
    });

    test(
      'RS-8 without permission nothing is planned and nothing is asked',
      () async {
        access.current = NotificationAccess.denied;

        await build().syncReminders();

        expect(gateway.calls.single, isEmpty);
        expect(access.requests, 0);
      },
    );

    test('RS-8 granting the permission plans on the next sync', () async {
      access.current = NotificationAccess.blocked;
      final service = build();
      await service.syncReminders();

      access.current = NotificationAccess.granted;
      await service.syncReminders();

      expect(gateway.calls.first, isEmpty);
      expect(gateway.calls.last, isNotEmpty);
    });

    test(
      'RS-9 a changed anniversary, setting or language is re-planned',
      () async {
        final service = build();
        await service.syncReminders();
        repository.records['a'] = _anniversary(
          name: 'Trần Văn B',
          daysBefore: 3,
        );
        settings.saved = _off.copyWith(
          sound: ReminderSound.softBell,
          languageCode: 'en',
        );

        await service.syncReminders();

        final latest = gateway.calls.last.single;
        expect(latest.title, 'In 3 days: Trần Văn B');
        expect(latest.sound, ReminderSound.softBell);
        expect(gateway.calls.first.single.title, isNot(latest.title));
      },
    );

    test('a call during a sync is merged into one more pass', () async {
      gateway.hold = Completer<void>();
      final service = build();

      final first = service.syncReminders();
      await pumpEventQueue();
      final second = service.syncReminders();
      gateway.hold!.complete();
      await Future.wait([first, second]);

      expect(gateway.calls, hasLength(2));
    });
  });

  group('triggers', () {
    late StreamController<List<Anniversary>> anniversaries;
    late StreamController<AppSettings> changes;
    late ReminderSyncTriggers triggers;

    setUp(() {
      anniversaries = StreamController<List<Anniversary>>.broadcast();
      changes = StreamController<AppSettings>.broadcast();
      triggers = ReminderSyncTriggers(
        service: build(),
        anniversaries: anniversaries.stream,
        settingsChanges: changes.stream,
        debounce: const Duration(milliseconds: 20),
      )..start();
    });

    tearDown(() async {
      await triggers.dispose();
      await anniversaries.close();
      await changes.close();
    });

    Future<void> settle() =>
        Future<void>.delayed(const Duration(milliseconds: 120));

    test('RS-9 a changed anniversary list triggers a sync', () async {
      anniversaries.add([_anniversary()]);
      await settle();

      expect(gateway.calls, hasLength(1));
    });

    test('RS-9 a settings change triggers a sync', () async {
      changes.add(_off);
      await settle();

      expect(gateway.calls, hasLength(1));
    });

    test('changes close together are merged into one sync', () async {
      anniversaries.add([_anniversary()]);
      changes.add(_off);
      anniversaries.add([_anniversary()]);
      await settle();

      expect(gateway.calls, hasLength(1));
    });

    test('coming back to the front triggers a sync', () async {
      triggers.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await settle();

      expect(gateway.calls, hasLength(1));
    });

    test('going to the background does not', () async {
      triggers.didChangeAppLifecycleState(AppLifecycleState.paused);
      await settle();

      expect(gateway.calls, isEmpty);
    });
  });

  group('tap', () {
    test('a reminder tap opens the list; a push tap does not', () async {
      final taps = StreamController<String?>();
      var opened = 0;
      final subscription = openHomeOnReminderTap(taps.stream, () => opened++);

      taps
        ..add('$reminderPayload:a')
        ..add('some push payload')
        ..add(null);
      await pumpEventQueue();

      expect(opened, 1);
      await subscription.cancel();
      await taps.close();
    });
  });
}

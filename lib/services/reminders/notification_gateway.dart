import 'package:equatable/equatable.dart';
import 'package:ever_moon/models/app_settings.dart';
import 'package:ever_moon/utils/app_logger.dart';

/// One notification ready for the operating system: the planned time plus
/// the text, sound and channel labels, already localized.
class ReminderNotification extends Equatable {
  /// Creates a notification to schedule.
  const ReminderNotification({
    required this.id,
    required this.fireAt,
    required this.title,
    required this.body,
    required this.sound,
    required this.vibrate,
    required this.channelName,
    required this.channelDescription,
    this.payload,
  });

  /// Stable id from the planner; scheduling an id again replaces it.
  final int id;

  /// Wall-clock time to fire, in the device's local time zone.
  final DateTime fireAt;

  /// Notification title.
  final String title;

  /// Notification body.
  final String body;

  /// Sound choice from Settings.
  final ReminderSound sound;

  /// Whether the notification vibrates.
  final bool vibrate;

  /// Android channel name shown in the phone's settings.
  final String channelName;

  /// Android channel description shown in the phone's settings.
  final String channelDescription;

  /// Passed back when the user taps the notification (the anniversary id, or
  /// `null` for a system event).
  final String? payload;

  /// Android channel for this sound and vibration choice. Android fixes both
  /// per channel, so each combination needs its own (D-R6).
  String get channelId => reminderChannelId(sound, vibrate);

  @override
  List<Object?> get props => [
    id,
    fireAt,
    title,
    body,
    sound,
    vibrate,
    channelName,
    channelDescription,
    payload,
  ];
}

/// Android channel id for a sound and vibration choice (D-R6).
String reminderChannelId(ReminderSound sound, bool vibrate) {
  final soundPart = switch (sound) {
    ReminderSound.deviceDefault => 'default',
    ReminderSound.softBell => 'bell',
    ReminderSound.silent => 'silent',
  };
  return 'evermoon_reminders_${soundPart}_${vibrate ? 'vibrate' : 'quiet'}';
}

/// What [NotificationGateway.replaceAll] did.
typedef ReplaceResult = ({int scheduled, int failed, int cancelled});

/// Keeps the operating system's pending notifications equal to a plan.
abstract interface class NotificationGateway {
  /// Makes the pending set equal to [reminders]: schedules each one (an
  /// existing id is replaced in place), then cancels pending ids that are no
  /// longer planned. One failure is logged and does not stop the rest; a
  /// failed id keeps whatever was pending for it.
  Future<ReplaceResult> replaceAll(List<ReminderNotification> reminders);
}

/// The few operations the gateway needs from the platform plugin.
///
/// A thin seam so the replace logic runs in unit tests with a fake and the
/// real plugin is only touched in one place.
abstract interface class NotificationBackend {
  /// Refreshes the device time zone and creates the channels [reminders]
  /// need. Called before every replace, so a time zone change is picked up.
  Future<void> prepare(List<ReminderNotification> reminders);

  /// Whether exact alarms are allowed (Android 12+ permission, D-R5).
  Future<bool> canScheduleExact();

  /// Ids of the notifications currently pending.
  Future<Set<int>> pendingIds();

  /// Schedules [reminder]; [exact] picks the exact or the inexact alarm.
  Future<void> schedule(ReminderNotification reminder, {required bool exact});

  /// Cancels the pending notification [id].
  Future<void> cancel(int id);
}

/// [NotificationGateway] over a [NotificationBackend].
class BackendNotificationGateway implements NotificationGateway {
  /// Creates the gateway over [backend].
  const BackendNotificationGateway(this._backend);

  final NotificationBackend _backend;

  @override
  Future<ReplaceResult> replaceAll(List<ReminderNotification> reminders) async {
    await _backend.prepare(reminders);
    final exact = await _backend.canScheduleExact();
    final pending = await _backend.pendingIds();
    final failed = <int>{};
    for (final reminder in reminders) {
      if (!await _schedule(reminder, exact: exact)) failed.add(reminder.id);
    }
    final planned = {for (final r in reminders) r.id};
    final cancelled = await _cancelStale(pending.difference(planned));
    return (
      scheduled: reminders.length - failed.length,
      failed: failed.length,
      cancelled: cancelled,
    );
  }

  Future<bool> _schedule(
    ReminderNotification reminder, {
    required bool exact,
  }) async {
    try {
      await _backend.schedule(reminder, exact: exact);
      return true;
    } on Exception catch (e, s) {
      err('Scheduling reminder ${reminder.id} failed', e, s);
      return false;
    }
  }

  Future<int> _cancelStale(Set<int> ids) async {
    var cancelled = 0;
    for (final id in ids) {
      try {
        await _backend.cancel(id);
        cancelled++;
      } on Exception catch (e, s) {
        err('Cancelling reminder $id failed', e, s);
      }
    }
    return cancelled;
  }
}

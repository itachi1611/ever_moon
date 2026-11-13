import 'dart:async';

import 'package:ever_moon/models/anniversary.dart';
import 'package:ever_moon/models/app_settings.dart';
import 'package:ever_moon/services/reminders/reminder_sync_service.dart';
import 'package:ever_moon/services/reminders/reminder_texts.dart';
import 'package:ever_moon/utils/app_logger.dart' as logger;
import 'package:flutter/widgets.dart';

/// Runs [ReminderSyncService.syncReminders] whenever its inputs may have
/// changed (plan 0006, N3; RS-9): the anniversaries, the Settings, and the
/// app coming back to the front.
///
/// Coming back to the front also covers a day that has passed, a changed
/// time zone and a notification permission granted from the system dialog or
/// the phone's settings. Changes arriving close together are merged into one
/// sync.
class ReminderSyncTriggers with WidgetsBindingObserver {
  /// Creates the triggers over [service] and the two change streams.
  ReminderSyncTriggers({
    required ReminderSyncService service,
    required Stream<List<Anniversary>> anniversaries,
    required Stream<AppSettings> settingsChanges,
    Duration debounce = const Duration(milliseconds: 400),
  }) : _service = service,
       _anniversaries = anniversaries,
       _settingsChanges = settingsChanges,
       _debounce = debounce;

  final ReminderSyncService _service;
  final Stream<List<Anniversary>> _anniversaries;
  final Stream<AppSettings> _settingsChanges;
  final Duration _debounce;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  Timer? _timer;

  /// Starts listening. The first anniversaries event is the start-up sync.
  void start() {
    WidgetsBinding.instance.addObserver(this);
    _subscriptions.addAll([
      _anniversaries.listen((_) => _request(), onError: _onStreamError),
      _settingsChanges.listen((_) => _request(), onError: _onStreamError),
    ]);
  }

  /// Stops listening and drops a pending sync.
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _request();
  }

  void _request() {
    _timer?.cancel();
    _timer = Timer(_debounce, () => unawaited(_run()));
  }

  Future<void> _run() async {
    try {
      await _service.syncReminders();
    } catch (error, stackTrace) {
      logger.err('Reminder sync failed', error, stackTrace);
    }
  }

  void _onStreamError(Object error, StackTrace stackTrace) =>
      logger.err('Reminder trigger stream failed', error, stackTrace);
}

/// Calls [openHome] when the user taps one of our reminders (D-R4: a tap
/// opens the list). Push-notification taps are ignored.
StreamSubscription<String?> openHomeOnReminderTap(
  Stream<String?> taps,
  VoidCallback openHome,
) => taps.listen((payload) {
  if (isReminderPayload(payload)) openHome();
});

import 'package:ever_moon/generated/l10n.dart';
import 'package:ever_moon/repositories/anniversary_repository.dart';
import 'package:ever_moon/services/notification_access_service.dart';
import 'package:ever_moon/services/reminders/notification_gateway.dart';
import 'package:ever_moon/services/reminders/reminder_planner.dart';
import 'package:ever_moon/services/reminders/reminder_texts.dart';
import 'package:ever_moon/storage/settings_store.dart';
import 'package:ever_moon/utils/app_logger.dart' as logger;
import 'package:flutter/widgets.dart' show Locale;
import 'package:intl/date_symbol_data_local.dart';

/// Loads the strings for a language code without a `BuildContext`.
typedef TextLoader = Future<S> Function(String languageCode);

/// Loads [S] for [languageCode] and the date symbols the Gregorian date in
/// a notification body needs, which exist only once the UI has built.
Future<S> loadAppTexts(String languageCode) async {
  await initializeDateFormatting(languageCode);
  return S.delegate.load(Locale(languageCode));
}

/// Makes the operating system's pending notifications match the database and
/// the settings (plan 0006, D-R1). The database is the only source of truth;
/// the pending set is a disposable copy rebuilt here.
class ReminderSyncService {
  /// Creates the service. [now] and [loadTexts] are injected for tests.
  ReminderSyncService({
    required ReminderPlanner planner,
    required NotificationGateway gateway,
    required NotificationAccessService access,
    required SettingsStore settings,
    required AnniversaryRepository repository,
    TextLoader? loadTexts,
    DateTime Function()? now,
  }) : _planner = planner,
       _gateway = gateway,
       _access = access,
       _settings = settings,
       _repository = repository,
       _loadTexts = loadTexts ?? loadAppTexts,
       _now = now ?? DateTime.now;

  final ReminderPlanner _planner;
  final NotificationGateway _gateway;
  final NotificationAccessService _access;
  final SettingsStore _settings;
  final AnniversaryRepository _repository;
  final TextLoader _loadTexts;
  final DateTime Function() _now;

  Future<void>? _current;
  bool _again = false;

  /// Rebuilds the pending notifications from the current data.
  ///
  /// Idempotent: running it twice in a row leaves the same set (RS-7). Calls
  /// that arrive while a sync runs share it and trigger one more pass, so the
  /// last change always wins and two passes never overlap.
  Future<void> syncReminders() {
    final running = _current;
    if (running != null) {
      _again = true;
      return running;
    }
    return _current = _drain();
  }

  Future<void> _drain() async {
    try {
      do {
        _again = false;
        await _syncOnce();
      } while (_again);
    } finally {
      _current = null;
    }
  }

  Future<void> _syncOnce() async {
    // Without permission nothing is planned and nothing is asked (RS-8);
    // an empty plan also clears what an earlier grant left pending.
    if (await _access.status() != NotificationAccess.granted) {
      await _gateway.replaceAll(const []);
      return;
    }
    final settings = _settings.read();
    final plan = _planner.plan(
      anniversaries: await _repository.watchAll().first,
      settings: settings,
      now: _now(),
    );
    final s = await _loadTexts(settings.languageCode);
    final result = await _gateway.replaceAll([
      for (final r in plan)
        buildReminderNotification(
          r,
          s,
          settings,
          locale: settings.languageCode,
        ),
    ]);
    logger.info('Reminders synced: $result');
  }
}

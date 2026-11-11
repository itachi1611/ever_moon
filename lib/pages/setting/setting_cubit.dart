import 'package:ever_moon/models/app_settings.dart';
import 'package:ever_moon/services/notification_access_service.dart';
import 'package:ever_moon/storage/settings_store.dart';
import 'package:ever_moon/utils/app_logger.dart' as logger;
import 'package:flutter_bloc/flutter_bloc.dart';

import 'setting_state.dart';

/// Notification preferences, the permission row and About (plan 0005, U6;
/// D14, D18, UI-16). Theme and language go through `AppCubit`.
class SettingCubit extends Cubit<SettingState> {
  /// Creates the Cubit; [version] reads the app version.
  SettingCubit({
    required SettingsStore store,
    required NotificationAccessService access,
    required Future<String> Function() version,
  }) : _store = store,
       _access = access,
       _version = version,
       super(const SettingLoading());

  final SettingsStore _store;
  final NotificationAccessService _access;
  final Future<String> Function() _version;

  /// Reads the stored settings, the permission state and the version.
  Future<void> load() async {
    final access = await _readAccess();
    final version = await _readVersion();
    if (isClosed) return;
    emit(
      SettingLoaded(settings: _store.read(), access: access, version: version),
    );
  }

  /// Re-reads the permission; the page calls it on resume, because the
  /// user may have changed it in the system settings.
  Future<void> refreshAccess() async {
    if (state is! SettingLoaded) return;
    final read = await _readAccess();
    final current = state;
    if (isClosed || current is! SettingLoaded) return;
    // Android's status cannot tell "blocked" from "denied"; only a request
    // can, so a known "blocked" is kept until the user allows.
    final blocked =
        current.access == NotificationAccess.blocked &&
        read == NotificationAccess.denied;
    emit(current.copyWith(access: blocked ? current.access : read));
  }

  /// The notification row: asks when Android still shows the dialog,
  /// otherwise opens the system settings (to turn on, or off). A request
  /// that turns out blocked opens the settings at once (D18, UI-16).
  Future<void> openNotificationAccess() async {
    final before = state;
    if (before is! SettingLoaded) return;
    try {
      final access = before.access == NotificationAccess.denied
          ? await _access.request()
          : before.access;
      _setAccess(access);
      // Blocked: only the settings can turn it on. Already granted: the
      // settings are where it is turned off.
      if (access == NotificationAccess.blocked ||
          before.access == NotificationAccess.granted) {
        await _access.openSettings();
      }
    } catch (error, stackTrace) {
      logger.err('Notification permission flow failed', error, stackTrace);
    }
  }

  void _setAccess(NotificationAccess access) {
    final current = state;
    if (!isClosed && current is SettingLoaded) {
      emit(current.copyWith(access: access));
    }
  }

  /// Sets the reminder sound.
  Future<void> setSound(ReminderSound sound) =>
      _change((s) => s.copyWith(sound: sound));

  /// Turns vibration on or off.
  Future<void> setVibrate(bool on) => _change((s) => s.copyWith(vibrate: on));

  /// Turns mùng 1 reminders on or off.
  Future<void> setRemindFirstDay(bool on) =>
      _change((s) => s.copyWith(remindFirstDay: on));

  /// Turns rằm reminders on or off.
  Future<void> setRemindFullMoon(bool on) =>
      _change((s) => s.copyWith(remindFullMoon: on));

  /// Turns Tết and festival reminders on or off.
  Future<void> setRemindFestivals(bool on) =>
      _change((s) => s.copyWith(remindFestivals: on));

  /// Shows the change at once, then stores it.
  Future<void> _change(AppSettingsEdit edit) async {
    final current = state;
    if (current is! SettingLoaded) return;
    emit(current.copyWith(settings: edit(current.settings)));
    try {
      await _store.update(edit);
    } catch (error, stackTrace) {
      logger.err('Setting not stored', error, stackTrace);
    }
  }

  Future<NotificationAccess> _readAccess() async {
    try {
      return await _access.status();
    } catch (error, stackTrace) {
      logger.err('Notification status could not be read', error, stackTrace);
      return NotificationAccess.denied;
    }
  }

  Future<String> _readVersion() async {
    try {
      return await _version();
    } catch (error, stackTrace) {
      logger.err('App version could not be read', error, stackTrace);
      return '';
    }
  }
}

import 'package:ever_moon/common/app_enums.dart' show AppPreferenceKey;
import 'package:ever_moon/models/app_settings.dart';
import 'package:flutter/material.dart' show ThemeMode;

import 'app_preference.dart';

/// Global getter for the settings store.
SettingsStore get settingsStore => PreferenceSettingsStore.instance;

/// Reads and writes [AppSettings] (plan 0005, U6; UI-12: they survive a
/// restart).
abstract interface class SettingsStore {
  /// The stored settings; defaults for anything never stored.
  AppSettings read();

  /// Stores [settings].
  Future<void> write(AppSettings settings);
}

/// A change to some fields of [AppSettings].
typedef AppSettingsEdit = AppSettings Function(AppSettings settings);

/// Read-modify-write helper for one change.
extension SettingsStoreUpdate on SettingsStore {
  /// Stores the current settings with [edit] applied, and returns them.
  Future<AppSettings> update(AppSettingsEdit edit) async {
    final next = edit(read());
    await write(next);
    return next;
  }
}

/// [SettingsStore] on [AppPreference] (SharedPreferences), one key per
/// field. Unknown stored values fall back to the default.
class PreferenceSettingsStore implements SettingsStore {
  /// Creates the store over [preference].
  PreferenceSettingsStore(this._preference);

  /// The app-wide store.
  static final PreferenceSettingsStore instance = PreferenceSettingsStore(
    AppPreference.instance,
  );

  final AppPreference _preference;

  static const _defaults = AppSettings();

  @override
  AppSettings read() {
    const d = _defaults;
    final p = _preference;
    return AppSettings(
      themeMode: _named(ThemeMode.values, _Key.kThemeMode) ?? d.themeMode,
      languageCode: _language() ?? d.languageCode,
      sound: _named(ReminderSound.values, _Key.kReminderSound) ?? d.sound,
      vibrate: p.getBool(_Key.kVibrate) ?? d.vibrate,
      remindFirstDay: p.getBool(_Key.kRemindFirstDay) ?? d.remindFirstDay,
      remindFullMoon: p.getBool(_Key.kRemindFullMoon) ?? d.remindFullMoon,
      remindFestivals: p.getBool(_Key.kRemindFestivals) ?? d.remindFestivals,
    );
  }

  /// Writes only the fields that changed, and starts every write before
  /// awaiting any: SharedPreferences updates its cache synchronously, so
  /// two quick updates cannot overwrite each other's field.
  @override
  Future<void> write(AppSettings settings) async {
    final old = read();
    final p = _preference;
    await Future.wait([
      if (settings.themeMode != old.themeMode)
        p.setString(_Key.kThemeMode, settings.themeMode.name),
      if (settings.languageCode != old.languageCode)
        p.setString(_Key.kLanguage, settings.languageCode),
      if (settings.sound != old.sound)
        p.setString(_Key.kReminderSound, settings.sound.name),
      ..._flags(settings, old),
    ]);
  }

  Iterable<Future<void>> _flags(AppSettings next, AppSettings old) => [
    if (next.vibrate != old.vibrate)
      _preference.setBool(_Key.kVibrate, next.vibrate),
    if (next.remindFirstDay != old.remindFirstDay)
      _preference.setBool(_Key.kRemindFirstDay, next.remindFirstDay),
    if (next.remindFullMoon != old.remindFullMoon)
      _preference.setBool(_Key.kRemindFullMoon, next.remindFullMoon),
    if (next.remindFestivals != old.remindFestivals)
      _preference.setBool(_Key.kRemindFestivals, next.remindFestivals),
  ];

  /// Only the two supported languages are taken.
  String? _language() {
    final code = _preference.getString(AppPreferenceKey.kLanguage);
    return const {'vi', 'en'}.contains(code) ? code : null;
  }

  T? _named<T extends Enum>(List<T> values, AppPreferenceKey key) {
    final name = _preference.getString(key);
    return values.where((value) => value.name == name).firstOrNull;
  }
}

typedef _Key = AppPreferenceKey;

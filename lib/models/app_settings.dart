import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Sound a reminder plays (plan 0005, U6). A4 maps it to a channel.
enum ReminderSound {
  /// The phone's notification sound.
  deviceDefault,

  /// A soft bell shipped with the app.
  softBell,

  /// No sound.
  silent,
}

/// Preferences the user sets in Settings, stored on the device.
///
/// Defaults follow the design: Vietnamese, system theme, device sound,
/// vibrate on, rằm and festivals on, mùng 1 off.
class AppSettings extends Equatable {
  /// Creates the settings; the defaults are those of a new install.
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.languageCode = 'vi',
    this.sound = ReminderSound.deviceDefault,
    this.vibrate = true,
    this.remindFirstDay = false,
    this.remindFullMoon = true,
    this.remindFestivals = true,
  });

  /// System, light or dark.
  final ThemeMode themeMode;

  /// `vi` or `en`.
  final String languageCode;

  /// Reminder sound.
  final ReminderSound sound;

  /// Whether reminders vibrate.
  final bool vibrate;

  /// Remind on mùng 1 (stored here; A4 schedules it).
  final bool remindFirstDay;

  /// Remind on rằm.
  final bool remindFullMoon;

  /// Remind on Tết and traditional festivals.
  final bool remindFestivals;

  /// The app locale.
  Locale get locale => Locale(languageCode);

  /// Copy with fields replaced.
  AppSettings copyWith({
    ThemeMode? themeMode,
    String? languageCode,
    ReminderSound? sound,
    bool? vibrate,
    bool? remindFirstDay,
    bool? remindFullMoon,
    bool? remindFestivals,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    languageCode: languageCode ?? this.languageCode,
    sound: sound ?? this.sound,
    vibrate: vibrate ?? this.vibrate,
    remindFirstDay: remindFirstDay ?? this.remindFirstDay,
    remindFullMoon: remindFullMoon ?? this.remindFullMoon,
    remindFestivals: remindFestivals ?? this.remindFestivals,
  );

  @override
  List<Object?> get props => [
    themeMode,
    languageCode,
    sound,
    vibrate,
    remindFirstDay,
    remindFullMoon,
    remindFestivals,
  ];
}

import 'package:equatable/equatable.dart';
import 'package:ever_moon/models/app_settings.dart';
import 'package:ever_moon/services/notification_access_service.dart';

/// State of the Settings page (plan 0005, U6).
sealed class SettingState extends Equatable {
  const SettingState();

  @override
  List<Object?> get props => [];
}

/// Reading the permission state and the app version.
final class SettingLoading extends SettingState {
  /// Creates the loading state.
  const SettingLoading();
}

/// Everything the page shows besides theme and language (those live in
/// `AppCubit`).
final class SettingLoaded extends SettingState {
  /// Creates the loaded state.
  const SettingLoaded({
    required this.settings,
    required this.access,
    required this.version,
    this.exactAlarm = true,
  });

  /// Stored preferences.
  final AppSettings settings;

  /// Whether notifications are allowed (D18).
  final NotificationAccess access;

  /// App version, for the About section.
  final String version;

  /// Whether reminders may be delivered at the exact minute (plan 0006).
  final bool exactAlarm;

  /// Copy with fields replaced.
  SettingLoaded copyWith({
    AppSettings? settings,
    NotificationAccess? access,
    bool? exactAlarm,
  }) => SettingLoaded(
    settings: settings ?? this.settings,
    access: access ?? this.access,
    version: version,
    exactAlarm: exactAlarm ?? this.exactAlarm,
  );

  @override
  List<Object?> get props => [settings, access, version, exactAlarm];
}

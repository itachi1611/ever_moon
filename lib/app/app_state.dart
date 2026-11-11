import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Global UI state held by [AppCubit]: theme mode and locale.
class AppState extends Equatable {
  /// Creates the state; Vietnamese is the primary language.
  const AppState({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('vi'),
  });

  /// Active theme mode.
  final ThemeMode themeMode;

  /// Active locale.
  final Locale locale;

  /// Copy with the given fields replaced.
  AppState copyWith({ThemeMode? themeMode, Locale? locale}) => AppState(
    themeMode: themeMode ?? this.themeMode,
    locale: locale ?? this.locale,
  );

  @override
  List<Object?> get props => [themeMode, locale];
}

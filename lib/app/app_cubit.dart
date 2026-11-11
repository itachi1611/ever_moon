import 'package:ever_moon/storage/settings_store.dart';
import 'package:ever_moon/utils/app_logger.dart' as logger;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_state.dart';

/// Global cubit for theme mode and locale (plan 0005, U6; UI-12).
///
/// Starts from the stored settings and stores every change, so the choice
/// applies at once and survives a restart.
class AppCubit extends Cubit<AppState> {
  /// Creates the cubit from [store].
  AppCubit(this._store) : super(_initial(_store));

  final SettingsStore _store;

  static AppState _initial(SettingsStore store) {
    final settings = store.read();
    return AppState(themeMode: settings.themeMode, locale: settings.locale);
  }

  /// Switches the theme mode (system / light / dark) and stores it.
  Future<void> setThemeMode(ThemeMode mode) async {
    emit(state.copyWith(themeMode: mode));
    await _save((s) => s.copyWith(themeMode: mode));
  }

  /// Switches the language and stores it.
  Future<void> setLocale(Locale locale) async {
    emit(state.copyWith(locale: locale));
    await _save((s) => s.copyWith(languageCode: locale.languageCode));
  }

  Future<void> _save(AppSettingsEdit edit) async {
    try {
      await _store.update(edit);
    } catch (error, stackTrace) {
      // The choice still applies now; it is lost only at the next start.
      logger.err('App settings not stored', error, stackTrace);
    }
  }
}

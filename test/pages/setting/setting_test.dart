// Plan 0005, U6: UI-12 (language and theme apply at once and survive a
// restart), UI-16 (notification row, D18) and the stored preferences.
import 'package:ever_moon/app/app_cubit.dart';
import 'package:ever_moon/app/app_state.dart';
import 'package:ever_moon/common/app_enums.dart' show AppPreferenceKey;
import 'package:ever_moon/common/app_themes.dart';
import 'package:ever_moon/generated/l10n.dart';
import 'package:ever_moon/models/app_settings.dart';
import 'package:ever_moon/pages/setting/setting_page.dart';
import 'package:ever_moon/services/notification_access_service.dart';
import 'package:ever_moon/storage/app_preference.dart';
import 'package:ever_moon/storage/settings_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/fake_notification_access.dart';

/// Settings kept in memory.
class MemorySettingsStore implements SettingsStore {
  AppSettings saved = const AppSettings();

  @override
  AppSettings read() => saved;

  @override
  Future<void> write(AppSettings settings) async => saved = settings;
}

void main() {
  late MemorySettingsStore store;
  late FakeNotificationAccess access;

  setUp(() {
    store = MemorySettingsStore();
    access = FakeNotificationAccess();
  });

  Future<void> pumpSettings(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => AppCubit(store),
        child: BlocBuilder<AppCubit, AppState>(
          builder: (context, app) => MaterialApp(
            theme: const M3Theme().light,
            darkTheme: const M3Theme().dark,
            themeMode: app.themeMode,
            locale: app.locale,
            supportedLocales: const [Locale('en'), Locale('vi')],
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: SettingPage(
              store: store,
              access: access,
              version: () async => '1.2.3',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('UI-12 English applies at once and is stored', (tester) async {
    await pumpSettings(tester);
    expect(find.text('Cài đặt'), findsOneWidget);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(store.saved.languageCode, 'en');
    expect(AppCubit(store).state.locale, const Locale('en'));
  });

  testWidgets('UI-12 the dark theme applies at once and is stored', (
    tester,
  ) async {
    await pumpSettings(tester);
    await tester.tap(find.text('Tối'));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(SettingPage));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(AppCubit(store).state.themeMode, ThemeMode.dark);
  });

  testWidgets('UI-16 the row asks when Android still can', (tester) async {
    await pumpSettings(tester);
    expect(find.text('Đang tắt · chạm để bật'), findsOneWidget);
    await tester.tap(find.text('Cho phép thông báo'));
    await tester.pumpAndSettle();
    expect(access.requests, 1);
    expect(find.text('Đang bật'), findsOneWidget);
  });

  testWidgets('UI-16 a blocked permission opens the system settings', (
    tester,
  ) async {
    access.current = NotificationAccess.blocked;
    await pumpSettings(tester);
    expect(find.text('Đang tắt · mở cài đặt máy để bật'), findsOneWidget);
    await tester.tap(find.text('Cho phép thông báo'));
    await tester.pumpAndSettle();
    expect(access.requests, 0);
    expect(access.settingsOpened, 1);
  });

  testWidgets('UI-16 a request that turns out blocked opens the settings, '
      'and a resume does not forget it', (tester) async {
    access.afterRequest = NotificationAccess.blocked;
    await pumpSettings(tester);
    await tester.tap(find.text('Cho phép thông báo'));
    await tester.pumpAndSettle();
    expect(access.requests, 1);
    expect(access.settingsOpened, 1);
    // Android's status reads "denied" again after the dialog closes.
    access.current = NotificationAccess.denied;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Đang tắt · mở cài đặt máy để bật'), findsOneWidget);
  });

  testWidgets('system-event switches, sound and version', (tester) async {
    await pumpSettings(tester);
    expect(find.text('1.2.3'), findsOneWidget);
    await tester.tap(find.text('Mùng 1 hằng tháng'));
    await tester.pumpAndSettle();
    expect(store.saved.remindFirstDay, isTrue);
    await tester.tap(find.text('Âm thanh'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chuông nhẹ'));
    await tester.pumpAndSettle();
    expect(store.saved.sound, ReminderSound.softBell);
    expect(find.text('Chuông nhẹ'), findsOneWidget);
  });

  test('the preference store round-trips and ignores bad values', () async {
    SharedPreferences.setMockInitialValues({
      AppPreferenceKey.kLanguage.key: 'fr',
      AppPreferenceKey.kThemeMode.key: 'neon',
    });
    await AppPreference.init();
    final prefs = PreferenceSettingsStore(AppPreference.instance);
    expect(prefs.read(), const AppSettings());
    const changed = AppSettings(
      themeMode: ThemeMode.light,
      languageCode: 'en',
      sound: ReminderSound.silent,
      vibrate: false,
      remindFirstDay: true,
      remindFullMoon: false,
      remindFestivals: false,
    );
    await prefs.write(changed);
    expect(prefs.read(), changed);
  });

  test('two quick updates both survive', () async {
    SharedPreferences.setMockInitialValues({});
    await AppPreference.init();
    final prefs = PreferenceSettingsStore(AppPreference.instance);
    await Future.wait([
      prefs.update((s) => s.copyWith(vibrate: false)),
      prefs.update((s) => s.copyWith(sound: ReminderSound.silent)),
    ]);
    expect(prefs.read().vibrate, isFalse);
    expect(prefs.read().sound, ReminderSound.silent);
  });
}

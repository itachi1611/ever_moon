// Plan 0005, U7: UI-15 (intro once; Bỏ qua and Bắt đầu lead to the
// notification screen; Cho phép asks, Để sau does not) and D18 (no
// permission request at start-up).
import 'package:ever_moon/common/app_themes.dart';
import 'package:ever_moon/generated/l10n.dart';
import 'package:ever_moon/pages/onboarding/onboarding_page.dart';
import 'package:ever_moon/pages/splash/splash_cubit.dart';
import 'package:ever_moon/pages/splash/splash_state.dart';
import 'package:ever_moon/services/notification_access_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../services/fake_notification_access.dart';

void main() {
  late FakeNotificationAccess access;
  late bool completed;
  late int done;
  late int tokenRefreshes;

  setUp(() {
    access = FakeNotificationAccess();
    completed = false;
    done = 0;
    tokenRefreshes = 0;
  });

  Future<void> pumpOnboarding(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: const M3Theme().light,
        locale: const Locale('vi'),
        supportedLocales: const [Locale('en'), Locale('vi')],
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: OnboardingPage(
          onDone: () => done++,
          onNotificationsAllowed: () async => tokenRefreshes++,
          access: access,
          markComplete: () async => completed = true,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('UI-15 Tiếp tục walks the pages, Bắt đầu opens the notify '
      'screen, Cho phép shows the system dialog', (tester) async {
    await pumpOnboarding(tester);
    expect(find.text('Ngày giỗ theo âm lịch'), findsOneWidget);
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    expect(find.text('Nhắc đúng lúc'), findsOneWidget);
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bắt đầu'));
    await tester.pumpAndSettle();
    expect(find.text('Bật thông báo'), findsOneWidget);
    expect(access.requests, 0);
    await tester.tap(find.text('Cho phép'));
    await tester.pumpAndSettle();
    expect(access.requests, 1);
    expect(tokenRefreshes, 1);
    expect(completed, isTrue);
    expect(done, 1);
  });

  testWidgets('UI-15 Bỏ qua then Để sau finishes without the dialog', (
    tester,
  ) async {
    await pumpOnboarding(tester);
    await tester.tap(find.text('Bỏ qua'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Để sau'));
    await tester.pumpAndSettle();
    expect(access.requests, 0);
    expect(tokenRefreshes, 0);
    expect(completed, isTrue);
    expect(done, 1);
  });

  testWidgets('a swipe moves the page and its dots', (tester) async {
    await pumpOnboarding(tester);
    await tester.fling(find.byType(PageView), const Offset(-600, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Nhắc đúng lúc'), findsOneWidget);
    expect(find.bySemanticsLabel('Trang 2 trên 3'), findsOneWidget);
  });

  group('splash (UI-15, D18)', () {
    SplashCubit splash({required bool completedIntro}) => SplashCubit(
      hasCompletedIntro: () => completedIntro,
      access: access,
      onNotificationsAllowed: () async => tokenRefreshes++,
      minimumDisplay: Duration.zero,
    );

    test('the first launch goes to the intro and never asks', () async {
      final cubit = splash(completedIntro: false);
      await cubit.start();
      expect(cubit.state, const SplashReady(firstRun: true));
      expect(access.requests, 0);
      await cubit.close();
    });

    test('later launches go to the list and never ask', () async {
      final cubit = splash(completedIntro: true);
      await cubit.start();
      expect(cubit.state, const SplashReady(firstRun: false));
      expect(access.requests, 0);
      expect(tokenRefreshes, 0);
      await cubit.close();
    });

    test('a failing token refresh does not break the start', () async {
      access.current = NotificationAccess.granted;
      final cubit = SplashCubit(
        hasCompletedIntro: () => true,
        access: access,
        onNotificationsAllowed: () async => throw StateError('offline'),
        minimumDisplay: Duration.zero,
      );
      await cubit.start();
      await pumpEventQueue();
      expect(cubit.state, const SplashReady(firstRun: false));
      await cubit.close();
    });

    test('with notifications allowed, the token refreshes silently', () async {
      access.current = NotificationAccess.granted;
      final cubit = splash(completedIntro: true);
      await cubit.start();
      expect(tokenRefreshes, 1);
      expect(access.requests, 0);
      await cubit.close();
    });
  });
}

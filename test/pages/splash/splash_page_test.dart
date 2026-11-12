// Plan 0005, U7 (UI-15): the splash really leaves for the intro or the list.
// Regression: on a first launch the decision was emitted before the page
// listened for it, and the app stayed on the splash.
import 'package:ever_moon/common/app_themes.dart';
import 'package:ever_moon/generated/l10n.dart';
import 'package:ever_moon/pages/splash/splash_cubit.dart';
import 'package:ever_moon/pages/splash/splash_page.dart';
import 'package:ever_moon/routing/routers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../services/fake_notification_access.dart';

void main() {
  // The minimum display time is a plain timer: pumpAndSettle does not wait
  // for it, so the clock is advanced by hand.
  Future<void> letSplashEnd(WidgetTester tester) async {
    await tester.pump(SplashCubit.defaultMinimumDisplay);
    await tester.pumpAndSettle();
  }

  Future<void> pumpSplash(
    WidgetTester tester, {
    required bool completedIntro,
    bool settle = true,
  }) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: Routers.root.routerPath,
          builder: (_, _) => SplashPage(
            hasCompletedIntro: () => completedIntro,
            access: FakeNotificationAccess(),
          ),
        ),
        GoRoute(
          path: Routers.onboarding.routerPath,
          builder: (_, _) => const Text('intro'),
        ),
        GoRoute(
          path: Routers.home.routerPath,
          builder: (_, _) => const Text('list'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: const M3Theme().light,
        locale: const Locale('vi'),
        supportedLocales: const [Locale('en'), Locale('vi')],
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    );
    if (settle) await letSplashEnd(tester);
  }

  testWidgets('UI-15 the mark stays up before the intro opens', (tester) async {
    await pumpSplash(tester, completedIntro: false, settle: false);
    await tester.pump(SplashCubit.defaultMinimumDisplay * 0.5);
    expect(find.text('intro'), findsNothing);
    await letSplashEnd(tester);
    expect(find.text('intro'), findsOneWidget);
  });

  testWidgets('UI-15 the first launch opens the intro', (tester) async {
    await pumpSplash(tester, completedIntro: false);
    expect(find.text('intro'), findsOneWidget);
  });

  testWidgets('UI-15 later launches open the list', (tester) async {
    await pumpSplash(tester, completedIntro: true);
    expect(find.text('list'), findsOneWidget);
  });
}

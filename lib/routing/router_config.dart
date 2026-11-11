import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:ever_moon/pages/widgets/bottom_sheet_widget.dart';
import 'package:go_router/go_router.dart';

import '../pages/pages.dart';
import 'routers.dart';

/// Root [NavigatorState] key shared between [AppRouter] and route builders.
///
/// Required by [StatefulShellRoute.parentNavigatorKey] so routes that need
/// to push above the shell (e.g. full-screen dialogs) can use the root navigator.
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: '_kRoot');

/// Key for the [StatefulNavigationShell] that hosts the drawer branches.
final shellKey = GlobalKey<StatefulNavigationShellState>(debugLabel: '_kShell');

// Branch navigator keys — one per drawer destination in [ShellPage].
final _homeBranchKey = GlobalKey<NavigatorState>(debugLabel: '_kHome');
final _settingBranchKey = GlobalKey<NavigatorState>(debugLabel: '_kSetting');

/// Top-level route list consumed by [GoRouter].
///
/// Order matters: GoRouter matches routes top-to-bottom.
List<RouteBase> routes = [
  _splashRoute,
  _profileRoute,
  _forgotPasswordRoute,
  _emailVerificationRoute,
  _phoneInputRoute,
  _smsCodeRoute,
  _loginRoute,
  _registerRoute,
  _shellRoute,
  _termRoute,
  _privacyRoute,
  _languageSheetRoute,
  ..._dialogRoutes,
  _notFoundRoute,
];

// Splash — entry point
GoRoute get _splashRoute => GoRoute(
  name: Routers.root.routerName,
  path: Routers.root.routerPath,
  pageBuilder: (context, state) => TransitionPage(
    child: const SplashPage(),
    transitionType: PageTransitionType.fade,
  ),
);

// Profile
GoRoute get _profileRoute => GoRoute(
  name: Routers.profile.routerName,
  path: Routers.profile.routerPath,
  pageBuilder: (context, state) => TransitionPage(
    child: const ProfilePage(),
    transitionType: PageTransitionType.sharedAxisHorizontal,
  ),
);

// Forgot password
GoRoute get _forgotPasswordRoute => GoRoute(
  name: Routers.forgotPassword.routerName,
  path: Routers.forgotPassword.routerPath,
  pageBuilder: (context, state) {
    final email = state.extra as String?;
    return TransitionPage(
      child: ForgotPasswordPage(email: email),
      transitionType: PageTransitionType.sharedAxisHorizontal,
    );
  },
);

// Email verification — shown after registration
GoRoute get _emailVerificationRoute => GoRoute(
  name: Routers.emailVerification.routerName,
  path: Routers.emailVerification.routerPath,
  pageBuilder: (context, state) => TransitionPage(
    child: const EmailVerificationPage(),
    transitionType: PageTransitionType.fade,
  ),
);

// Phone number input — entry point for phone auth
GoRoute get _phoneInputRoute => GoRoute(
  name: Routers.phoneInput.routerName,
  path: Routers.phoneInput.routerPath,
  pageBuilder: (context, state) => TransitionPage(
    child: const PhoneInputPage(),
    transitionType: PageTransitionType.sharedAxisHorizontal,
  ),
);

// SMS code input — pushed from PhoneInputPage via SMSCodeRequestedAction
GoRoute get _smsCodeRoute => GoRoute(
  name: Routers.smsCode.routerName,
  path: Routers.smsCode.routerPath,
  pageBuilder: (context, state) {
    final extra = state.extra as Map<String, dynamic>;
    return TransitionPage(
      child: SmsCodePage(
        flowKey: extra['flowKey'] as Object,
        action: extra['action'] as AuthAction?,
      ),
      transitionType: PageTransitionType.sharedAxisHorizontal,
    );
  },
);

// Login
GoRoute get _loginRoute => GoRoute(
  name: Routers.login.routerName,
  path: Routers.login.routerPath,
  pageBuilder: (context, state) => TransitionPage(
    child: const LoginPage(),
    transitionType: PageTransitionType.fade,
  ),
);

// Register
GoRoute get _registerRoute => GoRoute(
  name: Routers.register.routerName,
  path: Routers.register.routerPath,
  pageBuilder: (context, state) => TransitionPage(
    child: const RegisterPage(),
    transitionType: PageTransitionType.fade,
  ),
);

// Shell — branches behind the navigation drawer. The branch order must match
// the drawer's destination order (AppDrawer).
StatefulShellRoute get _shellRoute => StatefulShellRoute(
  parentNavigatorKey: rootNavigatorKey,
  key: shellKey,
  builder: (context, state, navigationShell) => navigationShell,
  navigatorContainerBuilder: (context, navigationShell, children) =>
      ShellPage(shell: navigationShell, children: children),
  branches: [
    // Branch 0 — upcoming anniversaries (plan 0005, U2)
    StatefulShellBranch(
      navigatorKey: _homeBranchKey,
      routes: [
        GoRoute(
          name: Routers.home.routerName,
          path: Routers.home.routerPath,
          pageBuilder: (context, state) => TransitionPage(
            child: AnniversaryListPage(
              onAdd: () => context.go(Routers.anniversaryNew.routerPath),
            ),
            transitionType: PageTransitionType.fade,
          ),
          routes: [_anniversaryNewRoute],
        ),
      ],
    ),

    // Branch 1 — Settings
    StatefulShellBranch(
      navigatorKey: _settingBranchKey,
      routes: [
        GoRoute(
          name: Routers.setting.routerName,
          path: Routers.setting.routerPath,
          pageBuilder: (context, state) => TransitionPage(
            child: const SettingPage(),
            transitionType: PageTransitionType.fade,
          ),
        ),
      ],
    ),
  ],
);

// Add form over the list. A child of home so Back returns to the list; on
// the root navigator so it covers the drawer shell.
GoRoute get _anniversaryNewRoute => GoRoute(
  parentNavigatorKey: rootNavigatorKey,
  name: Routers.anniversaryNew.routerName,
  path: 'new', // Routers.anniversaryNew = home + '/new'
  pageBuilder: (context, state) => TransitionPage(
    child: AnniversaryFormPage(
      onClose: () => context.go(Routers.home.routerPath),
    ),
    transitionType: PageTransitionType.sharedAxisHorizontal,
  ),
);

// Pages
GoRoute get _termRoute => GoRoute(
  name: Routers.terms.routerName,
  path: Routers.terms.routerPath,
  pageBuilder: (context, state) => TransitionPage(
    child: const TermsPage(),
    transitionType: PageTransitionType.sharedAxisHorizontal,
  ),
);

GoRoute get _privacyRoute => GoRoute(
  name: Routers.privacy.routerName,
  path: Routers.privacy.routerPath,
  pageBuilder: (context, state) => TransitionPage(
    child: const PrivacyPage(),
    transitionType: PageTransitionType.sharedAxisHorizontal,
  ),
);

// Bottom sheet
GoRoute get _languageSheetRoute => GoRoute(
  name: Routers.languageSheet.routerName,
  path: Routers.languageSheet.routerPath,
  pageBuilder: (context, state) => BottomSheetWidget.unScroll(
    builder: (context) => const LanguageBottomSheet(),
    barrierLabel: Routers.languageSheet.routerName,
    isDismissible: false,
  ),
);

List<GoRoute> get _dialogRoutes => [
  GoRoute(
    name: Routers.confirmDialog.routerName,
    path: Routers.confirmDialog.routerPath,
    pageBuilder: (context, state) => RouteDialogWidget<bool>(
      builder: (context) => const ConfirmDialogWidget(
        title: 'Are you sure to open the device info?',
        message: 'This will show you the device info.',
      ),
    ),
  ),
];

// 404 fallback
GoRoute get _notFoundRoute => GoRoute(
  name: Routers.pageNotFound.routerName,
  path: Routers.pageNotFound.routerPath,
  pageBuilder: (context, state) => TransitionPage(
    child: const NotFoundPage(),
    transitionType: PageTransitionType.slideFromRight,
  ),
);

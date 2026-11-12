import 'package:flutter/material.dart';
import 'package:ever_moon/services/firebase_notification_service.dart';
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
final _calendarBranchKey = GlobalKey<NavigatorState>(debugLabel: '_kCalendar');
final _settingBranchKey = GlobalKey<NavigatorState>(debugLabel: '_kSetting');

/// Top-level route list consumed by [GoRouter].
///
/// Order matters: GoRouter matches routes top-to-bottom.
List<RouteBase> routes = [
  _splashRoute,
  _onboardingRoute,
  _shellRoute,
  ..._dialogRoutes,
  _notFoundRoute,
];

// Splash, intro and the first screen change slowly enough to be seen: the
// 350 ms default read as a plain fade.
const _flowTransition = Duration(milliseconds: 500);

// Splash — entry point
GoRoute get _splashRoute => GoRoute(
  name: Routers.root.routerName,
  path: Routers.root.routerPath,
  pageBuilder: (context, state) => TransitionPage(
    child: SplashPage(
      onNotificationsAllowed:
          FirebaseNotificationService.instance.requestPermissionAndFetchToken,
    ),
    // Fade through: the old page fades out, then the new one scales in.
    transitionType: PageTransitionType.fadeThrough,
    transitionDuration: _flowTransition,
    reverseTransitionDuration: _flowTransition,
  ),
);

// First-run intro and notification explanation (plan 0005, U7). Splash
// sends the first launch here; finishing opens the list.
GoRoute get _onboardingRoute => GoRoute(
  name: Routers.onboarding.routerName,
  path: Routers.onboarding.routerPath,
  pageBuilder: (context, state) => TransitionPage(
    child: OnboardingPage(
      onDone: () => context.go(Routers.home.routerPath),
      onNotificationsAllowed:
          FirebaseNotificationService.instance.requestPermissionAndFetchToken,
    ),
    transitionType: PageTransitionType.fadeThrough,
    transitionDuration: _flowTransition,
    reverseTransitionDuration: _flowTransition,
  ),
);

// Shell — branches behind the navigation drawer. The branch order must match
// the drawer's destination order (AppDrawer).
StatefulShellRoute get _shellRoute => StatefulShellRoute(
  parentNavigatorKey: rootNavigatorKey,
  key: shellKey,
  // A transition page, so the shell scales out when a parent-child page
  // (edit form, terms, privacy) opens over it: shared axis needs the page
  // underneath to move too. The key is the route's own, so rebuilding never
  // replaces the shell.
  pageBuilder: (context, state, navigationShell) => TransitionPage(
    key: state.pageKey,
    child: navigationShell,
    transitionType: PageTransitionType.sharedAxisScaled,
  ),
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
            child: const AnniversaryListPage(addForm: _addForm),
            transitionType: PageTransitionType.fade,
          ),
        ),
      ],
    ),

    // Branch 1 — calendar (plan 0005, U5)
    StatefulShellBranch(
      navigatorKey: _calendarBranchKey,
      routes: [
        GoRoute(
          name: Routers.calendar.routerName,
          path: Routers.calendar.routerPath,
          pageBuilder: (context, state) => TransitionPage(
            child: CalendarPage(
              addForm: _addForm,
              onEdit: (id) => context.goNamed(
                Routers.anniversaryEdit.routerName,
                pathParameters: {'id': id},
              ),
            ),
            transitionType: PageTransitionType.fade,
          ),
          routes: [_anniversaryEditRoute],
        ),
      ],
    ),

    // Branch 2 — Settings
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
          // Children of Settings so Back returns there (D14).
          routes: [_termRoute, _privacyRoute],
        ),
      ],
    ),
  ],
);

// The add form, built inside a container transform from the add button (list
// and calendar, D12: the same empty form). The container pushes its own
// route, so the form has no GoRouter path; closing pops that route.
Widget _addForm(VoidCallback close) => AnniversaryFormPage(onClose: close);

// Edit form, reached by swiping an anniversary on the calendar (D15). A
// shared axis (z) like the other parent-child pages: the shell underneath
// scales out as the form scales in.
GoRoute get _anniversaryEditRoute => GoRoute(
  parentNavigatorKey: rootNavigatorKey,
  name: Routers.anniversaryEdit.routerName,
  path: 'edit/:id', // Routers.anniversaryEdit = calendar + '/edit/:id'
  pageBuilder: (context, state) => TransitionPage(
    child: AnniversaryFormPage(
      anniversaryId: state.pathParameters['id'],
      onClose: () => context.go(Routers.calendar.routerPath),
    ),
    transitionType: PageTransitionType.sharedAxisScaled,
  ),
);

// Pages
GoRoute get _termRoute => GoRoute(
  parentNavigatorKey: rootNavigatorKey,
  name: Routers.terms.routerName,
  path: 'terms', // Routers.terms = setting + '/terms'
  pageBuilder: (context, state) => TransitionPage(
    child: const TermsPage(),
    transitionType: PageTransitionType.sharedAxisScaled,
  ),
);

GoRoute get _privacyRoute => GoRoute(
  parentNavigatorKey: rootNavigatorKey,
  name: Routers.privacy.routerName,
  path: 'privacy', // Routers.privacy = setting + '/privacy'
  pageBuilder: (context, state) => TransitionPage(
    child: const PrivacyPage(),
    transitionType: PageTransitionType.sharedAxisScaled,
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

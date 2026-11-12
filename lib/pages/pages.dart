/// All screens, cubits, states, and shared widgets of the app.
///
/// **Shell**
/// - [ShellPage] — root scaffold with the navigation drawer
///
/// **Tab screens**
/// - [AnniversaryListPage] — upcoming anniversaries (read-only)
/// - [SettingPage] — language, theme, notifications, system events, About
///
/// **Standalone screens**
/// - [SplashPage] / [SplashCubit] / [SplashState]
/// - [PrivacyPage] — Privacy Policy rendered from Markdown asset
/// - [TermsPage] — Terms of Service rendered from Markdown asset
///
/// **Shared widgets**
/// - [AnimatedBranchContainer] — animated tab body for [StatefulShellRoute]
/// - [HeroImageWidget] — Hero-wraps any image widget, tap to open
///   `ImagePreviewPage`
/// - [NotFoundPage] — 404 fallback
/// - [TransitionPage] — [CustomTransitionPage] with [PageTransitionType]
/// - [ShellTransitionType] — transition styles for shell tab switches
/// - [FadeWrapper] / [FadeThroughWrapper] / [SharedAxisTransitionWrapper] /
///   [OpenContainerWrapper] — documented wrappers over the `animations`
///   package's Material motion patterns
// ignore: unnecessary_library_name
library pages;

export 'anniversary_form/anniversary_form_page.dart';
export 'anniversary_list/anniversary_list_page.dart';
export 'calendar/calendar_page.dart';
export 'onboarding/onboarding_page.dart';
export 'privacy/privacy_page.dart';
export 'setting/setting_page.dart';
export 'shell/shell_page.dart';
export 'splash/splash_page.dart';
export 'terms/terms_page.dart';
export 'widgets/animated_bottom_navigation_widget.dart';
export 'widgets/animations_wrapper/fade_through_wrapper.dart';
export 'widgets/animations_wrapper/fade_wrapper.dart';
export 'widgets/animations_wrapper/open_container_wrapper.dart';
export 'widgets/animations_wrapper/shared_axis_transition_wrapper.dart';
export 'widgets/confirm_dialog_widget.dart';
export 'widgets/not_found_page.dart';
export 'widgets/route_dialog_widget.dart';
export 'widgets/transition_dialog_widget.dart';
export 'widgets/transition_shell_widget.dart';
export 'widgets/transition_widget.dart';

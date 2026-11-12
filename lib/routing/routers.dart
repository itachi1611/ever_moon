/// Centralised route registry for the app.
///
/// Each value pairs a URL [routerPath] (used with `context.go()`) with a
/// human-readable [routerName] (used with `context.goNamed()`).
///
/// Always add new routes here before wiring them in [router_config.dart].
enum Routers {
  /// Splash screen — app entry point (`/`).
  root('/', 'root'),

  /// First-run intro and notification explanation (`/onboarding`, U7).
  onboarding('/onboarding', 'onboarding'),

  /// Home tab inside the shell (`/home`).
  home('/home', 'home'),

  /// Calendar tab inside the shell (`/calendar`, plan 0005 U5).
  calendar('/calendar', 'calendar'),

  /// Edit form over the calendar (`/calendar/edit/:id`, D5, D15). Go there
  /// with `goNamed` and the `id` path parameter.
  anniversaryEdit('/calendar/edit/:id', 'anniversaryEdit'),

  /// Settings tab inside the shell (`/setting`).
  setting('/setting', 'setting'),

  /// Terms of Service page, over Settings (`/setting/terms`).
  terms('/setting/terms', 'terms'),

  /// Privacy Policy page, over Settings (`/setting/privacy`).
  privacy('/setting/privacy', 'privacy'),

  /// Dialog
  confirmDialog('/confirmDialog', 'confirmDialog'),

  /// 404 fallback page (`/pageNotFound`).
  pageNotFound('/pageNotFound', 'pageNotFound');

  /// URL path used with `context.go(routerPath)`.
  final String routerPath;

  /// Named route used with `context.goNamed(routerName)`.
  final String routerName;

  const Routers(this.routerPath, this.routerName);
}

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

  /// Add form over the upcoming list (`/home/new`, plan 0005 D5). Its
  /// GoRoute is the child `new` of [home].
  anniversaryNew('/home/new', 'anniversaryNew'),

  /// Calendar tab inside the shell (`/calendar`, plan 0005 U5).
  calendar('/calendar', 'calendar'),

  /// Add form over the calendar (`/calendar/new`, D12: empty like the list's).
  calendarNew('/calendar/new', 'calendarNew'),

  /// Edit form over the calendar (`/calendar/edit/:id`, D5, D15). Go there
  /// with `goNamed` and the `id` path parameter.
  anniversaryEdit('/calendar/edit/:id', 'anniversaryEdit'),

  /// Settings tab inside the shell (`/setting`).
  setting('/setting', 'setting'),

  /// Terms of Service page (`/terms`).
  terms('/terms', 'terms'),

  /// Privacy Policy page (`/privacy`).
  privacy('/privacy', 'privacy'),

  /// Bottom sheet
  languageSheet('/languageSheet', 'languageSheet'),

  /// Dialog
  confirmDialog('/confirmDialog', 'confirmDialog'),

  /// User profile page (`/profile`).
  profile('/profile', 'profile'),

  /// Forgot password page (`/forgotPassword`).
  forgotPassword('/forgotPassword', 'forgotPassword'),

  /// Email verification page (`/emailVerification`).
  emailVerification('/emailVerification', 'emailVerification'),

  /// Phone number input page for phone auth (`/phoneInput`).
  phoneInput('/phoneInput', 'phoneInput'),

  /// SMS code input page — reached from [phoneInput] (`/smsCode`).
  smsCode('/smsCode', 'smsCode'),

  /// Login page (`/login`).
  login('/login', 'login'),

  /// Register page (`/register`).
  register('/register', 'register'),

  /// 404 fallback page (`/pageNotFound`).
  pageNotFound('/pageNotFound', 'pageNotFound');

  /// URL path used with `context.go(routerPath)`.
  final String routerPath;

  /// Named route used with `context.goNamed(routerName)`.
  final String routerName;

  const Routers(this.routerPath, this.routerName);
}

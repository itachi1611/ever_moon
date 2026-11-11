import 'package:equatable/equatable.dart';

/// The three intro pages, in order (design: Intro1 to Intro3).
enum IntroSlide {
  /// Anniversaries by lunar day and month.
  lunar,

  /// Reminders 1, 3 or 7 days before.
  reminders,

  /// Mùng 1, rằm and festivals on the calendar.
  holidays,
}

/// State of the first-run flow (plan 0005, U7; UI-15).
sealed class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object?> get props => [];
}

/// One of the intro pages.
final class OnboardingSlides extends OnboardingState {
  /// Creates the state on [slide].
  const OnboardingSlides(this.slide);

  /// The page on screen.
  final IntroSlide slide;

  /// Whether it is the last page (its button says "Bắt đầu").
  bool get isLast => slide == IntroSlide.values.last;

  @override
  List<Object?> get props => [slide];
}

/// The screen that explains notifications before the system dialog.
final class OnboardingNotify extends OnboardingState {
  /// Creates the state; [busy] while the system dialog is open.
  const OnboardingNotify({this.busy = false});

  /// Whether the permission request is running.
  final bool busy;

  @override
  List<Object?> get props => [busy];
}

/// Finished; the flag is stored and the list opens.
final class OnboardingDone extends OnboardingState {
  /// Creates the done state.
  const OnboardingDone();
}

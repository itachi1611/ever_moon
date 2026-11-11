import 'package:equatable/equatable.dart';

/// State of the Flutter splash that follows the native one (plan 0005, U7).
sealed class SplashState extends Equatable {
  const SplashState();

  @override
  List<Object?> get props => [];
}

/// Deciding where to go.
final class SplashChecking extends SplashState {
  /// Creates the checking state.
  const SplashChecking();
}

/// Decided: the intro on the first launch, otherwise the list (UI-15).
final class SplashReady extends SplashState {
  /// Creates the state.
  const SplashReady({required this.firstRun});

  /// Whether the intro has never been finished.
  final bool firstRun;

  @override
  List<Object?> get props => [firstRun];
}

import 'package:equatable/equatable.dart';
import 'package:ever_moon/services/lunar/lunar_calendar_service.dart';

/// State of the navigation shell: what the drawer header shows.
sealed class ShellState extends Equatable {
  const ShellState();

  @override
  List<Object?> get props => [];
}

/// Before the first refresh.
final class ShellStarting extends ShellState {
  /// Creates the starting state.
  const ShellStarting();
}

/// Today's dates and how many anniversaries fall today.
final class ShellReady extends ShellState {
  /// Creates the state for [solarToday].
  const ShellReady({
    required this.solarToday,
    required this.lunarToday,
    required this.todayCount,
  });

  /// Today as UTC midnight.
  final DateTime solarToday;

  /// Today's lunar date; `null` outside the supported range.
  final LunarDate? lunarToday;

  /// Anniversaries held today.
  final int todayCount;

  @override
  List<Object?> get props => [solarToday, lunarToday, todayCount];
}

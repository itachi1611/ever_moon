import 'package:equatable/equatable.dart';

import 'calendar_models.dart';

/// State of the calendar tab (plan 0005, U5).
sealed class CalendarState extends Equatable {
  const CalendarState();

  @override
  List<Object?> get props => [];
}

/// Waiting for the first list of anniversaries.
final class CalendarLoading extends CalendarState {
  /// Creates the loading state.
  const CalendarLoading();
}

/// Reading the anniversaries failed; the page offers a retry.
final class CalendarFailure extends CalendarState {
  /// Creates the failure state.
  const CalendarFailure();
}

/// A period ready to show.
final class CalendarReady extends CalendarState {
  /// Creates the state; the Cubit is the producer.
  const CalendarReady({
    required this.today,
    required this.selected,
    required this.period,
  });

  /// Today, UTC midnight.
  final DateTime today;

  /// The selected day, UTC midnight; it decides which period is shown.
  final DateTime selected;

  /// What the current view shows.
  final CalendarPeriod period;

  /// The current view.
  CalendarView get view => switch (period) {
    YearPeriod() => CalendarView.year,
    MonthPeriod() => CalendarView.month,
    WeekPeriod() => CalendarView.week,
  };

  @override
  List<Object?> get props => [today, selected, period];
}

/// The content of one view.
sealed class CalendarPeriod extends Equatable {
  const CalendarPeriod();
}

/// One Gregorian year as twelve month summaries.
final class YearPeriod extends CalendarPeriod {
  /// Creates the year view of [year].
  const YearPeriod({required this.year, required this.months});

  /// Gregorian year.
  final int year;

  /// January to December.
  final List<MonthSummary> months;

  /// Anniversaries in the year.
  int get anniversaryCount => months.fold(0, (s, m) => s + m.anniversaries);

  /// Named festivals in the year.
  int get festivalCount => months.fold(0, (s, m) => s + m.festivals);

  @override
  List<Object?> get props => [year, months];
}

/// One Gregorian month as a Monday-first grid.
final class MonthPeriod extends CalendarPeriod {
  /// Creates the month view; [cells] has `null` before day 1 and after the
  /// last day so every row has seven cells.
  const MonthPeriod({
    required this.year,
    required this.month,
    required this.cells,
  });

  /// Gregorian year.
  final int year;

  /// Gregorian month, 1 to 12.
  final int month;

  /// Grid cells, row by row.
  final List<CalendarDay?> cells;

  /// The days of the month, without the empty cells.
  List<CalendarDay> get days => cells.whereType<CalendarDay>().toList();

  @override
  List<Object?> get props => [year, month, cells];
}

/// One Monday-to-Sunday week.
final class WeekPeriod extends CalendarPeriod {
  /// Creates the week view.
  const WeekPeriod({required this.days});

  /// Monday first.
  final List<CalendarDay> days;

  @override
  List<Object?> get props => [days];
}

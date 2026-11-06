/// A day in the Vietnamese lunar calendar.
///
/// Plain value; whether it exists is decided by the calendar, whose
/// `toSolar` returns `null` when it does not.
final class LunarDate {
  /// Creates a lunar date value without validating it.
  const LunarDate(this.year, this.month, this.day, {this.isLeapMonth = false});

  /// Lunar year (the year that starts at Tết).
  final int year;

  /// Month number from 1 to 12.
  final int month;

  /// Day of the month from 1 to 30.
  final int day;

  /// Whether the day is in the leap month that repeats [month].
  final bool isLeapMonth;

  @override
  bool operator ==(Object other) =>
      other is LunarDate &&
      other.year == year &&
      other.month == month &&
      other.day == day &&
      other.isLeapMonth == isLeapMonth;

  @override
  int get hashCode => Object.hash(year, month, day, isLeapMonth);

  @override
  String toString() =>
      'LunarDate($day/$month${isLeapMonth ? ' leap' : ''}/$year)';
}

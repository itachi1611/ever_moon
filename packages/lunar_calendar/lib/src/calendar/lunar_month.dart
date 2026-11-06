import '../astronomy/julian_day.dart';

/// One month of the Vietnamese lunar calendar.
final class LunarMonth {
  /// Creates a month value; the engine is the only intended producer.
  const LunarMonth({
    required this.lunarYear,
    required this.month,
    required this.isLeap,
    required this.startJdn,
    required this.length,
  });

  /// Lunar year the month belongs to (the year that starts at Tết).
  final int lunarYear;

  /// Month number from 1 to 12; a leap month repeats the previous number.
  final int month;

  /// Whether this is the leap (intercalary) month.
  final bool isLeap;

  /// Julian Day Number of the first day (mùng 1), in UTC+7 civil days.
  final int startJdn;

  /// Number of days, 29 or 30.
  final int length;

  /// Gregorian date of the first day, as UTC midnight.
  DateTime get start => civilFromJdn(startJdn);

  /// Whether the civil day [jdn] falls inside this month.
  bool containsJdn(int jdn) => jdn >= startJdn && jdn < startJdn + length;

  @override
  bool operator ==(Object other) =>
      other is LunarMonth &&
      other.lunarYear == lunarYear &&
      other.month == month &&
      other.isLeap == isLeap &&
      other.startJdn == startJdn &&
      other.length == length;

  @override
  int get hashCode => Object.hash(lunarYear, month, isLeap, startJdn, length);

  @override
  String toString() =>
      'LunarMonth($lunarYear-$month${isLeap ? ' leap' : ''}, '
      'start ${start.toIso8601String().substring(0, 10)}, $length days)';
}

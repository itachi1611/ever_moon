import '../astronomy/julian_day.dart';
import '../astronomy/new_moon.dart';
import '../astronomy/principal_term.dart';
import 'lunar_month.dart';

/// Index of the December solstice (270 degrees) among the principal terms.
const int _solsticeIndex = 9;

/// Builds lunar months from the published Vietnamese rules, in UTC+7.
///
/// Rules: a month starts on the civil day of a new moon; month 11 is the
/// month that contains the December solstice; when 13 months lie between two
/// consecutive months 11, the first one after month 11 with no principal
/// term is the leap month and repeats the previous number.
///
/// Results are cached, so one instance should be shared.
class MonthBuilder {
  final Map<int, int> _newMoonDays = {};
  final Map<int, List<int>> _termDays = {};
  final Map<int, List<LunarMonth>> _spans = {};
  final Map<int, List<LunarMonth>> _years = {};

  /// Months of [lunarYear] in order, including its leap month if any.
  ///
  /// No range check here; the public calendar enforces the supported range.
  List<LunarMonth> monthsOfYear(int lunarYear) =>
      _years[lunarYear] ??= List.unmodifiable([
        ...span(lunarYear - 1).where((m) => m.lunarYear == lunarYear),
        ...span(lunarYear).where((m) => m.lunarYear == lunarYear),
      ]);

  /// Months from month 11 that starts in Gregorian [year] up to, but not
  /// including, month 11 that starts in [year] + 1.
  List<LunarMonth> span(int year) => _spans[year] ??= _buildSpan(year);

  /// Lunation number of month 11 that starts in Gregorian [year].
  int month11Lunation(int year) {
    final solsticeDay = _principalTermDays(year)[_solsticeIndex];
    var k = nearestLunation(principalTermJde(year, _solsticeIndex));
    while (newMoonDay(k) > solsticeDay) {
      k--;
    }
    while (newMoonDay(k + 1) <= solsticeDay) {
      k++;
    }
    return k;
  }

  /// Civil day number (UTC+7) of the new moon with lunation number [k].
  int newMoonDay(int k) =>
      _newMoonDays[k] ??= localDayNumber(jdeToJdUt(newMoonJde(k)));

  List<LunarMonth> _buildSpan(int year) {
    final begin = month11Lunation(year);
    final end = month11Lunation(year + 1);
    final starts = [for (var k = begin; k <= end; k++) newMoonDay(k)];
    final terms = [..._principalTermDays(year), ..._principalTermDays(year + 1)];
    final leapIndex = starts.length - 1 == 13 ? _leapIndex(starts, terms) : null;
    return _label(year, starts, leapIndex);
  }

  List<int> _principalTermDays(int year) => _termDays[year] ??= [
        for (var index = 0; index < 12; index++)
          localDayNumber(jdeToJdUt(principalTermJde(year, index))),
      ];
}

/// Position (1 to 12) of the first month after month 11 with no principal
/// term, or `null` if every month has one.
int? _leapIndex(List<int> starts, List<int> termDays) {
  for (var j = 1; j < starts.length - 1; j++) {
    final hasTerm =
        termDays.any((day) => day >= starts[j] && day < starts[j + 1]);
    if (!hasTerm) return j;
  }
  return null;
}

/// Numbers the months of one span, starting at month 11 of [year].
List<LunarMonth> _label(int year, List<int> starts, int? leapIndex) {
  final months = <LunarMonth>[];
  var number = 11;
  var lunarYear = year;
  for (var j = 0; j < starts.length - 1; j++) {
    final isLeap = j == leapIndex;
    if (j > 0 && !isLeap) {
      number = number % 12 + 1;
      if (number == 1) lunarYear++;
    }
    months.add(LunarMonth(
      lunarYear: lunarYear,
      month: number,
      isLeap: isLeap,
      startJdn: starts[j],
      length: starts[j + 1] - starts[j],
    ));
  }
  return months;
}

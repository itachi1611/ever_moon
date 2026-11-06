import 'package:equatable/equatable.dart';

/// The lunar date an anniversary (giỗ) is held on, as the family records it.
///
/// Day and month are required; the death year is optional and never
/// validated against the calendar (ADR 0001). [diedInLeapMonth] only counts
/// when [deathYear] is known; `AnniversaryResolver.normalize` clears it
/// otherwise.
class AnniversaryDate extends Equatable {
  /// Creates the value; [lunarDay] is 1 to 30 and [lunarMonth] 1 to 12.
  const AnniversaryDate({
    required this.lunarDay,
    required this.lunarMonth,
    this.deathYear,
    this.diedInLeapMonth = false,
  })  : assert(lunarDay >= 1 && lunarDay <= 30, 'lunarDay must be 1 to 30'),
        assert(lunarMonth >= 1 && lunarMonth <= 12,
            'lunarMonth must be 1 to 12');

  /// Lunar day of the death, 1 to 30.
  final int lunarDay;

  /// Lunar month number of the death, 1 to 12.
  final int lunarMonth;

  /// Lunar year of the death, when the family knows it.
  final int? deathYear;

  /// Whether the death happened in the leap month repeating [lunarMonth].
  final bool diedInLeapMonth;

  /// Copy with [diedInLeapMonth] replaced.
  AnniversaryDate withDiedInLeapMonth(bool value) => AnniversaryDate(
        lunarDay: lunarDay,
        lunarMonth: lunarMonth,
        deathYear: deathYear,
        diedInLeapMonth: value,
      );

  @override
  List<Object?> get props => [lunarDay, lunarMonth, deathYear, diedInLeapMonth];
}

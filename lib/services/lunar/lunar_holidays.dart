import 'package:equatable/equatable.dart';
import 'package:ever_moon/services/lunar/lunar_calendar_service.dart';

/// Traditional festivals on a fixed lunar date (plan 0005, D16).
///
/// The list follows the fixed-date Tết days in "Mỗi năm người Việt có bao
/// nhiêu ngày Tết?" (viettimes.vn, post19147), plus Giỗ Tổ Hùng Vương, added
/// by Fox on 2026-11-12. Tết Thanh Minh was tried and dropped the same day.
enum LunarFestival {
  /// Tết Nguyên Đán, 1/1.
  nguyenDan(1, 1),

  /// Tết Nguyên Tiêu (Rằm tháng Giêng), 15/1.
  nguyenTieu(1, 15),

  /// Tết Hàn Thực, 3/3.
  hanThuc(3, 3),

  /// Giỗ Tổ Hùng Vương, 10/3 (public holiday).
  hungKings(3, 10),

  /// Tết Đoan Ngọ, 5/5.
  doanNgo(5, 5),

  /// Tết Trung Nguyên (Rằm tháng Bảy), 15/7.
  trungNguyen(7, 15),

  /// Tết Trung Thu, 15/8.
  trungThu(8, 15),

  /// Tết Táo Quân (ông Công ông Táo), 23/12.
  taoQuan(12, 23);

  const LunarFestival(this.month, this.day);

  /// Lunar month (regular, never the leap one).
  final int month;

  /// Lunar day.
  final int day;
}

/// A system event: a named festival, mùng 1 or rằm.
sealed class LunarHoliday extends Equatable {
  const LunarHoliday();

  /// Whether the year view counts it: named festivals only, not plain
  /// mùng 1 and rằm (D16).
  bool get isFestival => this is FestivalHoliday;

  /// The holiday on [date], or `null` on an ordinary day.
  ///
  /// Festivals fall only in regular months; a leap month still has its
  /// mùng 1 and rằm.
  static LunarHoliday? on(LunarDate date) {
    if (!date.isLeapMonth) {
      for (final festival in LunarFestival.values) {
        if (festival.month == date.month && festival.day == date.day) {
          return FestivalHoliday(festival);
        }
      }
    }
    if (date.day == 1) return FirstDayHoliday(date.month, date.isLeapMonth);
    if (date.day == 15) return FullMoonHoliday(date.month, date.isLeapMonth);
    return null;
  }
}

/// A named festival.
final class FestivalHoliday extends LunarHoliday {
  /// Creates the holiday for [festival].
  const FestivalHoliday(this.festival);

  /// Which festival.
  final LunarFestival festival;

  @override
  List<Object?> get props => [festival];
}

/// Mùng 1 of a lunar month.
final class FirstDayHoliday extends LunarHoliday {
  /// Creates mùng 1 of [month].
  const FirstDayHoliday(this.month, this.isLeapMonth);

  /// Lunar month number.
  final int month;

  /// Whether it is the leap month.
  final bool isLeapMonth;

  @override
  List<Object?> get props => [month, isLeapMonth];
}

/// Rằm (day 15) of a lunar month.
final class FullMoonHoliday extends LunarHoliday {
  /// Creates rằm of [month].
  const FullMoonHoliday(this.month, this.isLeapMonth);

  /// Lunar month number.
  final int month;

  /// Whether it is the leap month.
  final bool isLeapMonth;

  @override
  List<Object?> get props => [month, isLeapMonth];
}

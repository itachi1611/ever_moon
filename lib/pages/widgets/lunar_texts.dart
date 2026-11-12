import 'package:ever_moon/generated/l10n.dart';
import 'package:ever_moon/services/lunar/lunar_calendar_service.dart';
import 'package:ever_moon/services/lunar/lunar_holidays.dart';

/// "9 tháng 10 âm lịch", or the leap form.
String lunarDateText(S s, LunarDate date) => date.isLeapMonth
    ? s.lb_lunar_date_leap(date.day, date.month)
    : s.lb_lunar_date(date.day, date.month);

/// "tháng 10", or "tháng 10 nhuận".
String lunarMonthText(S s, int month, {required bool isLeapMonth}) =>
    isLeapMonth
    ? s.lb_lunar_month_short_leap(month)
    : s.lb_lunar_month_short(month);

/// Name of [holiday]: "Mùng 1 tháng 10", "Rằm tháng 10" or the festival.
String holidayName(S s, LunarHoliday holiday) => switch (holiday) {
  FestivalHoliday(:final festival) => festivalName(s, festival),
  ThanhMinhHoliday() => s.lb_festival_thanh_minh,
  FirstDayHoliday(:final month, :final isLeapMonth) => s.lb_first_day(
    lunarMonthText(s, month, isLeapMonth: isLeapMonth),
  ),
  FullMoonHoliday(:final month, :final isLeapMonth) => s.lb_full_moon(
    lunarMonthText(s, month, isLeapMonth: isLeapMonth),
  ),
};

/// Second line under a holiday: monthly observance or festival.
String holidayKindText(S s, LunarHoliday holiday) =>
    holiday.isFestival ? s.lb_traditional_festival : s.lb_monthly_holiday;

/// Localized name of [festival].
String festivalName(S s, LunarFestival festival) => switch (festival) {
  LunarFestival.nguyenDan => s.lb_festival_nguyen_dan,
  LunarFestival.nguyenTieu => s.lb_festival_nguyen_tieu,
  LunarFestival.hanThuc => s.lb_festival_han_thuc,
  LunarFestival.hungKings => s.lb_festival_hung_kings,
  LunarFestival.doanNgo => s.lb_festival_doan_ngo,
  LunarFestival.trungNguyen => s.lb_festival_trung_nguyen,
  LunarFestival.trungThu => s.lb_festival_trung_thu,
  LunarFestival.taoQuan => s.lb_festival_tao_quan,
};

// Plan 0005, U5 (D16): which lunar days are holidays.
import 'package:ever_moon/services/lunar/lunar_calendar_service.dart';
import 'package:ever_moon/services/lunar/lunar_holidays.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('festivals win over plain mùng 1 and rằm', () {
    expect(
      LunarHoliday.on(const LunarDate(2002, 1, 1)),
      const FestivalHoliday(LunarFestival.nguyenDan),
    );
    expect(
      LunarHoliday.on(const LunarDate(2002, 8, 15)),
      const FestivalHoliday(LunarFestival.trungThu),
    );
    expect(
      LunarHoliday.on(const LunarDate(2002, 12, 23)),
      const FestivalHoliday(LunarFestival.taoQuan),
    );
  });

  test('every other mùng 1 and rằm is a monthly holiday', () {
    expect(
      LunarHoliday.on(const LunarDate(2002, 3, 1)),
      const FirstDayHoliday(3, false),
    );
    expect(
      LunarHoliday.on(const LunarDate(2002, 4, 15)),
      const FullMoonHoliday(4, false),
    );
    expect(LunarHoliday.on(const LunarDate(2002, 4, 14)), isNull);
  });

  test('a leap month has mùng 1 and rằm but no festival', () {
    expect(
      LunarHoliday.on(const LunarDate(2005, 8, 15, isLeapMonth: true)),
      const FullMoonHoliday(8, true),
    );
    expect(
      LunarHoliday.on(const LunarDate(2005, 5, 5, isLeapMonth: true)),
      isNull,
    );
  });

  test('only named festivals count for the year view', () {
    expect(const FestivalHoliday(LunarFestival.hanThuc).isFestival, isTrue);
    expect(const FirstDayHoliday(1, false).isFestival, isFalse);
  });
}

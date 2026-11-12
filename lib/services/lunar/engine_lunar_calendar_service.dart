import 'package:ever_moon/services/lunar/lunar_calendar_service.dart';
import 'package:lunar_calendar/lunar_calendar.dart';

/// [LunarCalendarService] backed by the in-repo `lunar_calendar` engine.
///
/// Singleton so the engine's month cache is shared across the app.
class EngineLunarCalendarService implements LunarCalendarService {
  EngineLunarCalendarService._internal();

  /// The single instance; prefer the `lunarCalendarService` getter.
  static final EngineLunarCalendarService instance =
      EngineLunarCalendarService._internal();

  final VietnameseLunarCalendar _calendar = VietnameseLunarCalendar.shared;

  @override
  bool isSupportedYear(int lunarYear) => isSupportedLunarYear(lunarYear);

  @override
  LunarDate? toLunar(DateTime solarDate) => _calendar.toLunar(solarDate);

  @override
  DateTime? toSolar(LunarDate date) => _calendar.toSolar(date);

  @override
  int? leapMonthOf(int lunarYear) => _calendar.leapMonthOf(lunarYear);

  @override
  DateTime? thanhMinhOf(int year) => _calendar.thanhMinhOf(year);
}

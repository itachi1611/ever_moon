import 'package:ever_moon/models/anniversary.dart';
import 'package:ever_moon/models/app_settings.dart';
import 'package:ever_moon/services/lunar/anniversary_resolver.dart';
import 'package:ever_moon/services/lunar/lunar_calendar_service.dart';
import 'package:ever_moon/services/lunar/lunar_holidays.dart';
import 'package:ever_moon/services/reminders/planned_reminder.dart';

/// Decides which notifications should exist right now (plan 0006, N1).
///
/// Pure: it reads no clock, time zone, plugin or database. Every leap-month
/// and day-30 decision stays in [AnniversaryResolver]; this class only moves
/// the resolved date back by the lead time and keeps what falls inside the
/// planning window.
class ReminderPlanner {
  /// Creates a planner over [resolver] and [calendar] (inject fakes in tests).
  const ReminderPlanner({
    required AnniversaryResolver resolver,
    required LunarCalendarService calendar,
  }) : _resolver = resolver,
       _calendar = calendar;

  final AnniversaryResolver _resolver;
  final LunarCalendarService _calendar;

  /// Most notifications planned at once. iOS keeps 64 pending notifications,
  /// so one cap serves both platforms (D-R2).
  static const int maxPlanned = 60;

  /// How far ahead reminders are planned, in days (D-R2).
  static const int windowDays = 365;

  /// Fixed time of day of system-event reminders: 07:00.
  static const int systemEventMinuteOfDay = 7 * 60;

  /// The reminders to schedule at [now], earliest first, at most [maxPlanned].
  ///
  /// Times at or before [now] are skipped (D-R8). [now] is a wall-clock time
  /// in the device's local zone. Returns nothing when [now] is outside the
  /// engine's supported years.
  List<PlannedReminder> plan({
    required Iterable<Anniversary> anniversaries,
    required AppSettings settings,
    required DateTime now,
  }) {
    final lunarYear = _calendar.toLunar(now)?.year;
    if (lunarYear == null) return const [];
    final horizon = _wallClock(now, windowDays);
    bool inWindow(DateTime t) => t.isAfter(now) && t.isBefore(horizon);
    final all = <PlannedReminder>[
      for (final a in anniversaries)
        if (a.reminderEnabled) ..._forAnniversary(a, lunarYear, inWindow),
      ..._systemEvents(settings, now, inWindow),
    ]..sort(_byFireTime);
    return all.length <= maxPlanned ? all : all.sublist(0, maxPlanned);
  }

  Iterable<PlannedReminder> _forAnniversary(
    Anniversary a,
    int lunarYear,
    bool Function(DateTime) inWindow,
  ) sync* {
    // A reminder up to 30 days ahead of next year's date can still land in
    // the window, so look two lunar years past the current one.
    for (var year = lunarYear; year <= lunarYear + 2; year++) {
      final lunar = _resolver.lunarDateIn(a.date, year);
      final solar = lunar == null ? null : _calendar.toSolar(lunar);
      if (lunar == null || solar == null) continue;
      final fireAt = _at(solar, a.remindDaysBefore, a.remindMinuteOfDay);
      if (!inWindow(fireAt)) continue;
      yield PlannedReminder(
        id: _stableId('a|${a.id}|${_ymd(solar)}'),
        kind: ReminderKind.anniversary,
        fireAt: fireAt,
        eventDay: solar,
        lunar: lunar,
        daysBefore: a.remindDaysBefore,
        anniversaryId: a.id,
        anniversaryName: a.name,
      );
    }
  }

  Iterable<PlannedReminder> _systemEvents(
    AppSettings settings,
    DateTime now,
    bool Function(DateTime) inWindow,
  ) sync* {
    final any =
        settings.remindFirstDay ||
        settings.remindFullMoon ||
        settings.remindFestivals;
    if (!any) return;
    for (var i = 0; i <= windowDays; i++) {
      final day = DateTime.utc(now.year, now.month, now.day + i);
      final lunar = _calendar.toLunar(day);
      final holiday = lunar == null ? null : _holidayFor(lunar, settings);
      final fireAt = _at(day, 0, systemEventMinuteOfDay);
      if (lunar == null || holiday == null || !inWindow(fireAt)) continue;
      yield PlannedReminder(
        id: _stableId('s|${_ymd(day)}'),
        kind: ReminderKind.systemEvent,
        fireAt: fireAt,
        eventDay: day,
        lunar: lunar,
        holiday: holiday,
      );
    }
  }

  /// The system event to remind about on [date], or `null`. A festival that
  /// also falls on mùng 1 or rằm is reminded once, under whichever switch is
  /// on.
  LunarHoliday? _holidayFor(LunarDate date, AppSettings settings) {
    final holiday = LunarHoliday.on(date);
    if (holiday is FestivalHoliday && settings.remindFestivals) return holiday;
    if (date.day == 1 && settings.remindFirstDay) {
      return FirstDayHoliday(date.month, date.isLeapMonth);
    }
    if (date.day == 15 && settings.remindFullMoon) {
      return FullMoonHoliday(date.month, date.isLeapMonth);
    }
    return null;
  }

  /// [day] minus [daysBefore] calendar days, at [minuteOfDay], as local
  /// wall-clock time.
  DateTime _at(DateTime day, int daysBefore, int minuteOfDay) => DateTime(
    day.year,
    day.month,
    day.day - daysBefore,
    minuteOfDay ~/ 60,
    minuteOfDay % 60,
  );

  /// [from] plus [days] calendar days at the same wall-clock time, so a
  /// daylight-saving change cannot move the window edge.
  DateTime _wallClock(DateTime from, int days) =>
      DateTime(from.year, from.month, from.day + days, from.hour, from.minute);

  int _byFireTime(PlannedReminder a, PlannedReminder b) {
    final byTime = a.fireAt.compareTo(b.fireAt);
    return byTime != 0 ? byTime : a.id.compareTo(b.id);
  }

  String _ymd(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}'
      '${d.day.toString().padLeft(2, '0')}';

  /// FNV-1a over [key], masked to a positive 31-bit int: stable across runs
  /// and platforms (unlike `hashCode`), and valid as a notification id.
  int _stableId(String key) {
    var hash = 0x811c9dc5;
    for (final unit in key.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash & 0x7fffffff;
  }
}

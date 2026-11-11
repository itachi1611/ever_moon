import 'package:equatable/equatable.dart';
import 'package:ever_moon/models/anniversary.dart';
import 'package:ever_moon/models/anniversary_date.dart';

/// Reminder lead times the form offers, in days; 0 means on the day
/// (plan 0005, D9). The table accepts 0 to 30, so the form must limit it.
const List<int> remindDaysChoices = [0, 1, 3, 7];

/// Largest lunar day the form accepts (ADR 0001: day 30 falls back to 29).
const int maxLunarDay = 30;

/// Largest lunar month number.
const int maxLunarMonth = 12;

/// A rule the form input breaks (UI-4).
enum AnniversaryFormError {
  /// The name is empty or only spaces.
  nameRequired,

  /// No lunar day, or one outside 1 to 30.
  dayInvalid,

  /// No lunar month, or one outside 1 to 12.
  monthInvalid,

  /// The reminder is on with a lead time outside [remindDaysChoices].
  daysBeforeInvalid,
}

/// The form input before it is saved.
///
/// Day and month may be missing while the user fills the form in; [errors]
/// reports what blocks saving. The death year is never validated (ADR 0001).
class AnniversaryDraft extends Equatable {
  /// Creates a draft; the defaults are those of a new anniversary.
  const AnniversaryDraft({
    this.name = '',
    this.lunarDay,
    this.lunarMonth,
    this.deathYear,
    this.diedInLeapMonth = false,
    this.reminderEnabled = true,
    this.remindDaysBefore = 0,
    this.remindMinuteOfDay = Anniversary.defaultRemindMinuteOfDay,
    this.address = '',
    this.note = '',
  });

  /// The draft that edits [anniversary].
  factory AnniversaryDraft.of(Anniversary anniversary) => AnniversaryDraft(
    name: anniversary.name,
    lunarDay: anniversary.date.lunarDay,
    lunarMonth: anniversary.date.lunarMonth,
    deathYear: anniversary.date.deathYear,
    diedInLeapMonth: anniversary.date.diedInLeapMonth,
    reminderEnabled: anniversary.reminderEnabled,
    remindDaysBefore: anniversary.remindDaysBefore,
    remindMinuteOfDay: anniversary.remindMinuteOfDay,
    address: anniversary.address ?? '',
    note: anniversary.note ?? '',
  );

  /// Name as typed.
  final String name;

  /// Lunar day, when chosen.
  final int? lunarDay;

  /// Lunar month number, when chosen.
  final int? lunarMonth;

  /// Lunar year of the death, when typed.
  final int? deathYear;

  /// The leap-month answer; the Cubit clears it when it cannot apply.
  final bool diedInLeapMonth;

  /// Whether a reminder is wanted.
  final bool reminderEnabled;

  /// Days before the anniversary the reminder fires.
  final int remindDaysBefore;

  /// Reminder time as minutes after local midnight.
  final int remindMinuteOfDay;

  /// Address as typed; empty means none.
  final String address;

  /// Note as typed; empty means none.
  final String note;

  /// What blocks saving; empty when the draft can be saved.
  Set<AnniversaryFormError> get errors => {
    if (name.trim().isEmpty) AnniversaryFormError.nameRequired,
    if (!_within(lunarDay, 1, maxLunarDay)) AnniversaryFormError.dayInvalid,
    if (!_within(lunarMonth, 1, maxLunarMonth))
      AnniversaryFormError.monthInvalid,
    if (reminderEnabled && !remindDaysChoices.contains(remindDaysBefore))
      AnniversaryFormError.daysBeforeInvalid,
  };

  /// The lunar date, or `null` while day or month is missing or invalid.
  AnniversaryDate? get date {
    final day = lunarDay;
    final month = lunarMonth;
    if (day == null || month == null) return null;
    if (!_within(day, 1, maxLunarDay) || !_within(month, 1, maxLunarMonth)) {
      return null;
    }
    return AnniversaryDate(
      lunarDay: day,
      lunarMonth: month,
      deathYear: deathYear,
      diedInLeapMonth: diedInLeapMonth,
    );
  }

  /// [address] trimmed, or `null` when blank.
  String? get addressOrNull => _blankToNull(address);

  /// [note] trimmed, or `null` when blank.
  String? get noteOrNull => _blankToNull(note);

  /// Copy with fields replaced. Day, month and year take a function so a
  /// caller can clear them: `copyWith(deathYear: () => null)`.
  AnniversaryDraft copyWith({
    String? name,
    int? Function()? lunarDay,
    int? Function()? lunarMonth,
    int? Function()? deathYear,
    bool? diedInLeapMonth,
    bool? reminderEnabled,
    int? remindDaysBefore,
    int? remindMinuteOfDay,
    String? address,
    String? note,
  }) => AnniversaryDraft(
    name: name ?? this.name,
    lunarDay: lunarDay == null ? this.lunarDay : lunarDay(),
    lunarMonth: lunarMonth == null ? this.lunarMonth : lunarMonth(),
    deathYear: deathYear == null ? this.deathYear : deathYear(),
    diedInLeapMonth: diedInLeapMonth ?? this.diedInLeapMonth,
    reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    remindDaysBefore: remindDaysBefore ?? this.remindDaysBefore,
    remindMinuteOfDay: remindMinuteOfDay ?? this.remindMinuteOfDay,
    address: address ?? this.address,
    note: note ?? this.note,
  );

  @override
  List<Object?> get props => [
    name,
    lunarDay,
    lunarMonth,
    deathYear,
    diedInLeapMonth,
    reminderEnabled,
    remindDaysBefore,
    remindMinuteOfDay,
    address,
    note,
  ];
}

bool _within(int? value, int min, int max) =>
    value != null && value >= min && value <= max;

String? _blankToNull(String text) {
  final trimmed = text.trim();
  return trimmed.isEmpty ? null : trimmed;
}

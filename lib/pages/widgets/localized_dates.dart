import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// [date] formatted with an intl [pattern] taken from the ARB file, in the
/// current locale, with the first letter capitalized ("Thứ Tư, …").
String formatLocalizedDate(
  BuildContext context,
  DateTime date,
  String pattern,
) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return toBeginningOfSentenceCase(DateFormat(pattern, locale).format(date));
}

/// [minuteOfDay] (minutes after midnight) as a time in the user's format.
String formatMinuteOfDay(BuildContext context, int minuteOfDay) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      timeOfDayOf(minuteOfDay),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );

/// [minuteOfDay] as a [TimeOfDay].
TimeOfDay timeOfDayOf(int minuteOfDay) => TimeOfDay(
  hour: minuteOfDay ~/ Duration.minutesPerHour,
  minute: minuteOfDay % Duration.minutesPerHour,
);

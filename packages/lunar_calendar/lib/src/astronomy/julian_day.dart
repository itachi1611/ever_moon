import 'delta_t.dart';

/// Julian Date of the J2000.0 epoch (2000-01-01 12:00 TT).
const double j2000 = 2451545.0;

/// Offset of Vietnamese civil time from UT, in hours.
///
/// Every day boundary in the calendar rules is taken in this zone, never in
/// UTC+8 (the Chinese calendar).
const int vietnamTimeZoneHours = 7;

/// Julian Day Number of 1970-01-01, the Dart [DateTime] epoch.
const int _unixEpochJdn = 2440588;

const int _millisecondsPerDay = 86400000;

/// Converts a Julian Ephemeris Day (TT) to a Julian Date in UT.
double jdeToJdUt(double jde) {
  final year = 2000.0 + (jde - j2000) / 365.25;
  return jde - deltaTSeconds(year) / 86400.0;
}

/// Julian Day Number of the civil day in UTC+7 that contains [jdUt].
int localDayNumber(double jdUt) =>
    (jdUt + 0.5 + vietnamTimeZoneHours / 24.0).floor();

/// Julian Day Number of a proleptic Gregorian calendar date.
int jdnFromCivil(int year, int month, int day) {
  final millis = DateTime.utc(year, month, day).millisecondsSinceEpoch;
  // Midnight UTC is an exact multiple of a day, so the division is exact.
  return millis ~/ _millisecondsPerDay + _unixEpochJdn;
}

/// Calendar date (as a UTC midnight [DateTime]) of a Julian Day Number.
DateTime civilFromJdn(int jdn) =>
    DateTime.utc(1970, 1, 1 + jdn - _unixEpochJdn);

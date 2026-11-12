import 'julian_day.dart';
import 'sun_longitude.dart';

/// Number of Newton-style refinement steps; each step gains roughly two
/// orders of magnitude, so eight is far below a second.
const int _refinementSteps = 8;

/// Julian Ephemeris Day (TT) when the Sun reaches longitude `index * 30`
/// degrees in Gregorian [year].
///
/// [index] runs from 0 (March equinox) to 11. Indexes 10 and 11 (300 and
/// 330 degrees) are the terms of January and February of [year], before its
/// March equinox. Index 9 (270 degrees) is the December solstice.
double principalTermJde(int year, int index) =>
    solarTermJde(year, index * 30.0);

/// Julian Ephemeris Day (TT) when the Sun reaches [longitude] degrees in
/// Gregorian [year] (any solar term, e.g. 15 for Thanh Minh).
///
/// Longitudes from 300 up to 360 are the terms of January and February of
/// [year], before its March equinox.
double solarTermJde(int year, double longitude) {
  final marchEquinoxGuess = jdnFromCivil(year, 3, 20) - 0.5;
  final offsetDegrees = longitude >= 300 ? longitude - 360.0 : longitude;
  var jde = marchEquinoxGuess + offsetDegrees / sunDegreesPerDay;
  for (var step = 0; step < _refinementSteps; step++) {
    final diff = (sunApparentLongitude(jde) - longitude + 180) % 360 - 180;
    jde -= diff / sunDegreesPerDay;
  }
  return jde;
}

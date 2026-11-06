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
double principalTermJde(int year, int index) {
  final target = index * 30.0;
  final marchEquinoxGuess = jdnFromCivil(year, 3, 20) - 0.5;
  final offsetDegrees = index >= 10 ? target - 360.0 : target;
  var jde = marchEquinoxGuess + offsetDegrees / sunDegreesPerDay;
  for (var step = 0; step < _refinementSteps; step++) {
    final diff = (sunApparentLongitude(jde) - target + 180) % 360 - 180;
    jde -= diff / sunDegreesPerDay;
  }
  return jde;
}

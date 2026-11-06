import 'dart:math' as math;

import 'julian_day.dart';
import 'vsop87_earth.dart';

/// Mean motion of the Sun in degrees per day, used to step towards a target
/// longitude.
const double sunDegreesPerDay = 0.9856474;

/// Apparent geocentric longitude of the Sun in degrees, in `[0, 360)`.
///
/// Truncated VSOP87 (Meeus, chapter 32) with the FK5 correction and the
/// low-accuracy aberration and nutation of chapters 25 and 22.
double sunApparentLongitude(double jde) {
  final tau = (jde - j2000) / 365250.0;
  final longitude = _radiansToDegrees(_heliocentricLongitude(tau)) + 180.0 -
      0.09033 / 3600.0;
  final radius = (_series(earthR0, tau) + _series(earthR1, tau) * tau) / 1e8;
  final aberration = -20.4898 / radius / 3600.0;
  return (longitude + aberration + _nutationInLongitude(tau * 10.0)) % 360.0;
}

double _heliocentricLongitude(double tau) {
  const series = [earthL0, earthL1, earthL2, earthL3, earthL4, earthL5];
  var sum = 0.0;
  var power = 1.0;
  for (final terms in series) {
    sum += _series(terms, tau) * power;
    power *= tau;
  }
  return sum / 1e8;
}

/// Nutation in longitude in degrees for [t] Julian centuries from J2000.
double _nutationInLongitude(double t) {
  final om = _degreesToRadians(125.04452 - 1934.136261 * t);
  final sunMean = _degreesToRadians(280.4665 + 36000.7698 * t);
  final moonMean = _degreesToRadians(218.3165 + 481267.8813 * t);
  return (-17.20 * math.sin(om) -
          1.32 * math.sin(2 * sunMean) -
          0.23 * math.sin(2 * moonMean) +
          0.21 * math.sin(2 * om)) /
      3600.0;
}

double _series(List<VsopTerm> terms, double tau) {
  var sum = 0.0;
  for (final (amplitude, phase, frequency) in terms) {
    sum += amplitude * math.cos(phase + frequency * tau);
  }
  return sum;
}

double _degreesToRadians(double degrees) => degrees * math.pi / 180.0;

double _radiansToDegrees(double radians) => radians * 180.0 / math.pi;

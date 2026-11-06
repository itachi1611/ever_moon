import 'dart:math' as math;

/// Periodic term of the new moon correction (Meeus, chapter 49).
///
/// The argument is `m*M + mp*M' + f*F + om*Omega`; [ePower] is the power of
/// the eccentricity factor E that multiplies the term.
typedef _PeriodicTerm = ({
  double coefficient,
  int ePower,
  int m,
  int mp,
  int f,
  int om,
});

const List<_PeriodicTerm> _periodicTerms = [
  (coefficient: -0.40720, ePower: 0, m: 0, mp: 1, f: 0, om: 0),
  (coefficient: 0.17241, ePower: 1, m: 1, mp: 0, f: 0, om: 0),
  (coefficient: 0.01608, ePower: 0, m: 0, mp: 2, f: 0, om: 0),
  (coefficient: 0.01039, ePower: 0, m: 0, mp: 0, f: 2, om: 0),
  (coefficient: 0.00739, ePower: 1, m: -1, mp: 1, f: 0, om: 0),
  (coefficient: -0.00514, ePower: 1, m: 1, mp: 1, f: 0, om: 0),
  (coefficient: 0.00208, ePower: 2, m: 2, mp: 0, f: 0, om: 0),
  (coefficient: -0.00111, ePower: 0, m: 0, mp: 1, f: -2, om: 0),
  (coefficient: -0.00057, ePower: 0, m: 0, mp: 1, f: 2, om: 0),
  (coefficient: 0.00056, ePower: 1, m: 1, mp: 2, f: 0, om: 0),
  (coefficient: -0.00042, ePower: 0, m: 0, mp: 3, f: 0, om: 0),
  (coefficient: 0.00042, ePower: 1, m: 1, mp: 0, f: 2, om: 0),
  (coefficient: 0.00038, ePower: 1, m: 1, mp: 0, f: -2, om: 0),
  (coefficient: -0.00024, ePower: 1, m: -1, mp: 2, f: 0, om: 0),
  (coefficient: -0.00017, ePower: 0, m: 0, mp: 0, f: 0, om: 1),
  (coefficient: -0.00007, ePower: 0, m: 2, mp: 1, f: 0, om: 0),
  (coefficient: 0.00004, ePower: 0, m: 0, mp: 2, f: -2, om: 0),
  (coefficient: 0.00004, ePower: 0, m: 3, mp: 0, f: 0, om: 0),
  (coefficient: 0.00003, ePower: 0, m: 1, mp: 1, f: -2, om: 0),
  (coefficient: 0.00003, ePower: 0, m: 0, mp: 2, f: 2, om: 0),
  (coefficient: -0.00003, ePower: 0, m: 1, mp: 1, f: 2, om: 0),
  (coefficient: 0.00003, ePower: 0, m: -1, mp: 1, f: 2, om: 0),
  (coefficient: -0.00002, ePower: 0, m: -1, mp: 1, f: -2, om: 0),
  (coefficient: -0.00002, ePower: 0, m: 1, mp: 3, f: 0, om: 0),
  (coefficient: 0.00002, ePower: 0, m: 0, mp: 4, f: 0, om: 0),
];

/// Additional planetary corrections A1 to A14: base angle and rate per
/// lunation in degrees, amplitude in days.
const List<({double base, double rate, double amplitude})> _planetary = [
  (base: 299.77, rate: 0.107408, amplitude: 0.000325),
  (base: 251.88, rate: 0.016321, amplitude: 0.000165),
  (base: 251.83, rate: 26.651886, amplitude: 0.000164),
  (base: 349.42, rate: 36.412478, amplitude: 0.000126),
  (base: 84.66, rate: 18.206239, amplitude: 0.00011),
  (base: 141.74, rate: 53.303771, amplitude: 0.000062),
  (base: 207.14, rate: 2.453732, amplitude: 0.00006),
  (base: 154.84, rate: 7.306860, amplitude: 0.000056),
  (base: 34.52, rate: 27.261239, amplitude: 0.000047),
  (base: 207.19, rate: 0.121824, amplitude: 0.000042),
  (base: 291.34, rate: 1.844379, amplitude: 0.00004),
  (base: 161.72, rate: 24.198154, amplitude: 0.000037),
  (base: 239.56, rate: 25.513099, amplitude: 0.000035),
  (base: 331.55, rate: 3.592518, amplitude: 0.000023),
];

/// Lunation number k = 0 is the first new moon of January 2000.
const double _lunationZeroJde = 2451550.09766;

/// Mean synodic month in days.
const double synodicMonth = 29.530588861;

/// Julian Ephemeris Day (TT) of the new moon with lunation number [k].
///
/// Meeus, "Astronomical Algorithms", chapter 49.
double newMoonJde(int k) {
  final t = k / 1236.85;
  final meanJde = _lunationZeroJde +
      synodicMonth * k +
      0.00015437 * t * t -
      0.000000150 * t * t * t +
      0.00000000073 * t * t * t * t;
  return meanJde + _periodicCorrection(k, t) + _planetaryCorrection(k, t);
}

/// Approximate lunation number of the new moon nearest to [jde].
int nearestLunation(double jde) =>
    ((jde - _lunationZeroJde) / synodicMonth).round();

double _periodicCorrection(int k, double t) {
  final e = 1 - 0.002516 * t - 0.0000074 * t * t;
  final m = _radians(2.5534 + 29.10535670 * k - 0.0000014 * t * t -
      0.00000011 * t * t * t);
  final mp = _radians(201.5643 + 385.81693528 * k + 0.0107582 * t * t +
      0.00001238 * t * t * t - 0.000000058 * t * t * t * t);
  final f = _radians(160.7108 + 390.67050284 * k - 0.0016118 * t * t -
      0.00000227 * t * t * t + 0.000000011 * t * t * t * t);
  final om = _radians(
      124.7746 - 1.56375588 * k + 0.0020672 * t * t + 0.00000215 * t * t * t);
  final eFactors = [1.0, e, e * e];
  var sum = 0.0;
  for (final term in _periodicTerms) {
    final angle = term.m * m + term.mp * mp + term.f * f + term.om * om;
    sum += term.coefficient * eFactors[term.ePower] * math.sin(angle);
  }
  return sum;
}

double _planetaryCorrection(int k, double t) {
  var sum = 0.0;
  for (final (index, term) in _planetary.indexed) {
    var angle = term.base + term.rate * k;
    // Only A1 carries a quadratic term in T.
    if (index == 0) angle -= 0.009173 * t * t;
    sum += term.amplitude * math.sin(_radians(angle));
  }
  return sum;
}

double _radians(double degrees) => degrees * math.pi / 180.0;

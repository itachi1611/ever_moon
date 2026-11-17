/// One polynomial piece of the Espenak and Meeus Delta T expressions (NASA).
///
/// Valid for decimal years below [untilYear]; the variable is
/// `year - originYear` and [coefficients] are in ascending powers.
typedef _DeltaTPiece = ({
  double untilYear,
  double originYear,
  List<double> coefficients,
});

const List<_DeltaTPiece> _pieces = [
  (
    untilYear: 1860,
    originYear: 1800,
    coefficients: [
      13.72,
      -0.332447,
      0.0068612,
      0.0041116,
      -0.00037436,
      0.0000121272,
      -0.0000001699,
      0.000000000875,
    ],
  ),
  (
    untilYear: 1900,
    originYear: 1860,
    coefficients: [
      7.62,
      0.5737,
      -0.251754,
      0.01680668,
      -0.0004473624,
      1 / 233174,
    ],
  ),
  (
    untilYear: 1920,
    originYear: 1900,
    coefficients: [-2.79, 1.494119, -0.0598939, 0.0061966, -0.000197],
  ),
  (
    untilYear: 1941,
    originYear: 1920,
    coefficients: [21.20, 0.84493, -0.076100, 0.0020936],
  ),
  (
    untilYear: 1961,
    originYear: 1950,
    coefficients: [29.07, 0.407, -1 / 233, 1 / 2547],
  ),
  (
    untilYear: 1986,
    originYear: 1975,
    coefficients: [45.45, 1.067, -1 / 260, -1 / 718],
  ),
  (
    untilYear: 2005,
    originYear: 2000,
    coefficients: [
      63.86,
      0.3345,
      -0.060374,
      0.0017275,
      0.000651814,
      0.00002373599,
    ],
  ),
  (untilYear: 2050, originYear: 2000, coefficients: [62.92, 0.32217, 0.005589]),
];

/// Delta T = TT - UT in seconds for a decimal [year].
///
/// Espenak and Meeus polynomial expressions; after 2050 the long-term
/// parabola is used, with the 2050 to 2150 linear correction.
double deltaTSeconds(double year) {
  for (final piece in _pieces) {
    if (year < piece.untilYear) {
      return _polynomial(year - piece.originYear, piece.coefficients);
    }
  }
  final u = (year - 1820) / 100;
  final parabola = -20 + 32 * u * u;
  return year < 2150 ? parabola - 0.5628 * (2150 - year) : parabola;
}

double _polynomial(double t, List<double> coefficients) {
  var result = 0.0;
  for (final c in coefficients.reversed) {
    result = result * t + c;
  }
  return result;
}

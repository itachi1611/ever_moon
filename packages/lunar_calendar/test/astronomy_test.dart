// Slice S3a: astronomy core against the independent oracle (plan 0001).
//
// The oracle uses the apparent Sun-Moon conjunction; the Meeus new moon
// formula we implement gives new moons about 35 seconds earlier, which is
// the author's convention (decision D7). Bounds mirror tests ORS-001 to 003.
import 'package:lunar_calendar/src/astronomy/julian_day.dart';
import 'package:lunar_calendar/src/astronomy/new_moon.dart';
import 'package:lunar_calendar/src/astronomy/principal_term.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

const double _secondsPerDay = 86400;

double _newMoonUt(int k) => jdeToJdUt(newMoonJde(k));

double _mean(List<double> values) =>
    values.reduce((a, b) => a + b) / values.length;

double _maxAbs(List<double> values) =>
    values.map((v) => v.abs()).reduce((a, b) => a > b ? a : b);

void main() {
  final events = loadFixture('oracle_events.json');
  final anchors = loadFixture('anchors.json');

  test(
    'LC-AST-1 new moons stay within 60 s of the oracle, mean about -35 s',
    () {
      final oracle = (events['new_moons_jd_ut'] as List<Object?>).cast<num>();
      final errors = [
        for (final jd in oracle)
          (_newMoonUt(nearestLunation(jd.toDouble())) - jd) * _secondsPerDay,
      ];
      expect(_maxAbs(errors), lessThan(60));
      expect(_mean(errors), closeTo(-35, 5));
    },
  );

  test('LC-AST-2 principal terms stay within 90 s of the oracle', () {
    final oracle = events['principal_terms_jd_ut'] as Map<String, Object?>;
    final errors = <double>[];
    for (final MapEntry(:key, :value) in oracle.entries) {
      final values = (value as List<Object?>).cast<num>();
      for (var index = 0; index < values.length; index++) {
        final ours = jdeToJdUt(principalTermJde(int.parse(key), index));
        errors.add((ours - values[index]) * _secondsPerDay);
      }
    }
    expect(_maxAbs(errors), lessThan(90));
    expect(_mean(errors).abs(), lessThan(5));
  });

  group('LC-AST-3 author published events', () {
    final authorEvents = (anchors['author_events'] as List<Object?>)
        .cast<Map<String, Object?>>();
    final newMoons = authorEvents.where((e) => e['kind'] == 'new_moon');

    test('new moons match the author within 5 s and on the Hanoi date', () {
      for (final event in newMoons) {
        final jd = julianDateOfUtc(event['gmt'] as String);
        final ours = _newMoonUt(nearestLunation(jd));
        expect(
          (ours - jd).abs() * _secondsPerDay,
          lessThan(5),
          reason: '$event',
        );
        final day = isoDate(civilFromJdn(localDayNumber(ours)));
        expect(day, event['hanoi_date'], reason: '$event');
      }
    });
  });
}

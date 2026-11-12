// Tết Thanh Minh (added 2026-11-12 for plan 0005): the UTC+7 day the Sun
// reaches 15 degrees, against the independent oracle fixture
// `oracle_solar_terms.json` (astronomy-engine), for Gregorian 1800 to 2199.
import 'package:lunar_calendar/lunar_calendar.dart';
import 'package:lunar_calendar/src/astronomy/julian_day.dart';
import 'package:lunar_calendar/src/astronomy/principal_term.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

const double _secondsPerDay = 86400;

/// Our principal terms are within 90 s of the oracle (LC-AST-2); a term
/// closer than this to midnight may fall on either day.
const double _boundarySeconds = 90;

void main() {
  final rows =
      (loadFixture('oracle_solar_terms.json')['thanh_minh']
              as Map<String, Object?>)
          .cast<String, Map<String, Object?>>();
  final calendar = VietnameseLunarCalendar();

  test('LC-ST-1 the 15 degree term stays within 90 s of the oracle', () {
    for (final MapEntry(:key, :value) in rows.entries) {
      final ours = jdeToJdUt(solarTermJde(int.parse(key), 15));
      final error = (ours - (value['jd_ut'] as num)) * _secondsPerDay;
      expect(error.abs(), lessThan(90), reason: 'year $key');
    }
  });

  test('LC-ST-2 Thanh Minh is on the oracle date every year', () {
    var compared = 0;
    for (final MapEntry(:key, :value) in rows.entries) {
      if ((value['margin_seconds'] as num) < _boundarySeconds) continue;
      final ours = calendar.thanhMinhOf(int.parse(key));
      expect(
        ours == null ? null : isoDate(ours),
        value['local_date'],
        reason: 'year $key',
      );
      compared++;
    }
    expect(compared, greaterThan(395));
  });

  test('LC-ST-3 no date outside the supported range', () {
    expect(calendar.thanhMinhOf(minLunarYear - 1), isNull);
    expect(calendar.thanhMinhOf(maxLunarYear + 1), isNull);
  });

  test('LC-ST-4 principal terms are unchanged by the generalization', () {
    for (final year in [1800, 1999, 2026, 2199]) {
      for (var index = 0; index < 12; index++) {
        expect(principalTermJde(year, index), solarTermJde(year, index * 30.0));
      }
    }
  });
}

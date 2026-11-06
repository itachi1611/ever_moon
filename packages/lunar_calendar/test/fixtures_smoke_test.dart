import 'package:lunar_calendar/lunar_calendar.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  group('oracle fixtures', () {
    late Map<String, Object?> months;

    setUpAll(() => months = loadFixture('oracle_months.json'));

    test('cover exactly the supported lunar year range', () {
      final meta = months['meta'] as Map<String, Object?>;
      expect(meta['first_lunar_year'], minLunarYear);
      expect(meta['last_lunar_year'], maxLunarYear);
      expect(meta['time_zone_hours'], 7);
    });

    test('month rows follow the declared row layout', () {
      final rows = months['months'] as List<Object?>;
      expect(rows, isNotEmpty);
      for (final row in rows) {
        expect(row, isA<List<Object?>>().having((r) => r.length, 'length', 5));
      }
    });

    test('every other fixture file decodes as a JSON object', () {
      for (final name in const [
        'anchors.json',
        'boundary_cases.json',
        'convention_differences.json',
        'oracle_events.json',
      ]) {
        expect(loadFixture(name), isNotEmpty, reason: name);
      }
    });
  });

  group('supported range', () {
    test('accepts the bounds and rejects years outside them', () {
      expect(isSupportedLunarYear(minLunarYear), isTrue);
      expect(isSupportedLunarYear(maxLunarYear), isTrue);
      expect(isSupportedLunarYear(minLunarYear - 1), isFalse);
      expect(isSupportedLunarYear(maxLunarYear + 1), isFalse);
    });
  });
}

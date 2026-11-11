// UI-7: both ARB files carry the same message keys, each exactly once.
// jsonDecode keeps only the last of two equal keys, so a duplicate would
// silently replace a string; this reads the raw lines instead.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

List<String> _messageKeys(String path) {
  final key = RegExp(r'^  "([a-z][A-Za-z0-9_]*)":', multiLine: true);
  return [
    for (final match in key.allMatches(File(path).readAsStringSync()))
      match.group(1) ?? '',
  ];
}

void main() {
  final en = _messageKeys('lib/l10n/intl_en.arb');
  final vi = _messageKeys('lib/l10n/intl_vi.arb');

  test('no message key appears twice', () {
    for (final keys in [en, vi]) {
      final seen = <String>{};
      final repeated = keys.where((k) => !seen.add(k)).toList();
      expect(repeated, isEmpty);
    }
  });

  test('weekday names list seven days in each language', () {
    final names = RegExp(r'"lb_weekdays_short": "([^"]*)"');
    for (final path in ['lib/l10n/intl_en.arb', 'lib/l10n/intl_vi.arb']) {
      final value = names.firstMatch(File(path).readAsStringSync())?.group(1);
      expect(value?.split(','), hasLength(DateTime.daysPerWeek));
    }
  });

  test('vi and en have the same message keys', () {
    expect(vi.toSet(), en.toSet());
  });
}

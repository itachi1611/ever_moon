import 'package:ever_moon/routing/routers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Routers', () {
    test('every path is absolute and unique', () {
      final paths = Routers.values.map((r) => r.routerPath).toList();
      expect(paths.every((p) => p.startsWith('/')), isTrue);
      expect(paths.toSet().length, paths.length);
    });

    test('every name is unique', () {
      final names = Routers.values.map((r) => r.routerName).toList();
      expect(names.toSet().length, names.length);
    });

    test('the add form path sits under home (D5)', () {
      expect(
        Routers.anniversaryNew.routerPath,
        '${Routers.home.routerPath}/new',
      );
    });

    test('removed template routes are gone', () {
      final names = Routers.values.map((r) => r.routerName).toSet();
      expect(
        names.intersection({'intro', 'service', 'explore', 'aiSupport'}),
        isEmpty,
      );
    });
  });
}

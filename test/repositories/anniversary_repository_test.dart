// Plans 0004 (ST-1 to ST-7) and 0005 U2a (ST-8, ST-10, ST-11): repository
// on an in-memory SQLite database.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:ever_moon/models/anniversary_date.dart';
import 'package:ever_moon/repositories/anniversary_repository.dart';
import 'package:ever_moon/services/lunar/anniversary_resolver.dart';
import 'package:ever_moon/storage/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../services/lunar/fake_lunar_calendar_service.dart';

void main() {
  late AppDatabase db;
  late DriftAnniversaryRepository repository;
  late DateTime now;
  var nextId = 0;

  const date = AnniversaryDate(lunarDay: 10, lunarMonth: 4);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    now = DateTime.utc(2026, 1, 1, 8);
    repository = DriftAnniversaryRepository(
      db,
      // The fake calendar repeats month 4 in 2001 only.
      AnniversaryResolver(
        FakeLunarCalendarService(leapMonths: const {2001: 4}),
      ),
      clock: () => now,
      newId: () => 'id-${nextId++}',
    );
  });

  tearDown(() => db.close());

  test(
    'ST-1 create assigns an ID and timestamps and can be read back',
    () async {
      final created = await repository.create(name: 'Ông nội', date: date);
      expect(created.id, isNotEmpty);
      expect(created.createdAt, now);
      expect(created.updatedAt, now);
      expect(await repository.findById(created.id), created);
      expect(await repository.watchAll().first, [created]);
    },
  );

  test('ST-2 update keeps identity and stamps updatedAt', () async {
    final created = await repository.create(name: 'Bà nội', date: date);
    now = now.add(const Duration(hours: 1));
    final edited = created.copyWith(
      name: 'Bà nội (bên nội)',
      note: () => 'Cúng chay',
      reminderEnabled: false,
    );
    final saved = await repository.update(edited);
    expect(saved.id, created.id);
    expect(saved.createdAt, created.createdAt);
    expect(saved.updatedAt, now);
    expect(await repository.findById(created.id), saved);
  });

  test('ST-2 update of a missing record throws', () async {
    final created = await repository.create(name: 'Cụ', date: date);
    await repository.delete(created.id);
    await expectLater(repository.update(created), throwsStateError);
  });

  test('ST-3 delete is soft', () async {
    final created = await repository.create(name: 'Chú', date: date);
    now = now.add(const Duration(minutes: 5));
    await repository.delete(created.id);
    expect(await repository.findById(created.id), isNull);
    expect(await repository.watchAll().first, isEmpty);
    final row = await (db.select(
      db.anniversaries,
    )..where((t) => t.id.equals(created.id))).getSingle();
    expect(row.deletedAt?.toUtc(), now);
    expect(row.updatedAt.toUtc(), now);
  });

  test('ST-4 leap flag is kept only when it can apply', () async {
    final valid = await repository.create(
      name: 'A',
      date: const AnniversaryDate(
        lunarDay: 1,
        lunarMonth: 4,
        deathYear: 2001,
        diedInLeapMonth: true,
      ),
    );
    final noYear = await repository.create(
      name: 'B',
      date: const AnniversaryDate(
        lunarDay: 1,
        lunarMonth: 4,
        diedInLeapMonth: true,
      ),
    );
    final noLeap = await repository.create(
      name: 'C',
      date: const AnniversaryDate(
        lunarDay: 1,
        lunarMonth: 4,
        deathYear: 2003,
        diedInLeapMonth: true,
      ),
    );
    expect((await repository.findById(valid.id))?.date.diedInLeapMonth, isTrue);
    expect(
      (await repository.findById(noYear.id))?.date.diedInLeapMonth,
      isFalse,
    );
    expect(
      (await repository.findById(noLeap.id))?.date.diedInLeapMonth,
      isFalse,
    );
  });

  test('ST-5 watchAll emits after each write', () async {
    final lengths = repository.watchAll().map((list) => list.length);
    final expectation = expectLater(lengths, emitsInOrder([0, 1, 2, 1]));
    await pumpEventQueue();
    final first = await repository.create(name: 'A', date: date);
    await pumpEventQueue();
    await repository.create(name: 'B', date: date);
    await pumpEventQueue();
    await repository.delete(first.id);
    await expectation;
  });

  test('ST-6 the table rejects an impossible lunar day or month', () async {
    Future<void> insert(int day, int month) => db
        .into(db.anniversaries)
        .insert(
          AnniversariesCompanion.insert(
            id: 'bad-$day-$month',
            name: 'X',
            lunarDay: day,
            lunarMonth: month,
            createdAt: now,
            updatedAt: now,
          ),
        );
    await expectLater(insert(31, 1), throwsA(isA<Exception>()));
    await expectLater(insert(0, 1), throwsA(isA<Exception>()));
    await expectLater(insert(1, 13), throwsA(isA<Exception>()));
  });

  test('timestamps are stored to the second in UTC', () async {
    now = DateTime.utc(2026, 1, 1, 8, 0, 0, 750);
    final created = await repository.create(name: 'A', date: date);
    expect(created.createdAt, DateTime.utc(2026, 1, 1, 8));
    expect(created.createdAt.isUtc, isTrue);
    expect(await repository.findById(created.id), created);
  });

  test('ST-8 schema v2 defaults: on the day, 07:00, no address', () async {
    expect(db.schemaVersion, 2);
    final created = await repository.create(name: 'Ông nội', date: date);
    final read = await repository.findById(created.id);
    expect(read?.reminderEnabled, isTrue);
    expect(read?.remindDaysBefore, 0);
    expect(read?.remindMinuteOfDay, 420);
    expect(read?.address, isNull);
  });

  test('ST-10 reminder settings and address round-trip', () async {
    final created = await repository.create(
      name: 'Bà nội',
      date: date,
      address: 'Nhà bác cả',
      note: 'Mời họ hàng',
      remindDaysBefore: 3,
      remindMinuteOfDay: 19 * 60,
    );
    expect(await repository.findById(created.id), created);
    now = now.add(const Duration(minutes: 1));
    final saved = await repository.update(
      created.copyWith(
        address: () => 'Nhà thờ họ',
        remindDaysBefore: 7,
        remindMinuteOfDay: 6 * 60,
      ),
    );
    final read = await repository.findById(created.id);
    expect(read, saved);
    expect(read?.address, 'Nhà thờ họ');
    expect(read?.remindDaysBefore, 7);
    expect(read?.remindMinuteOfDay, 360);
    final cleared = await repository.update(
      saved.copyWith(address: () => null, note: () => null),
    );
    expect(await repository.findById(created.id), cleared);
    expect(cleared.address, isNull);
    expect(cleared.note, isNull);
  });

  test('ST-11 the table rejects out-of-range reminder settings', () async {
    Future<void> insert(String id, int days, int minute) => db
        .into(db.anniversaries)
        .insert(
          AnniversariesCompanion.insert(
            id: id,
            name: 'X',
            lunarDay: 1,
            lunarMonth: 1,
            remindDaysBefore: Value(days),
            remindMinuteOfDay: Value(minute),
            createdAt: now,
            updatedAt: now,
          ),
        );
    await expectLater(insert('d', 31, 0), throwsA(isA<Exception>()));
    await expectLater(insert('n', -1, 0), throwsA(isA<Exception>()));
    await expectLater(insert('m', 0, 1440), throwsA(isA<Exception>()));
    await expectLater(insert('l', 0, -1), throwsA(isA<Exception>()));
    await insert('ok', 30, 1439);
  });
}

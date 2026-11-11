import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:ever_moon/models/anniversary.dart' show Anniversary;

import 'app_database.steps.dart';

part 'app_database.g.dart';

/// Global getter for the app's local database (ADR 0003).
///
/// Features do not use it directly; they go through repositories.
AppDatabase get appDatabase => AppDatabase.instance;

/// Anniversaries (giỗ) the user registered, one row per person.
///
/// Soft-deleted rows keep their ID so a later sync can propagate the delete.
@DataClassName('AnniversaryRow')
class Anniversaries extends Table {
  /// Client-generated UUID v4, stable across devices.
  TextColumn get id => text()();

  /// Name of the person the anniversary is held for.
  TextColumn get name => text()();

  /// Lunar day of the death, 1 to 30.
  // Drift's documented check pattern: the generator reads the getter
  // symbolically; it never recurses at run time.
  IntColumn get lunarDay =>
      integer()
      // ignore: recursive_getters
      .check(lunarDay.isBetweenValues(1, 30))();

  /// Lunar month of the death, 1 to 12.
  IntColumn get lunarMonth =>
      integer()
      // ignore: recursive_getters
      .check(lunarMonth.isBetweenValues(1, 12))();

  /// Lunar year of the death, when known.
  IntColumn get deathYear => integer().nullable()();

  /// Whether the death was in the leap month (normalized, ADR 0001).
  BoolColumn get diedInLeapMonth =>
      boolean().withDefault(const Constant(false))();

  /// Whether a reminder is scheduled for this anniversary.
  BoolColumn get reminderEnabled =>
      boolean().withDefault(const Constant(true))();

  /// Days before the anniversary the reminder fires; 0 means on the day.
  ///
  /// The form offers 0, 1, 3 and 7 (plan 0005, D9); the table allows up to
  /// 30 so a later option needs no migration.
  IntColumn get remindDaysBefore => integer()
      .withDefault(const Constant(0))
      // ignore: recursive_getters
      .check(remindDaysBefore.isBetweenValues(0, 30))();

  /// Reminder time as minutes after local midnight; 420 is 07:00.
  IntColumn get remindMinuteOfDay => integer()
      .withDefault(const Constant(Anniversary.defaultRemindMinuteOfDay))
      // ignore: recursive_getters
      .check(remindMinuteOfDay.isBetweenValues(0, 24 * 60 - 1))();

  /// Where the family gathers, when given.
  TextColumn get address => text().nullable()();

  /// Free-text note from the family.
  TextColumn get note => text().nullable()();

  /// Creation time, UTC.
  DateTimeColumn get createdAt => dateTime()();

  /// Last change time, UTC; sync resolves conflicts with it.
  DateTimeColumn get updatedAt => dateTime()();

  /// Soft-delete time, UTC; `null` while the record is live.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// The single on-device database.
@DriftDatabase(tables: [Anniversaries])
class AppDatabase extends _$AppDatabase {
  /// Opens the database on [executor]; tests pass an in-memory one.
  AppDatabase(super.executor);

  /// Process-wide instance backed by the platform's SQLite file.
  static final AppDatabase instance = AppDatabase(
    driftDatabase(name: 'evermoon'),
  );

  @override
  int get schemaVersion => 2;

  /// Schema history lives in `drift_schemas/`; each step is tested by
  /// `test/drift/app_database/migration_test.dart`.
  @override
  MigrationStrategy get migration =>
      MigrationStrategy(onUpgrade: stepByStep(from1To2: _from1To2));

  /// v2 (plan 0005, U2a): reminder days before and time, and an address.
  /// The column defaults fill existing rows: on the day, at 07:00.
  static Future<void> _from1To2(Migrator m, Schema2 schema) async {
    await m.addColumn(
      schema.anniversaries,
      schema.anniversaries.remindDaysBefore,
    );
    await m.addColumn(
      schema.anniversaries,
      schema.anniversaries.remindMinuteOfDay,
    );
    await m.addColumn(schema.anniversaries, schema.anniversaries.address);
  }
}

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

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
  IntColumn get lunarDay => integer()
      // ignore: recursive_getters
      .check(lunarDay.isBetweenValues(1, 30))();

  /// Lunar month of the death, 1 to 12.
  IntColumn get lunarMonth => integer()
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
  static final AppDatabase instance =
      AppDatabase(driftDatabase(name: 'evermoon'));

  @override
  int get schemaVersion => 1;
}

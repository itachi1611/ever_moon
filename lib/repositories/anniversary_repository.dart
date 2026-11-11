import 'package:drift/drift.dart';
import 'package:ever_moon/models/anniversary.dart';
import 'package:ever_moon/models/anniversary_date.dart';
import 'package:ever_moon/services/lunar/anniversary_resolver.dart';
import 'package:ever_moon/services/lunar/lunar_calendar_service.dart';
import 'package:ever_moon/storage/database/app_database.dart';
import 'package:uuid/uuid.dart';

/// Global getter for anniversary storage.
AnniversaryRepository get anniversaryRepository =>
    DriftAnniversaryRepository.instance;

/// Offline storage of anniversaries (plan 0004).
///
/// Every read excludes soft-deleted records. Every write normalizes the
/// leap-month flag so stored data follows ADR 0001.
abstract interface class AnniversaryRepository {
  /// Live list of all anniversaries, oldest first; emits after each write.
  Stream<List<Anniversary>> watchAll();

  /// The anniversary with [id], or `null` if missing or deleted.
  Future<Anniversary?> findById(String id);

  /// Stores a new anniversary with a fresh ID and timestamps.
  ///
  /// Reminder settings default to on the day at 07:00 (plan 0005, D9).
  Future<Anniversary> create({
    required String name,
    required AnniversaryDate date,
    String? note,
    String? address,
    bool reminderEnabled = true,
    int remindDaysBefore = 0,
    int remindMinuteOfDay = Anniversary.defaultRemindMinuteOfDay,
  });

  /// Saves the editable fields of [anniversary] and stamps `updatedAt`.
  ///
  /// Throws [StateError] if the record does not exist or was deleted.
  Future<Anniversary> update(Anniversary anniversary);

  /// Soft-deletes the anniversary with [id]; unknown IDs are ignored.
  Future<void> delete(String id);
}

/// [AnniversaryRepository] on the Drift [AppDatabase].
class DriftAnniversaryRepository implements AnniversaryRepository {
  /// Creates the repository; tests inject [clock] and [newId].
  DriftAnniversaryRepository(
    this._db,
    this._resolver, {
    DateTime Function()? clock,
    String Function()? newId,
  }) : _clock = clock ?? DateTime.now,
       _newId = newId ?? const Uuid().v4;

  /// Process-wide instance on the app database and lunar calendar.
  static final DriftAnniversaryRepository instance = DriftAnniversaryRepository(
    appDatabase,
    AnniversaryResolver(lunarCalendarService),
  );

  final AppDatabase _db;
  final AnniversaryResolver _resolver;
  final DateTime Function() _clock;
  final String Function() _newId;

  @override
  Stream<List<Anniversary>> watchAll() =>
      _liveQuery().watch().map((rows) => rows.map(_toEntity).toList());

  @override
  Future<Anniversary?> findById(String id) async {
    final query = _liveQuery()..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<Anniversary> create({
    required String name,
    required AnniversaryDate date,
    String? note,
    String? address,
    bool reminderEnabled = true,
    int remindDaysBefore = 0,
    int remindMinuteOfDay = Anniversary.defaultRemindMinuteOfDay,
  }) async {
    final now = _now();
    final draft = Anniversary(
      id: _newId(),
      name: name,
      date: date,
      note: note,
      address: address,
      reminderEnabled: reminderEnabled,
      remindDaysBefore: remindDaysBefore,
      remindMinuteOfDay: remindMinuteOfDay,
      createdAt: now,
      updatedAt: now,
    );
    final entity = _normalized(draft, updatedAt: now);
    await _db.into(_db.anniversaries).insert(_insertCompanion(entity));
    return entity;
  }

  @override
  Future<Anniversary> update(Anniversary anniversary) async {
    final saved = _normalized(anniversary, updatedAt: _now());
    final changed = await _liveUpdate(saved.id).write(_editCompanion(saved));
    if (changed == 0) {
      throw StateError('Anniversary ${saved.id} does not exist or was deleted');
    }
    return saved;
  }

  @override
  Future<void> delete(String id) async {
    final now = _now();
    await _liveUpdate(id).write(
      AnniversariesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  /// [entity] with the leap flag normalized (ADR 0001) and [updatedAt] set.
  Anniversary _normalized(Anniversary entity, {required DateTime updatedAt}) =>
      Anniversary(
        id: entity.id,
        name: entity.name,
        date: _resolver.normalize(entity.date),
        note: entity.note,
        address: entity.address,
        reminderEnabled: entity.reminderEnabled,
        remindDaysBefore: entity.remindDaysBefore,
        remindMinuteOfDay: entity.remindMinuteOfDay,
        createdAt: entity.createdAt,
        updatedAt: updatedAt,
      );

  /// UTC with whole seconds, the precision Drift stores, so a returned
  /// entity equals the one read back later.
  DateTime _now() {
    final now = _clock().toUtc();
    return DateTime.utc(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
      now.second,
    );
  }

  SimpleSelectStatement<$AnniversariesTable, AnniversaryRow> _liveQuery() =>
      _db.select(_db.anniversaries)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);

  UpdateStatement<$AnniversariesTable, AnniversaryRow> _liveUpdate(String id) =>
      _db.update(_db.anniversaries)
        ..where((t) => t.id.equals(id) & t.deletedAt.isNull());
}

Anniversary _toEntity(AnniversaryRow row) => Anniversary(
  id: row.id,
  name: row.name,
  date: AnniversaryDate(
    lunarDay: row.lunarDay,
    lunarMonth: row.lunarMonth,
    deathYear: row.deathYear,
    diedInLeapMonth: row.diedInLeapMonth,
  ),
  note: row.note,
  address: row.address,
  reminderEnabled: row.reminderEnabled,
  remindDaysBefore: row.remindDaysBefore,
  remindMinuteOfDay: row.remindMinuteOfDay,
  createdAt: row.createdAt.toUtc(),
  updatedAt: row.updatedAt.toUtc(),
);

AnniversariesCompanion _insertCompanion(Anniversary entity) =>
    AnniversariesCompanion.insert(
      id: entity.id,
      name: entity.name,
      lunarDay: entity.date.lunarDay,
      lunarMonth: entity.date.lunarMonth,
      deathYear: Value(entity.date.deathYear),
      diedInLeapMonth: Value(entity.date.diedInLeapMonth),
      reminderEnabled: Value(entity.reminderEnabled),
      remindDaysBefore: Value(entity.remindDaysBefore),
      remindMinuteOfDay: Value(entity.remindMinuteOfDay),
      address: Value(entity.address),
      note: Value(entity.note),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );

AnniversariesCompanion _editCompanion(Anniversary entity) =>
    AnniversariesCompanion(
      name: Value(entity.name),
      lunarDay: Value(entity.date.lunarDay),
      lunarMonth: Value(entity.date.lunarMonth),
      deathYear: Value(entity.date.deathYear),
      diedInLeapMonth: Value(entity.date.diedInLeapMonth),
      reminderEnabled: Value(entity.reminderEnabled),
      remindDaysBefore: Value(entity.remindDaysBefore),
      remindMinuteOfDay: Value(entity.remindMinuteOfDay),
      address: Value(entity.address),
      note: Value(entity.note),
      updatedAt: Value(entity.updatedAt),
    );

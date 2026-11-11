import 'package:ever_moon/models/anniversary.dart';
import 'package:ever_moon/models/anniversary_date.dart';
import 'package:ever_moon/repositories/anniversary_repository.dart';

/// In-memory repository that records writes; [failWrites] makes them throw.
class MemoryAnniversaryRepository implements AnniversaryRepository {
  /// Creates the store with [seed] records.
  MemoryAnniversaryRepository([List<Anniversary> seed = const []]) {
    for (final record in seed) {
      records[record.id] = record;
    }
  }

  /// Live records by ID.
  final Map<String, Anniversary> records = {};

  /// IDs passed to [delete], in order.
  final List<String> deleted = [];

  /// Whether create, update and delete throw.
  bool failWrites = false;

  int _nextId = 1;

  @override
  Stream<List<Anniversary>> watchAll() => Stream.value(records.values.toList());

  @override
  Future<Anniversary?> findById(String id) async => records[id];

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
    _guard();
    final record = Anniversary(
      id: 'new-${_nextId++}',
      name: name,
      date: date,
      note: note,
      address: address,
      reminderEnabled: reminderEnabled,
      remindDaysBefore: remindDaysBefore,
      remindMinuteOfDay: remindMinuteOfDay,
      createdAt: DateTime.utc(2002),
      updatedAt: DateTime.utc(2002),
    );
    return records[record.id] = record;
  }

  @override
  Future<Anniversary> update(Anniversary anniversary) async {
    _guard();
    if (!records.containsKey(anniversary.id)) throw StateError('missing');
    return records[anniversary.id] = anniversary;
  }

  @override
  Future<void> delete(String id) async {
    _guard();
    deleted.add(id);
    records.remove(id);
  }

  void _guard() {
    if (failWrites) throw StateError('disk full');
  }
}

/// A stored record with fixed timestamps.
Anniversary storedAnniversary({
  String id = 'a',
  String name = 'Bà nội',
  int day = 9,
  int month = 10,
  int? year,
  int remindDaysBefore = 1,
  String? address = 'Nhà bác cả',
}) => Anniversary(
  id: id,
  name: name,
  date: AnniversaryDate(lunarDay: day, lunarMonth: month, deathYear: year),
  address: address,
  remindDaysBefore: remindDaysBefore,
  createdAt: DateTime.utc(2001),
  updatedAt: DateTime.utc(2001),
);

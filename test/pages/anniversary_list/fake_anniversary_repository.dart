import 'dart:async';

import 'package:ever_moon/models/anniversary.dart';
import 'package:ever_moon/models/anniversary_date.dart';
import 'package:ever_moon/repositories/anniversary_repository.dart';

/// In-memory repository whose stream the test drives with [emit] or [fail].
class FakeAnniversaryRepository implements AnniversaryRepository {
  final _controller = StreamController<List<Anniversary>>.broadcast();

  /// Number of times [watchAll] was called (one per Cubit start).
  int watchCount = 0;

  /// Pushes a new list to every listener.
  void emit(List<Anniversary> items) => _controller.add(items);

  /// Pushes an error to every listener.
  void fail(Object error) => _controller.addError(error);

  @override
  Stream<List<Anniversary>> watchAll() {
    watchCount++;
    return _controller.stream;
  }

  @override
  Future<Anniversary?> findById(String id) async => null;

  @override
  Future<Anniversary> create({
    required String name,
    required AnniversaryDate date,
    String? note,
    String? address,
    bool reminderEnabled = true,
    int remindDaysBefore = 0,
    int remindMinuteOfDay = Anniversary.defaultRemindMinuteOfDay,
  }) => throw UnimplementedError();

  @override
  Future<Anniversary> update(Anniversary anniversary) =>
      throw UnimplementedError();

  @override
  Future<void> delete(String id) async {}
}

/// An anniversary with fixed timestamps for list tests.
Anniversary anniversary(String id, String name, int day, int month) =>
    Anniversary(
      id: id,
      name: name,
      date: AnniversaryDate(lunarDay: day, lunarMonth: month),
      createdAt: DateTime.utc(2001),
      updatedAt: DateTime.utc(2001),
    );

import 'dart:async';

import 'package:ever_moon/models/anniversary.dart';
import 'package:ever_moon/models/upcoming_anniversary.dart';
import 'package:ever_moon/repositories/anniversary_repository.dart';
import 'package:ever_moon/services/lunar/anniversary_resolver.dart';
import 'package:ever_moon/utils/app_logger.dart' as logger;
import 'package:flutter_bloc/flutter_bloc.dart';

import 'anniversary_list_state.dart';

/// Keeps the upcoming list in step with the stored anniversaries
/// (plan 0005, U2).
///
/// The list is read-only (D15): edits happen from the calendar.
class AnniversaryListCubit extends Cubit<AnniversaryListState> {
  /// Creates the Cubit; tests inject [today] to pin the current day.
  AnniversaryListCubit(
    this._repository,
    this._resolver, {
    DateTime Function()? today,
  }) : _today = today ?? DateTime.now,
       super(const AnniversaryListLoading());

  final AnniversaryRepository _repository;
  final AnniversaryResolver _resolver;
  final DateTime Function() _today;
  StreamSubscription<List<Anniversary>>? _subscription;
  List<Anniversary>? _latest;
  Timer? _midnight;

  /// Starts listening to the repository; calling it again restarts.
  ///
  /// The old subscription is cancelled without waiting: the new one is in
  /// place at once, so a retry tap takes effect in the same frame.
  void start() {
    final previous = _subscription;
    _forgetLatest();
    emit(const AnniversaryListLoading());
    _subscription = _repository.watchAll().listen(_onData, onError: _onError);
    if (previous != null) unawaited(previous.cancel());
  }

  /// Recomputes countdowns for the current day without re-reading storage.
  ///
  /// The page calls it when the app returns to the foreground; a timer calls
  /// it at local midnight, so "Hôm nay" and the day counts never go stale.
  void refresh() {
    final latest = _latest;
    if (latest != null) _onData(latest);
  }

  void _onData(List<Anniversary> anniversaries) {
    _latest = anniversaries;
    _scheduleMidnight();
    // Empty only when nothing is stored; records outside the supported
    // range still count as data.
    emit(
      anniversaries.isEmpty
          ? const AnniversaryListEmpty()
          : AnniversaryListLoaded(upcomingOf(anniversaries)),
    );
  }

  void _scheduleMidnight() {
    _midnight?.cancel();
    final now = _today();
    final next = DateTime(now.year, now.month, now.day + 1);
    _midnight = Timer(next.difference(now), refresh);
  }

  void _onError(Object error, StackTrace stackTrace) {
    logger.err('Upcoming anniversaries could not be read', error, stackTrace);
    _forgetLatest();
    emit(const AnniversaryListFailure());
  }

  /// Drops the cached records so a resume or midnight refresh cannot replace
  /// the loading or failure state with stale data.
  void _forgetLatest() {
    _latest = null;
    _midnight?.cancel();
  }

  /// [anniversaries] with their next holding, soonest first, ties by name.
  ///
  /// A record outside the supported lunar range has no next holding and is
  /// left out rather than shown with a wrong date.
  List<UpcomingAnniversary> upcomingOf(List<Anniversary> anniversaries) {
    final now = _today();
    final day = DateTime.utc(now.year, now.month, now.day);
    final items = [
      for (final anniversary in anniversaries) ?_entry(anniversary, day),
    ]..sort(_compare);
    return items;
  }

  UpcomingAnniversary? _entry(Anniversary anniversary, DateTime day) {
    final holding = _resolver.nextHolding(anniversary.date, day);
    if (holding == null) return null;
    return UpcomingAnniversary(
      anniversary: anniversary,
      lunarDate: holding.lunar,
      solarDate: holding.solar,
      daysLeft: holding.solar.difference(day).inDays,
    );
  }

  static int _compare(UpcomingAnniversary a, UpcomingAnniversary b) {
    final byDate = a.solarDate.compareTo(b.solarDate);
    return byDate != 0
        ? byDate
        : a.anniversary.name.compareTo(b.anniversary.name);
  }

  @override
  Future<void> close() async {
    _midnight?.cancel();
    await _subscription?.cancel();
    return super.close();
  }
}

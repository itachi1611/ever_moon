import 'dart:async';

import 'package:ever_moon/models/anniversary.dart';
import 'package:ever_moon/repositories/anniversary_repository.dart';
import 'package:ever_moon/services/lunar/anniversary_resolver.dart';
import 'package:ever_moon/services/lunar/lunar_calendar_service.dart';
import 'package:ever_moon/utils/app_logger.dart' as logger;
import 'package:flutter_bloc/flutter_bloc.dart';

import 'shell_state.dart';

/// Feeds the drawer header: today's lunar date and the number of
/// anniversaries held today (plan 0005, U4).
///
/// The shell calls [refresh] whenever the drawer opens, so the dates are
/// right even after midnight without a timer.
class ShellCubit extends Cubit<ShellState> {
  /// Creates the Cubit; tests inject [today].
  ShellCubit(
    this._repository,
    this._calendar,
    this._resolver, {
    DateTime Function()? today,
  }) : _today = today ?? DateTime.now,
       super(const ShellStarting());

  final AnniversaryRepository _repository;
  final LunarCalendarService _calendar;
  final AnniversaryResolver _resolver;
  final DateTime Function() _today;
  StreamSubscription<List<Anniversary>>? _subscription;
  List<Anniversary> _latest = const [];

  /// Starts following the stored anniversaries.
  void start() {
    _subscription = _repository.watchAll().listen((items) {
      _latest = items;
      refresh();
    }, onError: _onError);
    refresh();
  }

  /// Recomputes today's dates and count.
  void refresh() {
    final now = _today();
    final day = DateTime.utc(now.year, now.month, now.day);
    emit(
      ShellReady(
        solarToday: day,
        lunarToday: _calendar.toLunar(day),
        todayCount: _latest.where((a) => _isToday(a, day)).length,
      ),
    );
  }

  /// The header still shows today's date; the count drops to 0 rather than
  /// showing a stale number.
  void _onError(Object error, StackTrace stackTrace) {
    logger.err('Drawer could not read anniversaries', error, stackTrace);
    _latest = const [];
    refresh();
  }

  bool _isToday(Anniversary anniversary, DateTime day) =>
      _resolver.nextOccurrence(anniversary.date, day) == day;

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

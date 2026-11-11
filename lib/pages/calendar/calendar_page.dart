import 'package:ever_moon/common/app_dimensions.dart';
import 'package:ever_moon/generated/l10n.dart';
import 'package:ever_moon/models/anniversary.dart';
import 'package:ever_moon/pages/anniversary_list/widgets/list_status_views.dart';
import 'package:ever_moon/pages/shell/shell_scope.dart';
import 'package:ever_moon/pages/widgets/delete_anniversary_dialog.dart';
import 'package:ever_moon/repositories/anniversary_repository.dart';
import 'package:ever_moon/services/lunar/anniversary_resolver.dart';
import 'package:ever_moon/services/lunar/lunar_calendar_service.dart';
import 'package:ever_moon/utils/app_logger.dart' as logger;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'calendar_builder.dart';
import 'calendar_cubit.dart';
import 'calendar_state.dart';
import 'widgets/calendar_header.dart';
import 'widgets/event_items.dart';
import 'widgets/month_view.dart';
import 'widgets/week_view.dart';
import 'widgets/year_view.dart';

/// The calendar tab: year, month and week views with the anniversaries and
/// holidays on them (plan 0005, U5). Edit and delete live here (D15).
class CalendarPage extends StatefulWidget {
  /// Creates the page; tests pass [repository], [calendar] and [today].
  const CalendarPage({
    super.key,
    required this.onAdd,
    required this.onEdit,
    this.repository,
    this.calendar,
    this.today,
  });

  /// Opens the empty add form (D12).
  final VoidCallback onAdd;

  /// Opens the edit form for the anniversary with this ID.
  final ValueChanged<String> onEdit;

  /// Storage; the app-wide repository when `null`.
  final AnniversaryRepository? repository;

  /// Lunar calendar; the app's one when `null`.
  final LunarCalendarService? calendar;

  /// Clock for "today"; the device clock when `null`.
  final DateTime Function()? today;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late final CalendarCubit _cubit;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    final calendar = widget.calendar ?? lunarCalendarService;
    _cubit = CalendarCubit(
      widget.repository ?? anniversaryRepository,
      CalendarBuilder(calendar, AnniversaryResolver(calendar)),
      today: widget.today,
    )..start();
    // The day may have changed while the app was in the background.
    _lifecycle = AppLifecycleListener(onResume: _cubit.refresh);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _cubit.close();
    super.dispose();
  }

  /// Asks, deletes, and reports a failure; called from a swipe or TalkBack
  /// action, so nothing awaits it and every error is handled here.
  Future<void> _delete(Anniversary anniversary) async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = S.of(context).lb_delete_failed;
    try {
      if (!await confirmDeleteAnniversary(context, anniversary.name)) return;
      if (await _cubit.delete(anniversary.id)) return;
    } catch (error, stackTrace) {
      logger.err('Calendar delete flow failed', error, stackTrace);
    }
    messenger.showSnackBar(SnackBar(content: Text(failed)));
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _cubit,
    child: Scaffold(
      appBar: AppBar(
        leading: MenuButton.maybe(context),
        title: Text(S.of(context).lb_nav_calendar),
      ),
      body: _CalendarBody(
        actions: CalendarActions(
          edit: (anniversary) => widget.onEdit(anniversary.id),
          delete: _delete,
        ),
        onRetry: _cubit.start,
      ),
      floatingActionButton: _AddFab(onPressed: widget.onAdd),
    ),
  );
}

class _CalendarBody extends StatelessWidget {
  const _CalendarBody({required this.actions, required this.onRetry});

  final CalendarActions actions;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<CalendarCubit, CalendarState>(
        builder: (context, state) => switch (state) {
          CalendarLoading() => const Center(child: CircularProgressIndicator()),
          CalendarFailure() => FailedUpcomingView(onRetry: onRetry),
          CalendarReady() => Column(
            children: [
              CalendarHeader(state: state),
              Expanded(
                child: _PeriodView(state: state, actions: actions),
              ),
            ],
          ),
        },
      );
}

class _PeriodView extends StatelessWidget {
  const _PeriodView({required this.state, required this.actions});

  /// Room under the content so the FAB never covers the last item.
  static const _fabRoom = AppDimensions.fabSize + AppDimensions.space16;

  final CalendarReady state;
  final CalendarActions actions;

  @override
  Widget build(BuildContext context) => switch (state.period) {
    YearPeriod() && final p => YearView(
      state: state,
      period: p,
      bottomPadding: _fabRoom,
    ),
    MonthPeriod() && final p => MonthView(
      state: state,
      period: p,
      actions: actions,
      bottomPadding: _fabRoom,
    ),
    WeekPeriod() && final p => WeekView(
      state: state,
      period: p,
      actions: actions,
      bottomPadding: _fabRoom,
    ),
  };
}

class _AddFab extends StatelessWidget {
  const _AddFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      icon: const Icon(Icons.add),
      label: Text(S.of(context).lb_add),
      tooltip: S.of(context).lb_add_anniversary,
    );
  }
}

import 'package:ever_moon/common/app_dimensions.dart';
import 'package:ever_moon/generated/l10n.dart';
import 'package:ever_moon/pages/shell/shell_scope.dart';
import 'package:ever_moon/pages/widgets/add_anniversary_launcher.dart';
import 'package:ever_moon/repositories/anniversary_repository.dart';
import 'package:ever_moon/services/lunar/anniversary_resolver.dart';
import 'package:ever_moon/services/lunar/lunar_calendar_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'anniversary_list_cubit.dart';
import 'anniversary_list_state.dart';
import 'widgets/list_status_views.dart';
import 'widgets/upcoming_list_view.dart';

/// Upcoming anniversaries, soonest first (plan 0005, U2). Replaces the
/// template Home tab.
///
/// Owns its [AnniversaryListCubit]. The route passes [addForm] to build the
/// add form its button opens; the menu button appears inside the shell.
class AnniversaryListPage extends StatefulWidget {
  /// Creates the page; tests pass a [repository], [resolver] and [today].
  const AnniversaryListPage({
    super.key,
    this.addForm,
    this.repository,
    this.resolver,
    this.today,
  });

  /// Builds the add form; no add action is shown while it is `null`.
  final AddFormBuilder? addForm;

  /// Storage; the app-wide repository when `null`.
  final AnniversaryRepository? repository;

  /// Lunar rules; the app's resolver when `null`.
  final AnniversaryResolver? resolver;

  /// Clock for "today"; the device clock when `null`.
  final DateTime Function()? today;

  @override
  State<AnniversaryListPage> createState() => _AnniversaryListPageState();
}

class _AnniversaryListPageState extends State<AnniversaryListPage> {
  late final AnniversaryListCubit _cubit;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _cubit = AnniversaryListCubit(
      widget.repository ?? anniversaryRepository,
      widget.resolver ?? AnniversaryResolver(lunarCalendarService),
      today: widget.today,
    );
    _cubit.start();
    // The day may have changed while the app was in the background.
    _lifecycle = AppLifecycleListener(onResume: _cubit.refresh);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final addForm = widget.addForm;
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          leading: MenuButton.maybe(context),
          title: Text(S.of(context).lb_upcoming_title),
        ),
        body: _ListBody(addForm: addForm, onRetry: _cubit.start),
        floatingActionButton: addForm == null
            ? null
            : AddAnniversaryFab(formBuilder: addForm),
      ),
    );
  }
}

class _ListBody extends StatelessWidget {
  const _ListBody({required this.addForm, required this.onRetry});

  final AddFormBuilder? addForm;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AnniversaryListCubit, AnniversaryListState>(
        builder: (context, state) => switch (state) {
          AnniversaryListLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          AnniversaryListEmpty() => EmptyUpcomingView(addForm: addForm),
          AnniversaryListLoaded() => UpcomingListView(
            today: state.today,
            upcoming: state.upcoming,
            // Room for the add button so the last card can scroll clear of it.
            bottomPadding: addForm == null
                ? 0
                : AppDimensions.fabSize + AppDimensions.space16,
          ),
          AnniversaryListFailure() => FailedUpcomingView(onRetry: onRetry),
        },
      );
}

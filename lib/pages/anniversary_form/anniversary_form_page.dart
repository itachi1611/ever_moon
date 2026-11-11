import 'dart:async';

import 'package:ever_moon/generated/l10n.dart';
import 'package:ever_moon/repositories/anniversary_repository.dart';
import 'package:ever_moon/services/lunar/anniversary_resolver.dart';
import 'package:ever_moon/services/lunar/lunar_calendar_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'anniversary_form_cubit.dart';
import 'anniversary_form_state.dart';
import 'widgets/anniversary_form_view.dart';

/// Add or edit one anniversary (plan 0005, U3).
///
/// Adds when [anniversaryId] is `null`, otherwise edits that record and
/// offers Delete. Calls [onClose] after a save or delete; the route decides
/// where to go back to.
class AnniversaryFormPage extends StatefulWidget {
  /// Creates the page; tests pass a [repository], [resolver] and [today].
  const AnniversaryFormPage({
    super.key,
    required this.onClose,
    this.anniversaryId,
    this.repository,
    this.resolver,
    this.today,
  });

  /// Record to edit; `null` adds a new one.
  final String? anniversaryId;

  /// Leaves the form after it saved or deleted.
  final VoidCallback onClose;

  /// Storage; the app-wide repository when `null`.
  final AnniversaryRepository? repository;

  /// Lunar rules; the app's resolver when `null`.
  final AnniversaryResolver? resolver;

  /// Clock for "today"; the device clock when `null`.
  final DateTime Function()? today;

  @override
  State<AnniversaryFormPage> createState() => _AnniversaryFormPageState();
}

class _AnniversaryFormPageState extends State<AnniversaryFormPage> {
  late final AnniversaryFormCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = AnniversaryFormCubit(
      widget.repository ?? anniversaryRepository,
      widget.resolver ?? AnniversaryResolver(lunarCalendarService),
      today: widget.today,
    );
    unawaited(_cubit.load(widget.anniversaryId));
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<AnniversaryFormCubit, AnniversaryFormState>(
        listenWhen: _shouldReact,
        listener: _react,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              widget.anniversaryId == null
                  ? s.lb_add_anniversary
                  : s.lb_form_title_edit,
            ),
          ),
          body: const _FormBody(),
        ),
      ),
    );
  }

  static bool _shouldReact(
    AnniversaryFormState previous,
    AnniversaryFormState next,
  ) => switch (next) {
    AnniversaryFormDone() => true,
    AnniversaryFormEditing(:final notice) =>
      notice != AnniversaryFormNotice.none &&
          (previous is! AnniversaryFormEditing || previous.notice != notice),
    _ => false,
  };

  void _react(BuildContext context, AnniversaryFormState state) {
    if (state is AnniversaryFormDone) return widget.onClose();
    if (state is! AnniversaryFormEditing) return;
    final s = S.of(context);
    final message = state.notice == AnniversaryFormNotice.deleteFailed
        ? s.lb_delete_failed
        : s.lb_save_failed;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _FormBody extends StatelessWidget {
  const _FormBody();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AnniversaryFormCubit, AnniversaryFormState>(
        builder: (context, state) => switch (state) {
          AnniversaryFormEditing() => AnniversaryFormView(state: state),
          AnniversaryFormUnavailable() => Center(
            child: Text(S.of(context).lb_form_unavailable),
          ),
          AnniversaryFormLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          // The route is closing; nothing new to show.
          AnniversaryFormDone() => const SizedBox.shrink(),
        },
      );
}

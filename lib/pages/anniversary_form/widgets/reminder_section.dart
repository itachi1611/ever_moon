import 'package:ever_moon/common/app_dimensions.dart';
import 'package:ever_moon/generated/l10n.dart';
import 'package:ever_moon/pages/widgets/localized_dates.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../anniversary_draft.dart';
import '../anniversary_form_cubit.dart';

/// Reminder switch, lead time and time of day (UI-10, D9).
///
/// Turning the reminder off hides the details but keeps their values.
class ReminderSection extends StatelessWidget {
  /// Creates the section for [draft].
  const ReminderSection({
    super.key,
    required this.draft,
    required this.nextSolar,
    required this.showDaysError,
  });

  /// Current input.
  final AnniversaryDraft draft;

  /// Next holding (UTC midnight), when the date is complete.
  final DateTime? nextSolar;

  /// Whether to flag the lead time (a stored value the form does not offer).
  final bool showDaysError;

  @override
  Widget build(BuildContext context) => _SectionFrame(
    children: [
      _ReminderSwitch(enabled: draft.reminderEnabled),
      if (draft.reminderEnabled)
        _ReminderDetails(
          draft: draft,
          nextSolar: nextSolar,
          showDaysError: showDaysError,
        ),
    ],
  );
}

class _SectionFrame extends StatelessWidget {
  const _SectionFrame({required this.children});

  final List<Widget> children;

  @override
  // A Material, not a DecoratedBox, so the tiles inside show their ripple.
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    borderRadius: BorderRadius.circular(AppDimensions.cornerLarge),
    child: Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppDimensions.space16,
        AppDimensions.space4,
        AppDimensions.space16,
        AppDimensions.space16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ),
  );
}

class _ReminderSwitch extends StatelessWidget {
  const _ReminderSwitch({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    value: enabled,
    onChanged: context.read<AnniversaryFormCubit>().changeReminder,
    title: Text(
      S.of(context).lb_remind_me,
      style: Theme.of(
        context,
      ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
    ),
  );
}

class _ReminderDetails extends StatelessWidget {
  const _ReminderDetails({
    required this.draft,
    required this.nextSolar,
    required this.showDaysError,
  });

  final AnniversaryDraft draft;
  final DateTime? nextSolar;
  final bool showDaysError;

  @override
  Widget build(BuildContext context) {
    final next = nextSolar;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppDimensions.space16,
      children: [
        _LeadChoices(
          selected: draft.remindDaysBefore,
          showError: showDaysError,
        ),
        _ReminderTimeButton(minuteOfDay: draft.remindMinuteOfDay),
        if (next != null && !showDaysError)
          _ReminderSummary(draft: draft, nextSolar: next),
      ],
    );
  }
}

class _LeadChoices extends StatelessWidget {
  const _LeadChoices({required this.selected, required this.showError});

  final int selected;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppDimensions.space8,
      children: [
        Text(
          s.lb_remind_before,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        _LeadChips(selected: selected),
        if (showError)
          Text(
            s.er_days_before,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
      ],
    );
  }
}

class _LeadChips extends StatelessWidget {
  const _LeadChips({required this.selected});

  final int selected;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cubit = context.read<AnniversaryFormCubit>();
    return Wrap(
      spacing: AppDimensions.space8,
      runSpacing: AppDimensions.space8,
      children: [
        for (final days in remindDaysChoices)
          ChoiceChip(
            label: Text(
              days == 0 ? s.lb_remind_on_day : s.lb_remind_days_before(days),
            ),
            selected: days == selected,
            onSelected: (_) => cubit.changeDaysBefore(days),
          ),
      ],
    );
  }
}

class _ReminderTimeButton extends StatelessWidget {
  const _ReminderTimeButton({required this.minuteOfDay});

  final int minuteOfDay;

  Future<void> _pick(BuildContext context) async {
    final cubit = context.read<AnniversaryFormCubit>();
    final picked = await showTimePicker(
      context: context,
      initialTime: timeOfDayOf(minuteOfDay),
    );
    if (picked == null) return;
    cubit.changeReminderTime(
      picked.hour * Duration.minutesPerHour + picked.minute,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: () => _pick(context),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(AppDimensions.cornerExtraSmall),
      ),
      leading: const Icon(Icons.schedule),
      title: Text(
        S.of(context).lb_remind_time,
        style: theme.textTheme.bodySmall,
      ),
      subtitle: Text(
        formatMinuteOfDay(context, minuteOfDay),
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class _ReminderSummary extends StatelessWidget {
  const _ReminderSummary({required this.draft, required this.nextSolar});

  final AnniversaryDraft draft;
  final DateTime nextSolar;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final days = draft.remindDaysBefore;
    final time = formatMinuteOfDay(context, draft.remindMinuteOfDay);
    final date = formatLocalizedDate(
      context,
      nextSolar.subtract(Duration(days: days)),
      s.lb_short_date_pattern,
    );
    final theme = Theme.of(context);
    return Text(
      days == 0
          ? s.lb_remind_summary_on_day(time, date)
          : s.lb_remind_summary_before(time, days, date),
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

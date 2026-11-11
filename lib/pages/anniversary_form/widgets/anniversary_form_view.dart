import 'package:ever_moon/common/app_dimensions.dart';
import 'package:ever_moon/generated/l10n.dart';
import 'package:ever_moon/pages/widgets/localized_dates.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../anniversary_draft.dart';
import '../anniversary_form_cubit.dart';
import '../anniversary_form_state.dart';
import 'form_action_bar.dart';
import 'labeled_text_field.dart';
import 'leap_month_card.dart';
import 'lunar_date_fields.dart';
import 'reminder_section.dart';

/// The form body while editing: fields above, Save and Delete below.
///
/// Owns the text controllers; their first text comes from the draft the
/// form opened with, and every edit goes to the Cubit.
class AnniversaryFormView extends StatefulWidget {
  /// Creates the view for [state].
  const AnniversaryFormView({super.key, required this.state});

  /// Current editing state.
  final AnniversaryFormEditing state;

  @override
  State<AnniversaryFormView> createState() => _AnniversaryFormViewState();
}

class _AnniversaryFormViewState extends State<AnniversaryFormView> {
  late final _FieldControllers _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = _FieldControllers(widget.state.draft);
  }

  @override
  void dispose() {
    _controllers.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppDimensions.space16,
              children: [
                _DateGroup(state: state, controllers: _controllers),
                _ReminderAndNotesGroup(state: state, controllers: _controllers),
              ],
            ),
          ),
        ),
        FormActionBar(isEdit: state.isEdit, busy: state.busy),
      ],
    );
  }
}

/// Text controllers of the free-text fields.
class _FieldControllers {
  _FieldControllers(AnniversaryDraft draft)
    : name = TextEditingController(text: draft.name),
      year = TextEditingController(text: draft.deathYear?.toString() ?? ''),
      address = TextEditingController(text: draft.address),
      note = TextEditingController(text: draft.note);

  final TextEditingController name;
  final TextEditingController year;
  final TextEditingController address;
  final TextEditingController note;

  void dispose() {
    name.dispose();
    year.dispose();
    address.dispose();
    note.dispose();
  }
}

/// Name, lunar date, death year, leap question and next holding.
class _DateGroup extends StatelessWidget {
  const _DateGroup({required this.state, required this.controllers});

  final AnniversaryFormEditing state;
  final _FieldControllers controllers;

  @override
  Widget build(BuildContext context) {
    final errors = state.visibleErrors;
    final draft = state.draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppDimensions.space16,
      children: [
        _NameField(controller: controllers.name, errors: errors),
        LunarDateFields(
          day: draft.lunarDay,
          month: draft.lunarMonth,
          errors: errors,
        ),
        _YearField(controller: controllers.year),
        _LeapQuestion(state: state),
        _NextHoldingNote(state: state),
      ],
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({required this.controller, required this.errors});

  final TextEditingController controller;
  final Set<AnniversaryFormError> errors;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return LabeledTextField(
      label: s.lb_field_name,
      controller: controller,
      onChanged: context.read<AnniversaryFormCubit>().changeName,
      error: errors.contains(AnniversaryFormError.nameRequired)
          ? s.er_name_required
          : null,
      options: const FieldOptions(capitalization: TextCapitalization.words),
    );
  }
}

class _YearField extends StatelessWidget {
  const _YearField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cubit = context.read<AnniversaryFormCubit>();
    return LabeledTextField(
      label: s.lb_field_year,
      controller: controller,
      // Never validated (ADR 0001): an empty or partial year means unknown.
      onChanged: (text) => cubit.changeYear(int.tryParse(text)),
      options: FieldOptions(
        optional: true,
        hint: s.lb_year_hint,
        helper: s.lb_year_help,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4),
        ],
      ),
    );
  }
}

class _LeapQuestion extends StatelessWidget {
  const _LeapQuestion({required this.state});

  final AnniversaryFormEditing state;

  @override
  Widget build(BuildContext context) {
    final month = state.draft.lunarMonth;
    if (!state.canBeLeapMonth || month == null) return const SizedBox.shrink();
    return LeapMonthCard(
      month: month,
      value: state.draft.diedInLeapMonth,
      onChanged: context.read<AnniversaryFormCubit>().changeLeapMonth,
    );
  }
}

class _NextHoldingNote extends StatelessWidget {
  const _NextHoldingNote({required this.state});

  final AnniversaryFormEditing state;

  @override
  Widget build(BuildContext context) {
    final solar = state.nextHolding?.solar;
    if (solar == null) return const SizedBox.shrink();
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;
    final date = formatLocalizedDate(context, solar, s.lb_solar_date_pattern);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(AppDimensions.cornerMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space12),
        child: _IconLine(text: s.lb_next_holding(date)),
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Row(
    spacing: AppDimensions.space12,
    children: [
      Icon(
        Icons.event_outlined,
        size: AppDimensions.fieldIcon,
        color: Theme.of(context).colorScheme.primary,
      ),
      Expanded(child: Text(text)),
    ],
  );
}

/// Reminder settings, address and note.
class _ReminderAndNotesGroup extends StatelessWidget {
  const _ReminderAndNotesGroup({
    required this.state,
    required this.controllers,
  });

  final AnniversaryFormEditing state;
  final _FieldControllers controllers;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: AppDimensions.space16,
    children: [
      ReminderSection(
        draft: state.draft,
        // No summary when the lead time reaches back before today.
        nextSolar: state.reminderStillAhead ? state.nextHolding?.solar : null,
        showDaysError: state.visibleErrors.contains(
          AnniversaryFormError.daysBeforeInvalid,
        ),
      ),
      _AddressField(controller: controllers.address),
      _NoteField(controller: controllers.note),
    ],
  );
}

class _AddressField extends StatelessWidget {
  const _AddressField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return LabeledTextField(
      label: s.lb_field_address,
      controller: controller,
      onChanged: context.read<AnniversaryFormCubit>().changeAddress,
      options: FieldOptions(optional: true, hint: s.lb_address_hint),
    );
  }
}

class _NoteField extends StatelessWidget {
  const _NoteField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return LabeledTextField(
      label: s.lb_field_note,
      controller: controller,
      onChanged: context.read<AnniversaryFormCubit>().changeNote,
      options: FieldOptions(
        optional: true,
        hint: s.lb_note_hint,
        minLines: 3,
        maxLines: 6,
        capitalization: TextCapitalization.sentences,
      ),
    );
  }
}

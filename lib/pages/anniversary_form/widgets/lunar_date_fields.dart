import 'package:ever_moon/common/app_dimensions.dart';
import 'package:ever_moon/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../anniversary_draft.dart';
import '../anniversary_form_cubit.dart';
import 'labeled_text_field.dart';

/// Lunar day and month pickers of the date of death (required, UI-4).
class LunarDateFields extends StatelessWidget {
  /// Creates the pickers showing [day] and [month].
  const LunarDateFields({
    super.key,
    required this.day,
    required this.month,
    required this.errors,
  });

  /// Chosen lunar day.
  final int? day;

  /// Chosen lunar month.
  final int? month;

  /// Errors to show.
  final Set<AnniversaryFormError> errors;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: AppDimensions.space8,
    children: [
      FieldLabel(text: S.of(context).lb_death_date_lunar),
      _DayMonthRow(day: day, month: month, errors: errors),
    ],
  );
}

class _DayMonthRow extends StatelessWidget {
  const _DayMonthRow({
    required this.day,
    required this.month,
    required this.errors,
  });

  final int? day;
  final int? month;
  final Set<AnniversaryFormError> errors;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: AppDimensions.space12,
    children: [
      Expanded(
        child: _DayPicker(
          value: day,
          showError: errors.contains(AnniversaryFormError.dayInvalid),
        ),
      ),
      Expanded(
        child: _MonthPicker(
          value: month,
          showError: errors.contains(AnniversaryFormError.monthInvalid),
        ),
      ),
    ],
  );
}

class _DayPicker extends StatelessWidget {
  const _DayPicker({required this.value, required this.showError});

  final int? value;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return NumberPicker(
      label: s.lb_field_day,
      max: maxLunarDay,
      value: value,
      error: showError ? s.er_day_required : null,
      onSelected: context.read<AnniversaryFormCubit>().changeDay,
    );
  }
}

class _MonthPicker extends StatelessWidget {
  const _MonthPicker({required this.value, required this.showError});

  final int? value;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return NumberPicker(
      label: s.lb_field_month,
      max: maxLunarMonth,
      value: value,
      error: showError ? s.er_month_required : null,
      onSelected: context.read<AnniversaryFormCubit>().changeMonth,
    );
  }
}

/// A drop-down of the numbers 1 to [max]; no keyboard opens.
class NumberPicker extends StatelessWidget {
  /// Creates the picker.
  const NumberPicker({
    super.key,
    required this.label,
    required this.max,
    required this.value,
    required this.onSelected,
    this.error,
  });

  /// Label inside the field.
  final String label;

  /// Largest number offered.
  final int max;

  /// Chosen number, or `null`.
  final int? value;

  /// Called with the chosen number.
  final ValueChanged<int?> onSelected;

  /// Error under the field, or `null`.
  final String? error;

  @override
  Widget build(BuildContext context) => DropdownMenu<int>(
    expandedInsets: EdgeInsets.zero,
    label: Text(label),
    initialSelection: value,
    errorText: error,
    requestFocusOnTap: false,
    enableSearch: false,
    menuHeight: AppDimensions.pickerMenuHeight,
    onSelected: onSelected,
    dropdownMenuEntries: List.generate(
      max,
      (index) => DropdownMenuEntry(value: index + 1, label: '${index + 1}'),
    ),
  );
}

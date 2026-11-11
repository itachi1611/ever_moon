import 'package:ever_moon/common/app_dimensions.dart';
import 'package:ever_moon/generated/l10n.dart';
import 'package:ever_moon/pages/widgets/delete_anniversary_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../anniversary_form_cubit.dart';

/// Save, and Delete when editing, pinned under the form (design: FormEdit).
class FormActionBar extends StatelessWidget {
  /// Creates the bar; buttons are disabled while [busy].
  const FormActionBar({super.key, required this.isEdit, required this.busy});

  /// Whether an existing record is edited.
  final bool isEdit;

  /// Whether a save or delete is running.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space16),
          child: _Buttons(isEdit: isEdit, busy: busy),
        ),
      ),
    );
  }
}

class _Buttons extends StatelessWidget {
  const _Buttons({required this.isEdit, required this.busy});

  final bool isEdit;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cubit = context.read<AnniversaryFormCubit>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppDimensions.space8,
      children: [
        FilledButton(
          onPressed: busy ? null : cubit.save,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(AppDimensions.minTouchTarget),
          ),
          child: Text(isEdit ? s.lb_save_edit : s.lb_save_new),
        ),
        if (isEdit) _DeleteButton(enabled: !busy),
      ],
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.enabled});

  final bool enabled;

  Future<void> _delete(BuildContext context) async {
    final cubit = context.read<AnniversaryFormCubit>();
    final confirmed = await confirmDeleteAnniversary(
      context,
      cubit.storedName ?? '',
    );
    if (confirmed) await cubit.delete();
  }

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: enabled ? () => _delete(context) : null,
    style: TextButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.error,
      minimumSize: const Size.fromHeight(AppDimensions.minTouchTarget),
    ),
    icon: const Icon(Icons.delete_outline),
    label: Text(S.of(context).lb_delete_anniversary),
  );
}

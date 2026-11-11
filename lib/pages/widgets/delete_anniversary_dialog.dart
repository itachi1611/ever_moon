import 'package:ever_moon/generated/l10n.dart';
import 'package:flutter/material.dart';

/// Asks before an anniversary is deleted (UI-6; design: DeleteDialog).
///
/// Returns `true` only when the user picks Delete; dismissing the dialog
/// keeps the record.
Future<bool> confirmDeleteAnniversary(BuildContext context, String name) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => DeleteAnniversaryDialog(name: name),
  );
  return confirmed ?? false;
}

/// Confirmation dialog for deleting the anniversary of [name].
class DeleteAnniversaryDialog extends StatelessWidget {
  /// Creates the dialog.
  const DeleteAnniversaryDialog({super.key, required this.name});

  /// Name of the person whose anniversary would be deleted.
  final String name;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final navigator = Navigator.of(context);
    return AlertDialog(
      title: Text(s.lb_delete_title(name)),
      content: Text(s.lb_delete_body),
      actions: [
        TextButton(
          onPressed: () => navigator.pop(false),
          child: Text(s.lb_keep),
        ),
        TextButton(
          onPressed: () => navigator.pop(true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: Text(s.lb_delete),
        ),
      ],
    );
  }
}

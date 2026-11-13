import 'package:flutter/material.dart';

/// Shows the platform time picker for the reminder time.
///
/// The picker never sees a text scale below 1. Flutter's keyboard-entry mode
/// has a 216 px minimum height inside a 252 px box that the text scale
/// shrinks, so at 85% (a font size users can pick in the phone settings) the
/// box ends up below the minimum and the picker throws a layout error.
/// Larger scales are left alone.
Future<TimeOfDay?> showReminderTimePicker(
  BuildContext context,
  TimeOfDay initialTime,
) => showTimePicker(
  context: context,
  initialTime: initialTime,
  builder: (context, child) => MediaQuery.withClampedTextScaling(
    minScaleFactor: 1,
    maxScaleFactor: double.infinity,
    child: child ?? const SizedBox.shrink(),
  ),
);

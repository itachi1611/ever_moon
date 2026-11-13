import 'package:ever_moon/generated/l10n.dart';
import 'package:ever_moon/models/app_settings.dart';
import 'package:ever_moon/pages/widgets/lunar_texts.dart';
import 'package:ever_moon/services/reminders/notification_gateway.dart';
import 'package:ever_moon/services/reminders/planned_reminder.dart';
import 'package:intl/intl.dart';

/// Start of every reminder payload; a tap handler checks it so it ignores
/// taps on push notifications.
const String reminderPayload = 'evermoon.reminder';

/// Whether [payload] came from one of our reminders.
bool isReminderPayload(String? payload) =>
    payload != null && payload.startsWith(reminderPayload);

/// Turns [reminder] into a notification in the language of [s].
///
/// [locale] is the language code [s] was loaded for; the Gregorian date in
/// the body is formatted with it. The text is fixed here, at schedule time,
/// so a language change needs a new plan (D-R7).
ReminderNotification buildReminderNotification(
  PlannedReminder reminder,
  S s,
  AppSettings settings, {
  required String locale,
}) {
  final holiday = reminder.holiday;
  final title = holiday == null
      ? s.lb_reminder_anniversary_title(
          reminder.daysBefore,
          reminder.anniversaryName ?? '',
        )
      : holidayName(s, holiday);
  final lunar = lunarDateText(s, reminder.lunar);
  final body = holiday == null
      ? s.lb_reminder_anniversary_body(
          lunar,
          DateFormat(s.lb_solar_date_pattern, locale).format(reminder.eventDay),
        )
      : lunar;
  return ReminderNotification(
    id: reminder.id,
    fireAt: reminder.fireAt,
    title: title,
    body: body,
    sound: settings.sound,
    vibrate: settings.vibrate,
    channelName: s.lb_reminder_channel_name,
    channelDescription: s.lb_reminder_channel_description,
    payload: _payloadOf(reminder),
  );
}

String _payloadOf(PlannedReminder reminder) {
  final id = reminder.anniversaryId;
  return id == null ? reminderPayload : '$reminderPayload:$id';
}

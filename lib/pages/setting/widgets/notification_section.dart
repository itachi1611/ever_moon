import 'package:ever_moon/common/app_dimensions.dart';
import 'package:ever_moon/generated/l10n.dart';
import 'package:ever_moon/models/app_settings.dart';
import 'package:ever_moon/services/notification_access_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../setting_cubit.dart';
import '../setting_state.dart';
import 'settings_frame.dart';

/// Permission row (D18, UI-16), reminder sound and vibration.
class NotificationSection extends StatelessWidget {
  /// Creates the section for [state].
  const NotificationSection({super.key, required this.state});

  /// Loaded preferences.
  final SettingLoaded state;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cubit = context.read<SettingCubit>();
    return SectionCard(
      children: [
        NotificationAccessTile(access: state.access),
        _SoundTile(sound: state.settings.sound),
        SwitchListTile(
          title: Text(s.lb_vibrate),
          value: state.settings.vibrate,
          onChanged: cubit.setVibrate,
        ),
        const _NotifyHint(),
      ],
    );
  }
}

/// Shows whether notifications are allowed; a tap asks, or opens the
/// system settings when Android will not ask again (D18, UI-16).
class NotificationAccessTile extends StatelessWidget {
  /// Creates the row for [access].
  const NotificationAccessTile({super.key, required this.access});

  /// Current permission state.
  final NotificationAccess access;

  String _status(S s) => switch (access) {
    NotificationAccess.granted => s.lb_notify_on,
    NotificationAccess.denied => s.lb_notify_off,
    NotificationAccess.blocked => s.lb_notify_blocked,
  };

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;
    final granted = access == NotificationAccess.granted;
    return ListTile(
      leading: Icon(
        granted
            ? Icons.notifications_active_outlined
            : Icons.notifications_off_outlined,
        color: granted ? scheme.primary : scheme.error,
      ),
      title: Text(s.lb_notify_access),
      subtitle: Text(_status(s)),
      trailing: const Icon(Icons.chevron_right),
      onTap: context.read<SettingCubit>().openNotificationAccess,
    );
  }
}

class _SoundTile extends StatelessWidget {
  const _SoundTile({required this.sound});

  final ReminderSound sound;

  Future<void> _pick(BuildContext context) async {
    final cubit = context.read<SettingCubit>();
    final picked = await showModalBottomSheet<ReminderSound>(
      context: context,
      showDragHandle: true,
      builder: (_) => SoundSheet(selected: sound),
    );
    if (picked != null) await cubit.setSound(picked);
  }

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(S.of(context).lb_sound),
    subtitle: Text(soundName(S.of(context), sound)),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => _pick(context),
  );
}

/// Name of [sound].
String soundName(S s, ReminderSound sound) => switch (sound) {
  ReminderSound.deviceDefault => s.lb_sound_default,
  ReminderSound.softBell => s.lb_sound_bell,
  ReminderSound.silent => s.lb_sound_silent,
};

/// The sound choices; returns the picked one.
class SoundSheet extends StatelessWidget {
  /// Creates the sheet with [selected] marked.
  const SoundSheet({super.key, required this.selected});

  /// The current sound.
  final ReminderSound selected;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(s.lb_sound_title, style: Theme.of(context).textTheme.titleLarge),
          for (final sound in ReminderSound.values)
            _SoundOption(sound: sound, isSelected: sound == selected),
        ],
      ),
    );
  }
}

class _SoundOption extends StatelessWidget {
  const _SoundOption({required this.sound, required this.isSelected});

  final ReminderSound sound;
  final bool isSelected;

  @override
  Widget build(BuildContext context) => ListTile(
    selected: isSelected,
    leading: Icon(
      isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
    ),
    title: Text(soundName(S.of(context), sound)),
    // The sheet returns the pick to the caller.
    onTap: () => Navigator.of(context).pop(sound),
  );
}

class _NotifyHint extends StatelessWidget {
  const _NotifyHint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.space16,
        0,
        AppDimensions.space16,
        AppDimensions.space16,
      ),
      child: Text(
        S.of(context).lb_notify_hint,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

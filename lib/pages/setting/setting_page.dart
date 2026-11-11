import 'package:ever_moon/generated/l10n.dart';
import 'package:ever_moon/pages/shell/shell_scope.dart';
import 'package:ever_moon/services/notification_access_service.dart';
import 'package:ever_moon/storage/settings_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'setting_cubit.dart';
import 'setting_state.dart';
import 'widgets/settings_sections.dart';

/// Settings (plan 0005, U6; design: Settings): language, theme,
/// notifications, system events and About.
///
/// Owns its [SettingCubit]; theme and language go through `AppCubit`.
class SettingPage extends StatefulWidget {
  /// Creates the page; tests pass [store], [access] and [version].
  const SettingPage({super.key, this.store, this.access, this.version});

  /// Preferences; the app-wide store when `null`.
  final SettingsStore? store;

  /// Notification permission; the plugin-backed one when `null`.
  final NotificationAccessService? access;

  /// App version; read from the package when `null`.
  final Future<String> Function()? version;

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  late final SettingCubit _cubit;
  late final AppLifecycleListener _lifecycle;

  static Future<String> _packageVersion() async =>
      (await PackageInfo.fromPlatform()).version;

  @override
  void initState() {
    super.initState();
    _cubit = SettingCubit(
      store: widget.store ?? settingsStore,
      access: widget.access ?? notificationAccessService,
      version: widget.version ?? _packageVersion,
    )..load();
    // The user may come back from the system settings with a new answer.
    _lifecycle = AppLifecycleListener(onResume: _cubit.refreshAccess);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _cubit,
    child: Scaffold(
      appBar: AppBar(
        leading: MenuButton.maybe(context),
        title: Text(S.of(context).lb_settings),
      ),
      body: BlocBuilder<SettingCubit, SettingState>(
        builder: (context, state) => switch (state) {
          SettingLoading() => const Center(child: CircularProgressIndicator()),
          SettingLoaded() => SettingsSections(state: state),
        },
      ),
    ),
  );
}

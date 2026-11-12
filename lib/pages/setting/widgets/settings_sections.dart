import 'package:ever_moon/app/app_cubit.dart';
import 'package:ever_moon/app/app_state.dart';
import 'package:ever_moon/common/app_config.dart';
import 'package:ever_moon/common/app_dimensions.dart';
import 'package:ever_moon/common/app_enums.dart' show AppLanguage;
import 'package:ever_moon/generated/l10n.dart';
import 'package:ever_moon/routing/routers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../setting_cubit.dart';
import '../setting_state.dart';
import 'notification_section.dart';
import 'settings_frame.dart';

/// All sections of the Settings page, in design order.
class SettingsSections extends StatelessWidget {
  /// Creates the sections for [state].
  const SettingsSections({super.key, required this.state});

  /// Loaded preferences.
  final SettingLoaded state;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    // A fixed set of sections, not a dynamic list.
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.space16),
      children: [
        SectionTitle(text: s.lb_general),
        const _GeneralSection(),
        SectionTitle(text: s.lb_notify_section),
        NotificationSection(state: state),
        SectionTitle(text: s.lb_system_section),
        _SystemEventsSection(state: state),
        SectionTitle(text: s.lb_about),
        _AboutSection(version: state.version),
      ],
    );
  }
}

/// Language and theme; both apply to the whole app at once (UI-12).
class _GeneralSection extends StatelessWidget {
  const _GeneralSection();

  @override
  Widget build(BuildContext context) => BlocBuilder<AppCubit, AppState>(
    builder: (context, app) => SectionCard(
      children: [
        LabeledControl(
          label: S.of(context).lb_language,
          child: _LanguageSwitch(locale: app.locale),
        ),
        LabeledControl(
          label: S.of(context).lb_theme,
          child: _ThemeSwitch(mode: app.themeMode),
        ),
      ],
    ),
  );
}

class _LanguageSwitch extends StatelessWidget {
  const _LanguageSwitch({required this.locale});

  final Locale locale;

  @override
  Widget build(BuildContext context) {
    // Vietnamese first; each language is shown in its own name.
    const languages = [AppLanguage.vi, AppLanguage.eng];
    final selected = languages.firstWhere(
      (l) => l.locale.languageCode == locale.languageCode,
      orElse: () => AppLanguage.vi,
    );
    return SegmentedButton<AppLanguage>(
      showSelectedIcon: false,
      selected: {selected},
      onSelectionChanged: (picked) =>
          context.read<AppCubit>().setLocale(picked.first.locale),
      segments: [
        for (final language in languages)
          ButtonSegment(value: language, label: Text(language.label)),
      ],
    );
  }
}

class _ThemeSwitch extends StatelessWidget {
  const _ThemeSwitch({required this.mode});

  final ThemeMode mode;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return SegmentedButton<ThemeMode>(
      showSelectedIcon: false,
      selected: {mode},
      onSelectionChanged: (picked) =>
          context.read<AppCubit>().setThemeMode(picked.first),
      segments: [
        ButtonSegment(value: ThemeMode.system, label: Text(s.lb_theme_system)),
        ButtonSegment(value: ThemeMode.light, label: Text(s.lb_theme_light)),
        ButtonSegment(value: ThemeMode.dark, label: Text(s.lb_theme_dark)),
      ],
    );
  }
}

/// Mùng 1, rằm and festival reminders (stored here; A4 schedules them).
class _SystemEventsSection extends StatelessWidget {
  const _SystemEventsSection({required this.state});

  final SettingLoaded state;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cubit = context.read<SettingCubit>();
    final settings = state.settings;
    final rows = [
      (s.lb_remind_first_day, settings.remindFirstDay, cubit.setRemindFirstDay),
      (s.lb_remind_full_moon, settings.remindFullMoon, cubit.setRemindFullMoon),
      (
        s.lb_remind_festivals,
        settings.remindFestivals,
        cubit.setRemindFestivals,
      ),
    ];
    return SectionCard(
      children: [
        for (final (title, value, onChanged) in rows)
          SwitchListTile(
            title: Text(title),
            value: value,
            onChanged: onChanged,
          ),
      ],
    );
  }
}

/// Terms, privacy and version; the drawer has no legal section (D14).
class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.version});

  final String version;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return SectionCard(
      children: [
        _LinkTile(text: s.lb_terms, path: Routers.terms.routerPath),
        _LinkTile(text: s.lb_policy, path: Routers.privacy.routerPath),
        ListTile(
          title: Text(s.lb_version),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppDimensions.space8,
            children: [Text(version), const Icon(Icons.chevron_right)],
          ),
          onTap: () => _showAbout(context),
        ),
      ],
    );
  }

  /// Flutter's own about dialog; its "View licenses" button lists the
  /// licenses of the packages the app uses.
  void _showAbout(BuildContext context) => showAboutDialog(
    context: context,
    applicationName: S.of(context).lb_app_name,
    applicationVersion: version,
    applicationIcon: const _AboutIcon(),
    applicationLegalese: S.of(context).lb_legalese,
  );
}

class _AboutIcon extends StatelessWidget {
  const _AboutIcon();

  @override
  Widget build(BuildContext context) => ClipOval(
    child: Image.asset(
      AppConfig.kMarkImage,
      width: AppDimensions.drawerMark,
      height: AppDimensions.drawerMark,
      excludeFromSemantics: true,
    ),
  );
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.text, required this.path});

  final String text;
  final String path;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(text),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => context.go(path),
  );
}

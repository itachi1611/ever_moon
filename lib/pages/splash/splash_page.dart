import 'dart:async';

import 'package:ever_moon/common/app_config.dart';
import 'package:ever_moon/common/app_dimensions.dart';
import 'package:ever_moon/generated/l10n.dart';
import 'package:ever_moon/routing/routers.dart';
import 'package:ever_moon/services/notification_access_service.dart';
import 'package:ever_moon/storage/app_preference.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'splash_cubit.dart';
import 'splash_state.dart';

/// Entry route (`/`): holds the mark from the native splash for the moment
/// the first-run flag is read, then goes to the intro or the list
/// (plan 0005, U7; UI-15).
class SplashPage extends StatefulWidget {
  /// Creates the page; tests pass [hasCompletedIntro] and [access].
  const SplashPage({
    super.key,
    this.onNotificationsAllowed,
    this.hasCompletedIntro,
    this.access,
  });

  /// Runs on later launches when notifications are allowed (the route
  /// passes the push token refresh); never shows a dialog.
  final Future<void> Function()? onNotificationsAllowed;

  /// Reads the first-run flag; [AppPreference] when `null`.
  final bool Function()? hasCompletedIntro;

  /// Notification permission; the plugin-backed one when `null`.
  final NotificationAccessService? access;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  late final SplashCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = SplashCubit(
      hasCompletedIntro:
          widget.hasCompletedIntro ?? AppPreference.instance.isCompleteIntro,
      access: widget.access ?? notificationAccessService,
      onNotificationsAllowed: widget.onNotificationsAllowed,
    );
    // After the first frame: on a first launch start() emits at once, and a
    // state emitted before the BlocListener subscribes would be missed,
    // leaving the app on the splash.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_cubit.start()),
    );
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _cubit,
    child: BlocListener<SplashCubit, SplashState>(
      listener: (context, state) {
        if (state is! SplashReady) return;
        context.go(
          state.firstRun
              ? Routers.onboarding.routerPath
              : Routers.home.routerPath,
        );
      },
      child: const _SplashMark(),
    ),
  );
}

/// The E8 mark in its circle on the surface. It pops in like the native
/// Android 12 splash (scale 0.6 to 1 with overshoot, 700 ms); with system
/// animations off it appears at once.
class _SplashMark extends StatelessWidget {
  const _SplashMark();

  static const _popDuration = Duration(milliseconds: 700);
  static const _startScale = 0.6;

  @override
  Widget build(BuildContext context) {
    final animate = !MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      body: Center(
        child: Semantics(
          label: S.of(context).lb_app_opening,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: animate ? 0 : 1, end: 1),
            duration: animate ? _popDuration : Duration.zero,
            curve: Curves.easeOutBack,
            builder: (context, progress, child) => Opacity(
              opacity: progress.clamp(0.0, 1.0).toDouble(),
              child: Transform.scale(
                scale: _startScale + (1 - _startScale) * progress,
                child: child,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                AppConfig.kMarkImage,
                width: AppDimensions.splashMark,
                height: AppDimensions.splashMark,
                excludeFromSemantics: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

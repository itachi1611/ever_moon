import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import 'transition_shell_widget.dart';

/// Renders all navigation branches in a [Stack], keeping inactive branches
/// in an [Offstage] so their state is preserved. The newly activated branch
/// animates in using [transitionType]; the branch that was just left plays a
/// correlated exit (fade/slide out) for the same [duration] instead of
/// disappearing instantly.
///
/// The [CurvedAnimation] and [Tween]s are stored as long-lived fields to
/// avoid listener accumulation on repeated tab switches — no new
/// [AnimationController] is created per switch.
class AnimatedBranchContainer extends StatefulWidget {
  /// Creates an [AnimatedBranchContainer].
  const AnimatedBranchContainer({
    super.key,
    required this.currentIndex,
    required this.children,
    this.transitionType = ShellTransitionType.slide,
    this.curve = Curves.easeOut,
    this.duration = const Duration(milliseconds: 220),
  });

  /// Index of the branch to display, into [children].
  final int currentIndex;

  /// All navigation branches; every entry is kept alive off-stage while
  /// inactive so its state is preserved.
  final List<Widget> children;

  /// How the active branch animates in (and the previous one animates out).
  ///
  /// Defaults to [ShellTransitionType.slide].
  final ShellTransitionType transitionType;

  /// Easing curve applied to the transition. Defaults to [Curves.easeOut].
  final Curve curve;

  /// How long the transition takes. Defaults to 220ms.
  final Duration duration;

  @override
  State<AnimatedBranchContainer> createState() =>
      _AnimatedBranchContainerState();
}

/// Share of the width a branch travels while it fades, for the types that
/// fade as well as slide: enough to read as movement, not a full-width push.
const double _fadeSlideDistance = 0.25;

class _AnimatedBranchContainerState extends State<AnimatedBranchContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curved;
  late final Tween<Offset> _tween;
  late final Animation<Offset> _slideIn;

  // Exit animations for the branch that was just left — derived from the
  // same controller/curve, so no extra AnimationController is allocated.
  late final Animation<double> _fadeOut;
  late final Tween<Offset> _exitTween;
  late final Animation<Offset> _slideOut;

  // Index still playing its exit transition, or null once it has completed.
  // Kept on-stage only while this is non-null.
  int? _previousIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
      value: 1.0, // start fully visible on first render
    )..addStatusListener(_onStatusChanged);
    _curved = CurvedAnimation(parent: _controller, curve: widget.curve);

    _tween = Tween<Offset>(begin: Offset.zero, end: Offset.zero);
    _slideIn = _tween.animate(_curved);

    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(_curved);
    _exitTween = Tween<Offset>(begin: Offset.zero, end: Offset.zero);
    _slideOut = _exitTween.animate(_curved);
  }

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && _previousIndex != null) {
      setState(() => _previousIndex = null);
    }
  }

  @override
  void didUpdateWidget(AnimatedBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      // The new branch comes in from the side it sits on in the drawer
      // (a higher index from the right), the old one leaves the other way.
      final side = widget.currentIndex > oldWidget.currentIndex ? 1.0 : -1.0;
      final distance = widget.transitionType == ShellTransitionType.slide
          ? 1.0
          : _fadeSlideDistance;
      _tween.begin = Offset(distance * side, 0);
      _exitTween.begin = Offset.zero;
      _exitTween.end = Offset(-distance * side, 0);
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onStatusChanged);
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: widget.children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        final isActive = index == widget.currentIndex;
        final isExiting = index == _previousIndex;

        if (widget.transitionType == ShellTransitionType.fadeThrough) {
          return _fadeThrough(child, isActive: isActive, isExiting: isExiting);
        }

        return Offstage(
          offstage: !isActive && !isExiting,
          child: RepaintBoundary(
            child: isActive
                ? widget.transitionType.transition(
                    child: child,
                    opacity: _curved,
                    position: _slideIn,
                  )
                : isExiting
                ? widget.transitionType.transition(
                    child: child,
                    opacity: _fadeOut,
                    position: _slideOut,
                  )
                : child,
          ),
        );
      }).toList(),
    );
  }

  /// The package transition takes the raw controller: it has its own
  /// timing (the old branch fades out first, the new one scales in after).
  Widget _fadeThrough(
    Widget child, {
    required bool isActive,
    required bool isExiting,
  }) => Offstage(
    offstage: !isActive && !isExiting,
    child: RepaintBoundary(
      child: isActive
          ? FadeThroughTransition(
              animation: _controller,
              secondaryAnimation: kAlwaysDismissedAnimation,
              fillColor: Colors.transparent,
              child: child,
            )
          : isExiting
          ? FadeThroughTransition(
              animation: kAlwaysCompleteAnimation,
              secondaryAnimation: _controller,
              fillColor: Colors.transparent,
              child: child,
            )
          : child,
    ),
  );
}

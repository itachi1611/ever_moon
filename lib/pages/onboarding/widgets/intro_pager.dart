import 'package:ever_moon/common/app_dimensions.dart';
import 'package:ever_moon/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../onboarding_cubit.dart';
import '../onboarding_state.dart';
import 'intro_illustration.dart';

/// The three intro pages with Bỏ qua, the page dots and the next button
/// (design: Intro1 to Intro3).
class IntroPager extends StatefulWidget {
  /// Creates the pager.
  const IntroPager({super.key});

  @override
  State<IntroPager> createState() => _IntroPagerState();
}

class _IntroPagerState extends State<IntroPager> {
  final _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Follows a button tap; a swipe already moved the page.
  void _follow(BuildContext context, OnboardingState state) {
    if (state is! OnboardingSlides || !_controller.hasClients) return;
    if (_controller.page?.round() == state.slide.index) return;
    _controller.animateToPage(
      state.slide.index,
      duration: kTabScrollDuration,
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    return BlocListener<OnboardingCubit, OnboardingState>(
      listener: _follow,
      child: Column(
        children: [
          const _SkipBar(),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: IntroSlide.values.length,
              onPageChanged: (i) => cubit.showSlide(IntroSlide.values[i]),
              itemBuilder: (_, i) =>
                  IntroSlideView(slide: IntroSlide.values[i]),
            ),
          ),
          const _PagerFooter(),
        ],
      ),
    );
  }
}

class _SkipBar extends StatelessWidget {
  const _SkipBar();

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerEnd,
    child: Padding(
      padding: const EdgeInsets.all(AppDimensions.space8),
      child: TextButton(
        onPressed: context.read<OnboardingCubit>().skip,
        child: Text(S.of(context).lb_skip),
      ),
    ),
  );
}

/// One intro page.
class IntroSlideView extends StatelessWidget {
  /// Creates the page for [slide].
  const IntroSlideView({super.key, required this.slide});

  /// Which page.
  final IntroSlide slide;

  static (IconData, String, String) _content(S s, IntroSlide slide) =>
      switch (slide) {
        IntroSlide.lunar => (
          Icons.dark_mode_outlined,
          s.lb_intro1_title,
          s.lb_intro1_body,
        ),
        IntroSlide.reminders => (
          Icons.notifications_outlined,
          s.lb_intro2_title,
          s.lb_intro2_body,
        ),
        IntroSlide.holidays => (
          Icons.calendar_month_outlined,
          s.lb_intro3_title,
          s.lb_intro3_body,
        ),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, title, body) = _content(S.of(context), slide);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space24),
      child: Column(
        children: [
          Expanded(
            child: Center(child: IntroIllustration(icon: icon)),
          ),
          IntroTexts(title: title, body: body),
        ],
      ),
    );
  }
}

class _PagerFooter extends StatelessWidget {
  const _PagerFooter();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<OnboardingCubit, OnboardingState>(
        builder: (context, state) => state is OnboardingSlides
            ? _FooterRow(state: state)
            : const SizedBox.shrink(),
      );
}

class _FooterRow extends StatelessWidget {
  const _FooterRow({required this.state});

  final OnboardingSlides state;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.space24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          PageDots(index: state.slide.index, count: IntroSlide.values.length),
          FilledButton(
            onPressed: context.read<OnboardingCubit>().next,
            child: Text(state.isLast ? s.lb_start : s.lb_continue),
          ),
        ],
      ),
    );
  }
}

/// Where the user is among the intro pages.
class PageDots extends StatelessWidget {
  /// Creates the dots; [index] is the current page.
  const PageDots({super.key, required this.index, required this.count});

  /// Current page, from 0.
  final int index;

  /// Number of pages.
  final int count;

  @override
  Widget build(BuildContext context) => Semantics(
    label: S.of(context).lb_page_of(index + 1, count),
    excludeSemantics: true,
    child: Row(
      spacing: AppDimensions.space8,
      children: [
        for (var i = 0; i < count; i++) _PageDot(isCurrent: i == index),
      ],
    ),
  );
}

class _PageDot extends StatelessWidget {
  const _PageDot({required this.isCurrent});

  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: kThemeAnimationDuration,
      width: isCurrent ? AppDimensions.pageDotActive : AppDimensions.pageDot,
      height: AppDimensions.pageDot,
      decoration: BoxDecoration(
        color: isCurrent ? scheme.primary : scheme.outlineVariant,
        borderRadius: BorderRadius.circular(AppDimensions.pageDot),
      ),
    );
  }
}

// lib/widgets/post_list/list_cardskeleton.dart

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ListCardSkeleton extends StatelessWidget {
  final bool isHero;
  const ListCardSkeleton({super.key, this.isHero = false});

  @override
  Widget build(BuildContext context) {
    if (isHero) {
      final isMobile = MediaQuery.of(context).size.width < 800;
      return Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: isMobile
              ? const Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 6,
                      child: SkeletonBox(height: double.infinity),
                    ),
                    Padding(
                      padding: EdgeInsets.all(28),
                      child: _HeroSkeletonContent(),
                    ),
                  ],
                )
              : const IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 12,
                        child: AspectRatio(
                          aspectRatio: 16 / 6,
                          child: SkeletonBox(height: double.infinity),
                        ),
                      ),
                      Expanded(
                        flex: 10,
                        child: Padding(
                          padding: EdgeInsets.all(28),
                          child: _HeroSkeletonContent(),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkeletonBox(width: 24, height: 24, shape: BoxShape.circle),
              const SizedBox(width: 8),
              SkeletonBox(
                width: 120,
                height: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(
                      width: double.infinity,
                      height: 18,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 6),
                    SkeletonBox(
                      width: double.infinity,
                      height: 13,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 6),
                    SkeletonBox(
                      width: 160,
                      height: 13,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: const SkeletonBox(
                  width: 140,
                  height: 90,
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            color: AppColors.border(context).withValues(alpha: 0.5),
            height: 1,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBox(
                width: 70,
                height: 12,
                borderRadius: BorderRadius.circular(4),
              ),
              SkeletonBox(
                width: 80,
                height: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TrendingSkeleton extends StatelessWidget {
  const TrendingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(
            width: 160,
            height: 12,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 20),
          for (int row = 0; row < 2; row++) ...[
            if (row > 0) const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(child: _TrendingRowSkeleton()),
                const SizedBox(width: 32),
                const Expanded(child: _TrendingRowSkeleton()),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TrendingRowSkeleton extends StatelessWidget {
  const _TrendingRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SkeletonBox(
                    width: 22,
                    height: 22,
                    shape: BoxShape.circle,
                  ),
                  const SizedBox(width: 8),
                  SkeletonBox(
                    width: 100,
                    height: 12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SkeletonBox(
                width: double.infinity,
                height: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: const SkeletonBox(
            width: 90,
            height: 60,
            borderRadius: BorderRadius.zero,
          ),
        ),
      ],
    );
  }
}

class _HeroSkeletonContent extends StatelessWidget {
  const _HeroSkeletonContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SkeletonBox(
          width: 120,
          height: 14,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 16),
        SkeletonBox(
          width: double.infinity,
          height: 24,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 12),
        SkeletonBox(
          width: double.infinity,
          height: 14,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        SkeletonBox(
          width: 220,
          height: 14,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 28),
        SkeletonBox(
          width: 160,
          height: 40,
          borderRadius: BorderRadius.circular(8),
        ),
      ],
    );
  }
}

/// Restored subtle opacity pulse
class SkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final BoxShape shape;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.25,
      end: 0.65,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              shape: widget.shape,
              borderRadius: widget.shape == BoxShape.circle
                  ? null
                  : widget.borderRadius,
              color: AppColors.border(context).withValues(alpha: 0.5),
            ),
          ),
        );
      },
    );
  }
}

/// Hashnode Fade-In + Pop-In scale animation for loaded cards
class FadeSlideUp extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double startY;
  final Duration delay; // Added start delay parameter

  const FadeSlideUp({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1100),
    this.startY = 45.0,
    this.delay = Duration.zero,
  });

  @override
  State<FadeSlideUp> createState() => _FadeSlideUpState();
}

class _FadeSlideUpState extends State<FadeSlideUp>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _translateY;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _translateY = Tween<double>(
      begin: widget.startY,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: Offset(0, _translateY.value),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

// lib/widgets/post_list/list_cardskeleton.dart

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ListCardSkeleton extends StatelessWidget {
  const ListCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.cardBackground(context),
          borderRadius: BorderRadius.circular(AppRadius.value),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SkeletonBox(
                  width: 32,
                  height: 32,
                  shape: BoxShape.circle,
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(
                      width: 120,
                      height: 14,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 6),
                    SkeletonBox(
                      width: 80,
                      height: 12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SkeletonBox(
              width: 220,
              height: 20,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: AppSpacing.xs),
            SkeletonBox(
              width: double.infinity,
              height: 14,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 6),
            SkeletonBox(
              width: 180,
              height: 14,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: AppSpacing.sm),
            SkeletonBox(
              width: double.infinity,
              height: 200,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                SkeletonBox(
                  width: 60,
                  height: 32,
                  borderRadius: BorderRadius.circular(999),
                ),
                const SizedBox(width: 8),
                SkeletonBox(
                  width: 60,
                  height: 32,
                  borderRadius: BorderRadius.circular(999),
                ),
                const SizedBox(width: 8),
                SkeletonBox(
                  width: 40,
                  height: 32,
                  borderRadius: BorderRadius.circular(999),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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
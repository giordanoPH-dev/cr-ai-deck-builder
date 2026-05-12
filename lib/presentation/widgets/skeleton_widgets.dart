import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

// ── Shimmer base ─────────────────────────────────────────────────────────────

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            begin: Alignment(_animation.value - 1, 0),
            end: Alignment(_animation.value, 0),
            colors: const [
              AppColors.card,
              AppColors.cardElevated,
              AppColors.card,
            ],
          ),
        ),
      ),
    );
  }
}

// ── Public shimmer widget ─────────────────────────────────────────────────────

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return _ShimmerBox(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }
}

// ── Profile skeleton ──────────────────────────────────────────────────────────

class ProfileSkeletonScreen extends StatelessWidget {
  const ProfileSkeletonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AppBar fake
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const ShimmerBox(width: 40, height: 40, borderRadius: 20),
                  const SizedBox(width: 12),
                  ShimmerBox(width: w * 0.4, height: 18),
                  const Spacer(),
                  const ShimmerBox(width: 36, height: 36, borderRadius: 18),
                ],
              ),
            ),
            // Header card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ShimmerBox(width: w * 0.45, height: 24),
                        const Spacer(),
                        const ShimmerBox(width: 80, height: 28, borderRadius: 14),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ShimmerBox(width: w * 0.18, height: 36, borderRadius: 10),
                        const SizedBox(width: 12),
                        ShimmerBox(width: w * 0.18, height: 36, borderRadius: 10),
                        const SizedBox(width: 12),
                        ShimmerBox(width: w * 0.18, height: 36, borderRadius: 10),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Tab bar fake
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(5, (i) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ShimmerBox(width: w * 0.14, height: 32, borderRadius: 8),
                )),
              ),
            ),
            const SizedBox(height: 20),
            // Content area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: w * 0.5, height: 20),
                    const SizedBox(height: 16),
                    // Card grid skeleton (2x4)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: 8,
                      itemBuilder: (_, __) => const ShimmerBox(
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: 12,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ShimmerBox(width: w * 0.6, height: 16),
                    const SizedBox(height: 10),
                    ShimmerBox(width: w * 0.9, height: 12),
                    const SizedBox(height: 6),
                    ShimmerBox(width: w * 0.75, height: 12),
                    const SizedBox(height: 6),
                    ShimmerBox(width: w * 0.8, height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── AI analysis skeleton ──────────────────────────────────────────────────────

class AiAnalysisSkeletonWidget extends StatelessWidget {
  const AiAnalysisSkeletonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grade card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const ShimmerBox(width: 72, height: 72, borderRadius: 36),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: w * 0.3, height: 18),
                        const SizedBox(height: 8),
                        ShimmerBox(width: w * 0.4, height: 14),
                        const SizedBox(height: 6),
                        ShimmerBox(width: w * 0.25, height: 14),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ShimmerBox(width: double.infinity, height: 12),
                const SizedBox(height: 6),
                ShimmerBox(width: w * 0.85, height: 12),
                const SizedBox(height: 6),
                ShimmerBox(width: w * 0.7, height: 12),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Deck card skeleton
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: w * 0.4, height: 16),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    8,
                    (_) => const ShimmerBox(width: 40, height: 50, borderRadius: 8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Playstyle card skeleton
          _SkeletonCard(lines: 4, titleWidth: w * 0.35),
          const SizedBox(height: 12),
          _SkeletonCard(lines: 3, titleWidth: w * 0.45),
          const SizedBox(height: 12),
          _SkeletonCard(lines: 5, titleWidth: w * 0.5),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final int lines;
  final double titleWidth;

  const _SkeletonCard({required this.lines, required this.titleWidth});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: titleWidth, height: 16),
          const SizedBox(height: 12),
          ...List.generate(lines, (i) {
            final lineWidth = i == lines - 1 ? w * 0.55 : (i.isEven ? double.infinity : w * 0.85);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: ShimmerBox(width: lineWidth, height: 12),
            );
          }),
        ],
      ),
    );
  }
}

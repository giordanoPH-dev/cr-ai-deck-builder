import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';

// ── GradeBadge ────────────────────────────────────────────────────────────────

class GradeBadge extends StatefulWidget {
  final String grade;
  final double size;
  final bool animate;

  const GradeBadge({
    super.key,
    required this.grade,
    this.size = 80,
    this.animate = true,
  });

  @override
  State<GradeBadge> createState() => _GradeBadgeState();
}

class _GradeBadgeState extends State<GradeBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.gradeColor(widget.grade);
    final tier = _gradeTier(widget.grade);

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, child) => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.15),
          border: Border.all(
            color: color.withValues(alpha: _glowAnim.value * 0.9),
            width: tier == _GradeTier.sPlus ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: _glowAnim.value * _glowIntensity(tier)),
              blurRadius: _glowRadius(tier),
              spreadRadius: _glowSpread(tier),
            ),
          ],
        ),
        child: child,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (tier == _GradeTier.sPlus) _GoldenParticles(size: widget.size),
          Text(
            widget.grade,
            style: TextStyle(
              color: _textColor(widget.grade),
              fontSize: widget.size * 0.38,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: AppColors.gradeColor(widget.grade).withValues(alpha: 0.8),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _textColor(String grade) {
    final upper = grade.toUpperCase();
    if (upper == 'S') return const Color(0xFFFFD700);
    if (upper.startsWith('A')) return AppColors.gradeA;
    if (upper.startsWith('B')) return AppColors.gradeB;
    if (upper.startsWith('C')) return AppColors.gradeC;
    if (upper.startsWith('D')) return AppColors.gradeD;
    return AppColors.gradeF;
  }

  double _glowIntensity(_GradeTier tier) {
    switch (tier) {
      case _GradeTier.sPlus:
        return 0.6;
      case _GradeTier.a:
        return 0.4;
      case _GradeTier.b:
        return 0.2;
      case _GradeTier.c:
      case _GradeTier.d:
        return 0.15;
      case _GradeTier.f:
        return 0.2;
    }
  }

  double _glowRadius(_GradeTier tier) {
    switch (tier) {
      case _GradeTier.sPlus:
        return 24;
      case _GradeTier.a:
        return 18;
      default:
        return 10;
    }
  }

  double _glowSpread(_GradeTier tier) {
    switch (tier) {
      case _GradeTier.sPlus:
        return 4;
      case _GradeTier.a:
        return 2;
      default:
        return 0;
    }
  }

  _GradeTier _gradeTier(String grade) {
    final upper = grade.toUpperCase();
    if (upper == 'S') return _GradeTier.sPlus;
    if (upper.startsWith('A')) return _GradeTier.a;
    if (upper.startsWith('B')) return _GradeTier.b;
    if (upper.startsWith('C')) return _GradeTier.c;
    if (upper.startsWith('D')) return _GradeTier.d;
    return _GradeTier.f;
  }
}

enum _GradeTier { sPlus, a, b, c, d, f }

// ── Subtle rotating particles for S grade ────────────────────────────────────

class _GoldenParticles extends StatefulWidget {
  final double size;
  const _GoldenParticles({required this.size});

  @override
  State<_GoldenParticles> createState() => _GoldenParticlesState();
}

class _GoldenParticlesState extends State<_GoldenParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
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
      builder: (_, __) => CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _ParticlePainter(_controller.value),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  static final _particleAngles = [0.0, 60.0, 120.0, 180.0, 240.0, 300.0];

  _ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;
    final paint = Paint()..color = const Color(0xFFFFD700);

    for (final angleDeg in _particleAngles) {
      final angle = (angleDeg + progress * 360) * math.pi / 180;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      final opacity = (math.sin(progress * math.pi * 2 + angleDeg) * 0.5 + 0.5) * 0.7;
      paint.color = Color.fromRGBO(255, 215, 0, opacity);
      canvas.drawCircle(Offset(x, y), 2, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

// ── GradeRevealWidget (flip animation) ───────────────────────────────────────

class GradeRevealWidget extends StatefulWidget {
  final String grade;
  final double size;

  const GradeRevealWidget({super.key, required this.grade, this.size = 80});

  @override
  State<GradeRevealWidget> createState() => _GradeRevealWidgetState();
}

class _GradeRevealWidgetState extends State<GradeRevealWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flipController;
  late final Animation<double> _flipAnim;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flipAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );

    // Start flip after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        HapticFeedback.mediumImpact();
        _flipController.forward();
      }
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flipAnim,
      builder: (_, __) {
        final angle = _flipAnim.value * math.pi;
        final isShowingFront = angle < math.pi / 2;

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          alignment: Alignment.center,
          child: isShowingFront
              ? _CardBack(size: widget.size)
              : Transform(
                  transform: Matrix4.identity()..rotateY(math.pi),
                  alignment: Alignment.center,
                  child: GradeBadge(grade: widget.grade, size: widget.size),
                ),
        );
      },
    );
  }
}

class _CardBack extends StatelessWidget {
  final double size;
  const _CardBack({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.cardElevated,
        border: Border.all(color: AppColors.borderMedium, width: 2),
      ),
      child: const Center(
        child: Icon(Icons.question_mark_rounded, color: AppColors.textDisabled, size: 28),
      ),
    );
  }
}

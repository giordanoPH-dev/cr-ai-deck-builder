import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../domain/entities/battle.dart';

/// Displays the current win/loss streak derived from [battles] (most-recent first).
///
/// Returns [SizedBox.shrink] when [battles] is empty or the streak length < 2.
class StreakWidget extends StatefulWidget {
  final List<CrBattle> battles;

  const StreakWidget({super.key, required this.battles});

  @override
  State<StreakWidget> createState() => _StreakWidgetState();
}

class _StreakWidgetState extends State<StreakWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.85, end: 1.15).animate(
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
    final result = _computeStreak(widget.battles);
    if (result == null) return const SizedBox.shrink();

    final isWin = result.isWin;
    final count = result.count;
    final color = isWin ? AppColors.success : AppColors.error;
    final bigStreak = count >= 3;

    // Label
    final String label;
    if (isWin) {
      label = bigStreak ? '$count VITÓRIAS' : '$count vitórias';
    } else {
      label = bigStreak ? '$count DERROTAS' : '$count derrotas';
    }

    // Leading icon
    Widget leadingIcon;
    if (isWin && bigStreak) {
      // Fire icon with pulse animation
      leadingIcon = ScaleTransition(
        scale: _pulse,
        child: const Text('🔥', style: TextStyle(fontSize: 18)),
      );
    } else {
      leadingIcon = Icon(
        isWin ? Icons.arrow_upward : Icons.arrow_downward,
        color: color,
        size: 16,
      );
    }

    return Container(
      width: double.infinity,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        boxShadow: bigStreak
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.18),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          leadingIcon,
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: bigStreak ? 0.8 : 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _StreakResult {
  final bool isWin;
  final int count;
  const _StreakResult({required this.isWin, required this.count});
}

/// Iterates [battles] from index 0 (most recent) and counts consecutive identical outcomes.
/// Returns null if fewer than 2 consecutive results of the same type.
_StreakResult? _computeStreak(List<CrBattle> battles) {
  if (battles.isEmpty) return null;

  final first = battles.first;
  final teamCrowns = first.team.isNotEmpty ? first.team.first.crowns : 0;
  final oppCrowns = first.opponent.isNotEmpty ? first.opponent.first.crowns : 0;

  // Draws don't count as either a win or a loss streak
  if (teamCrowns == oppCrowns) return null;

  final firstIsWin = teamCrowns > oppCrowns;
  int count = 1;

  for (int i = 1; i < battles.length; i++) {
    final b = battles[i];
    final tc = b.team.isNotEmpty ? b.team.first.crowns : 0;
    final oc = b.opponent.isNotEmpty ? b.opponent.first.crowns : 0;
    final isWin = tc > oc;
    final isDraw = tc == oc;

    if (isDraw) break; // draws break the streak
    if (isWin != firstIsWin) break;

    count++;
  }

  if (count < 2) return null;
  return _StreakResult(isWin: firstIsWin, count: count);
}

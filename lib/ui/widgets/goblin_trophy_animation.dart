import 'dart:async';
import 'package:flutter/material.dart';

class GoblinTrophyAnimation extends StatefulWidget {
  final double size;
  final Duration interval;

  const GoblinTrophyAnimation({
    super.key,
    this.size = 100,
    this.interval = const Duration(milliseconds: 150),
  });

  @override
  State<GoblinTrophyAnimation> createState() => _GoblinTrophyAnimationState();
}

class _GoblinTrophyAnimationState extends State<GoblinTrophyAnimation> {
  int _currentIndex = 0;
  Timer? _timer;

  final List<String> _images = [
    'assets/images/animations/goblin_trophy/Item_Goblin_Trophy_01.png',
    'assets/images/animations/goblin_trophy/Item_Goblin_Trophy_04.png',
    'assets/images/animations/goblin_trophy/Item_Goblin_Trophy_05.png',
    'assets/images/animations/goblin_trophy/Item_Goblin_Trophy_06.png',
    'assets/images/animations/goblin_trophy/Item_Goblin_Trophy_07.png',
    'assets/images/animations/goblin_trophy/Item_Goblin_Trophy_08.png',
    'assets/images/animations/goblin_trophy/Item_Goblin_Trophy_09.png',
  ];

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() {
    _timer = Timer.periodic(widget.interval, (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _images.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _images[_currentIndex],
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      // Use gaplessPlayback to avoid flickering during image swaps
      gaplessPlayback: true,
    );
  }
}

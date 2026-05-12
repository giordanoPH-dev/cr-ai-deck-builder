import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../blocs/ai_strategy/ai_strategy_cubit.dart';
import '../blocs/player/player_cubit.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  late final Animation<double> _bgFade;
  late final Animation<double> _bgScale;

  late final Animation<double> _glowScale;
  late final Animation<double> _glowOpacity;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;

  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleFade;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // Background: fades in (0–400ms) + subtle zoom out (0–1200ms)
    _bgFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.18, curve: Curves.easeIn),
    );
    _bgScale = Tween<double>(begin: 1.08, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );

    // Golden glow ring: expands and fades (300–1580ms)
    _glowScale = Tween<double>(begin: 0.2, end: 1.6).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.13, 0.62, curve: Curves.easeOut),
      ),
    );
    _glowOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.75), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.75, end: 0.0), weight: 65),
    ]).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.13, 0.75),
      ),
    );

    // Logo: elastic bounce in + fade (400–1200ms)
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.18, 0.62, curve: Curves.elasticOut),
      ),
    );
    _logoFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.18, 0.36, curve: Curves.easeIn),
    );

    // Title: slide up + fade in (990–1650ms)
    _titleFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.7),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
      ),
    );

    // Subtitle: fade in last (1320–2090ms)
    _subtitleFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.6, 0.95, curve: Curves.easeOut),
    );

    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2900), _navigate);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final savedTag = prefs.getString(AppConstants.savedPlayerTagKey) ?? '';

    if (!mounted) return;

    if (savedTag.isNotEmpty) {
      context.read<PlayerCubit>().fetchPlayer(savedTag);
      context.read<AiStrategyCubit>().loadSavedAnalysis(savedTag);
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const ProfileScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const SearchScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Background with zoom-in + fade
              FadeTransition(
                opacity: _bgFade,
                child: Transform.scale(
                  scale: _bgScale.value,
                  child: Image.asset(
                    'assets/images/backgrounds/bg_splash.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Static dark overlay for contrast
              Container(color: Colors.black.withValues(alpha: 0.48)),

              // Center content
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Glow ring + logo stacked
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Golden radial glow pulse
                        Opacity(
                          opacity: _glowOpacity.value,
                          child: Transform.scale(
                            scale: _glowScale.value,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFFFFD700)
                                        .withValues(alpha: 0.9),
                                    const Color(0xFFFF8C00)
                                        .withValues(alpha: 0.45),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.45, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Logo: elastic bounce + fade
                        FadeTransition(
                          opacity: _logoFade,
                          child: ScaleTransition(
                            scale: _logoScale,
                            child: Image.asset(
                              'assets/images/ui_icons/bitmagedev_logo.png',
                              width: 200,
                              height: 200,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 36),

                    // App title
                    SlideTransition(
                      position: _titleSlide,
                      child: FadeTransition(
                        opacity: _titleFade,
                        child: const Text(
                          'ROYALE COACH',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Subtitle
                    FadeTransition(
                      opacity: _subtitleFade,
                      child: const Text(
                        'by BitmageDev',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                          letterSpacing: 2.5,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

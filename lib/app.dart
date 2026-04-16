import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection_container.dart';
import 'presentation/blocs/player/player_cubit.dart';
import 'presentation/blocs/ai_strategy/ai_strategy_cubit.dart';
import 'presentation/blocs/ai_strategy/saved_strategies_cubit.dart';
import 'presentation/screens/search_screen.dart';

/// Root application widget.
///
/// Provides:
/// - MultiBlocProvider for global state access
/// - Material 3 dark theme with Clash Royale branding
/// - Global error boundary (ErrorWidget.builder)
/// - Background image overlay
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PlayerCubit>(create: (_) => sl()),
        BlocProvider<AiStrategyCubit>(create: (_) => sl()),
        BlocProvider<SavedStrategiesCubit>(create: (_) => sl()),
      ],
      child: MaterialApp(
        title: 'CR AI Deck Builder',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Clash',
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blueAccent,
            brightness: Brightness.dark,
          ),
          textTheme: Typography.material2021().white.apply(fontFamily: 'Clash'),
          useMaterial3: true,
        ),
        builder: (context, child) {
          // Global error boundary — ensures no blank "red screen" in production
          ErrorWidget.builder = (FlutterErrorDetails details) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Algo deu errado',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Reinicie o aplicativo.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          };

          return Stack(
            children: [
              // Global Background
              Positioned.fill(
                child: Image.asset(
                  'assets/images/backgrounds/bg.png',
                  fit: BoxFit.cover,
                ),
              ),
              // Semi-transparent overlay
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                ),
              ),
              if (child != null) child,
            ],
          );
        },
        home: const SearchScreen(),
      ),
    );
  }
}

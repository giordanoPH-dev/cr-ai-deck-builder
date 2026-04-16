import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/player.dart';
import '../../../domain/entities/battle.dart';
import '../../../domain/entities/ai_strategy_report.dart';
import '../../../domain/usecases/get_ai_strategy.dart';
import '../../../core/observability/logger_service.dart';
import 'ai_strategy_state.dart';

/// Cubit for managing AI strategy generation state.
///
/// Handles archetype selection and delegates analysis to the
/// [GetAiStrategy] use case.
import '../../../domain/usecases/save_ai_strategy.dart';

// ... class AiStrategyCubit ...
class AiStrategyCubit extends Cubit<AiStrategyState> {
  final GetAiStrategy _getAiStrategy;
  final SaveAiStrategy _saveAiStrategy;
  final LoggerService _logger;

  String _selectedArchetype = 'Aggressive (Beatdown)';
  String get selectedArchetype => _selectedArchetype;

  AiStrategyCubit({
    required GetAiStrategy getAiStrategy,
    required SaveAiStrategy saveAiStrategy,
    required LoggerService logger,
  })  : _getAiStrategy = getAiStrategy,
        _saveAiStrategy = saveAiStrategy,
        _logger = logger,
        super(const AiStrategyInitial());

  /// Saves the current report to the cloud.
  Future<void> saveStrategy({
    required AiStrategyReport report,
    required String playerTag,
  }) async {
    _logger.info('AiStrategyCubit: Saving strategy', metadata: {'tag': playerTag});
    
    final result = await _saveAiStrategy(
      report: report,
      playerTag: playerTag,
    );

    result.fold(
      (failure) => _logger.warn('AiStrategyCubit: Save failed', metadata: {'error': failure.message}),
      (_) => _logger.info('AiStrategyCubit: Save successful'),
    );
  }

  /// Updates the preferred archetype.
  void setArchetype(String archetype) {
    _selectedArchetype = archetype;
    if (state is AiStrategyInitial) {
      emit(AiStrategyInitial(archetype: archetype));
    }
  }

  /// Generates AI strategy for the given player data.
  Future<void> generateStrategy({
    required PlayerProfile profile,
    required List<CrBattle> battles,
  }) async {
    emit(const AiStrategyLoading());
    _logger.info('AiStrategyCubit: Generating strategy', metadata: {
      'player': profile.name,
      'archetype': _selectedArchetype,
    });

    final result = await _getAiStrategy(
      profile: profile,
      battles: battles,
      preferredArchetype: _selectedArchetype,
    );

    result.fold(
      (failure) {
        _logger.warn('AiStrategyCubit: Generation failed', metadata: {
          'failure': failure.message,
        });
        emit(AiStrategyError(failure: failure));
      },
      (report) {
        _logger.info('AiStrategyCubit: Strategy generated', metadata: {
          'confidence': report.confidenceScore,
          'deck_cards': report.suggestedDeckNames.length,
        });
        emit(AiStrategyLoaded(report: report));
      },
    );
  }

  /// Resets state to initial.
  void reset() {
    emit(const AiStrategyInitial());
  }
}

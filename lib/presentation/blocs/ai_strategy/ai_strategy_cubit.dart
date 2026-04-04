import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/player.dart';
import '../../../domain/entities/battle.dart';
import '../../../domain/usecases/get_ai_strategy.dart';
import '../../../core/observability/logger_service.dart';
import 'ai_strategy_state.dart';

/// Cubit for managing AI strategy generation state.
///
/// Handles archetype selection and delegates analysis to the
/// [GetAiStrategy] use case.
class AiStrategyCubit extends Cubit<AiStrategyState> {
  final GetAiStrategy _getAiStrategy;
  final LoggerService _logger;

  String _selectedArchetype = 'Aggressive (Beatdown)';
  String get selectedArchetype => _selectedArchetype;

  AiStrategyCubit({
    required GetAiStrategy getAiStrategy,
    required LoggerService logger,
  })  : _getAiStrategy = getAiStrategy,
        _logger = logger,
        super(const AiStrategyInitial());

  /// Updates the preferred archetype.
  void setArchetype(String archetype) {
    _selectedArchetype = archetype;
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

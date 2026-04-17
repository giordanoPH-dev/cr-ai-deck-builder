import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/player.dart';
import '../../../domain/entities/battle.dart';
import '../../../domain/repositories/ai_repository.dart';
import '../../../domain/usecases/get_ai_strategy.dart';
import '../../../domain/usecases/get_full_analysis.dart';
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
  final GetFullAnalysis _getFullAnalysis;
  final AiRepository _aiRepository;
  final LoggerService _logger;

  AiStrategyCubit({
    required GetAiStrategy getAiStrategy,
    required GetFullAnalysis getFullAnalysis,
    required AiRepository aiRepository,
    required LoggerService logger,
  })  : _getAiStrategy = getAiStrategy,
        _getFullAnalysis = getFullAnalysis,
        _aiRepository = aiRepository,
        _logger = logger,
        super(const AiStrategyInitial());

  /// Generates AI strategy for the given player data.
  Future<void> generateStrategy({
    required PlayerProfile profile,
    required List<CrBattle> battles,
    required String preferredArchetype,
    String languageName = 'English',
  }) async {
    emit(const AiStrategyLoading());
    _logger.info('AiStrategyCubit: Generating strategy', metadata: {
      'player': profile.name,
      'archetype': preferredArchetype,
      'language': languageName,
    });

    final result = await _getAiStrategy(
      profile: profile,
      battles: battles,
      preferredArchetype: preferredArchetype,
      languageName: languageName,
    );

    result.fold(
      (failure) {
        _logger.warn('AiStrategyCubit: Generation failed', metadata: {'failure': failure.message});
        emit(AiStrategyError(failure: failure));
      },
      (report) {
        _logger.info('AiStrategyCubit: Strategy generated', metadata: {
          'confidence': report.confidenceScore,
        });
        emit(AiStrategyLoaded(report: report));
      },
    );
  }

  Future<void> analyzeDeck({
    required PlayerProfile profile,
    required List<CrBattle> battles,
    String languageName = 'English',
  }) async {
    emit(const DeckAnalysisLoading());
    _logger.info('AiStrategyCubit: Analyzing current deck', metadata: {'player': profile.name});

    final result = await _aiRepository.analyzeDeck(
      profile: profile,
      battles: battles,
      languageName: languageName,
    );

    result.fold(
      (failure) => emit(AiStrategyError(failure: failure)),
      (report) => emit(DeckAnalysisLoaded(report: report)),
    );
  }

  Future<void> runFullAnalysis({
    required PlayerProfile profile,
    required List<CrBattle> battles,
    required String preferredArchetype,
    String languageName = 'English',
  }) async {
    emit(const FullAnalysisLoading());
    _logger.info('AiStrategyCubit: Running full analysis', metadata: {
      'player': profile.name,
      'archetype': preferredArchetype,
    });

    final result = await _getFullAnalysis(
      profile: profile,
      battles: battles,
      preferredArchetype: preferredArchetype,
      languageName: languageName,
    );

    if (result.isLeft()) {
      result.fold((failure) => emit(AiStrategyError(failure: failure)), (_) {});
      return;
    }

    final report = result.getOrElse(() => throw StateError('impossible'));
    final now = DateTime.now();
    emit(FullAnalysisLoaded(report: report, savedAt: now, isFromCache: false));

    final saveResult = await _aiRepository.saveAnalysis(playerTag: profile.tag, report: report);
    saveResult.fold(
      (failure) => _logger.warn('AiStrategyCubit: Save failed', metadata: {'error': failure.message}),
      (_) => _logger.info('AiStrategyCubit: Analysis saved', metadata: {'player': profile.name}),
    );
  }

  Future<void> loadSavedAnalysis(String playerTag) async {
    final result = await _aiRepository.loadSavedAnalysis(playerTag: playerTag);
    result.fold(
      (_) {},
      (data) {
        if (data != null) {
          final (report, savedAt) = data;
          emit(FullAnalysisLoaded(report: report, savedAt: savedAt, isFromCache: true));
          _logger.info('AiStrategyCubit: Saved analysis restored', metadata: {'player': playerTag});
        }
      },
    );
  }

  Future<void> clearSavedAnalysis(String playerTag) async {
    await _aiRepository.clearSavedAnalysis(playerTag: playerTag);
    emit(const AiStrategyInitial());
  }

  void reset() => emit(const AiStrategyInitial());
}

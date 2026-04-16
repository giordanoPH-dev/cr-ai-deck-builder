import 'package:dartz/dartz.dart';

import '../../core/constants/app_constants.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/observability/alert_dispatcher.dart';
import '../../core/observability/logger_service.dart';
import '../../domain/entities/ai_strategy_report.dart';
import '../../domain/entities/player.dart';
import '../../domain/entities/battle.dart';
import '../../domain/repositories/ai_repository.dart';
import '../datasources/ai_datasource.dart';
import '../datasources/supabase_datasource.dart';

/// Implementation of [AiRepository] with Supabase sync support.
class AiRepositoryImpl implements AiRepository {
  final AiDatasource datasource;
  final SupabaseDatasource supabaseDatasource;
  final LoggerService logger;
  final AlertDispatcher alertDispatcher;

  AiRepositoryImpl({
    required this.datasource,
    required this.supabaseDatasource,
    required this.logger,
    required this.alertDispatcher,
  });

  @override
  Future<Either<Failure, AiStrategyReport>> generateStrategy({
    required PlayerProfile profile,
    required List<CrBattle> battles,
    required String preferredArchetype,
  }) async {
    if (!datasource.isAvailable) {
      return const Left(LlmFailure(
        message: 'AI service not configured. Please provide a valid Gemini API key.',
        code: 'LLM_NOT_CONFIGURED',
      ));
    }

    LlmException? lastException;

    for (int attempt = 1; attempt <= AppConstants.maxRetries; attempt++) {
      try {
        logger.info('AI strategy generation attempt $attempt/${AppConstants.maxRetries}', metadata: {
          'player': profile.name,
          'archetype': preferredArchetype,
        });

        final report = await datasource.generateStrategy(
          profile: profile,
          battles: battles,
          preferredArchetype: preferredArchetype,
        );

        logger.info('AI strategy generated successfully', metadata: {
          'confidence': report.confidenceScore,
          'deck_size': report.suggestedDeckIds.length,
        });

        return Right(report);
      } on LlmException catch (e) {
        lastException = e;
        logger.warn(
          'AI generation attempt $attempt failed',
          metadata: {
            'attempt': attempt,
            'error': e.message,
            if (e.rawResponse != null) 'raw_preview': e.rawResponse!.length > 100
                ? '${e.rawResponse!.substring(0, 100)}...'
                : e.rawResponse,
          },
        );

        if (attempt < AppConstants.maxRetries) {
          // Wait before retrying
          final delay = AppConstants.retryBaseDelay * (1 << (attempt - 1));
          await Future.delayed(delay);
        }
      } catch (e) {
        lastException = LlmException(message: e.toString());
        logger.error('Unexpected AI error on attempt $attempt', error: e);

        if (attempt < AppConstants.maxRetries) {
          final delay = AppConstants.retryBaseDelay * (1 << (attempt - 1));
          await Future.delayed(delay);
        }
      }
    }

    // All retries exhausted — CRITICAL alert
    alertDispatcher.llmFailure(
      'Gemini failed after ${AppConstants.maxRetries} retries: ${lastException?.message}',
      rawResponse: lastException?.rawResponse,
    );

    logger.critical(
      'AI strategy generation failed after all retries',
      error: lastException,
      metadata: {
        'player': profile.name,
        'archetype': preferredArchetype,
        'retries': AppConstants.maxRetries,
      },
    );

    return Left(LlmFailure(
      message: 'AI analysis failed after ${AppConstants.maxRetries} attempts. '
          'Please try again shortly.',
      rawResponse: lastException?.rawResponse,
    ));
  }

  @override
  Future<Either<Failure, void>> saveStrategy({
    required AiStrategyReport report,
    required String playerTag,
  }) async {
    try {
      await supabaseDatasource.saveAiStrategy(report, playerTag);
      return const Right(null);
    } catch (e) {
      logger.error('Failed to save strategy to Supabase', error: e);
      return Left(DatabaseFailure(
        message: 'Could not save strategy to the cloud: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, List<AiStrategyReport>>> getSavedStrategies(String playerTag) async {
    try {
      final reports = await supabaseDatasource.getSavedAiStrategies(playerTag);
      return Right(reports);
    } catch (e) {
      logger.error('Failed to fetch strategies from Supabase', error: e);
      return Left(DatabaseFailure(
        message: 'Could not load saved strategies: ${e.toString()}',
      ));
    }
  }
}

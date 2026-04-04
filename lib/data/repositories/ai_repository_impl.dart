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

/// Implementation of [AiRepository] with:
/// - Retry logic (up to [AppConstants.maxRetries] attempts)
/// - Hallucination detection via structured JSON parsing
/// - Critical alert dispatch on total failure
class AiRepositoryImpl implements AiRepository {
  final AiDatasource datasource;
  final LoggerService logger;
  final AlertDispatcher alertDispatcher;

  AiRepositoryImpl({
    required this.datasource,
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
        message: 'Serviço de IA não configurado. Forneça uma chave Gemini API válida.',
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
      message: 'A análise de IA falhou após ${AppConstants.maxRetries} tentativas. '
          'Tente novamente em alguns instantes.',
      rawResponse: lastException?.rawResponse,
    ));
  }
}

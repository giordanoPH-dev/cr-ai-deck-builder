import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/observability/alert_dispatcher.dart';
import '../../core/observability/logger_service.dart';
import '../../domain/entities/ai_strategy_report.dart';
import '../../domain/entities/deck_analysis_report.dart';
import '../../domain/entities/full_analysis_report.dart';
import '../../domain/entities/player.dart';
import '../../domain/entities/battle.dart';
import '../../domain/repositories/ai_repository.dart';
import '../datasources/ai_datasource.dart';
import '../datasources/supabase_datasource.dart';
import '../models/ai_strategy_report_model.dart';
import '../models/deck_analysis_report_model.dart';
import '../models/full_analysis_report_model.dart';

/// Implementation of [AiRepository] with Supabase sync and local cache support.
class AiRepositoryImpl implements AiRepository {
  final AiDatasource datasource;
  final SupabaseDatasource supabaseDatasource;
  final LoggerService logger;
  final AlertDispatcher alertDispatcher;
  final SharedPreferences sharedPreferences;

  AiRepositoryImpl({
    required this.datasource,
    required this.supabaseDatasource,
    required this.logger,
    required this.alertDispatcher,
    required this.sharedPreferences,
  });

  static String _analysisKey(String playerTag) => 'saved_analysis_${playerTag.replaceAll('#', '')}';
  static String _analysisDateKey(String playerTag) => 'saved_analysis_date_${playerTag.replaceAll('#', '')}';

  @override
  Future<Either<Failure, AiStrategyReport>> generateStrategy({
    required PlayerProfile profile,
    required List<CrBattle> battles,
    required String preferredArchetype,
    required String languageName,
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
          languageName: languageName,
        );

        logger.info('AI strategy generated successfully', metadata: {
          'confidence': report.confidenceScore,
          'deck_size': report.suggestedDeckIds.length,
        });

        return Right(report);
      } on LlmException catch (e) {
        lastException = e;

        if (_isQuotaError(e.message)) {
          logger.warn('Gemini quota exceeded — aborting retries', metadata: {'error': e.message});
          return const Left(LlmFailure(
            message: 'Limite da API Gemini atingido. Aguarde alguns minutos e tente novamente, ou verifique seu plano em ai.google.dev.',
            code: 'LLM_QUOTA_EXCEEDED',
          ));
        }

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
      message: 'Análise de IA falhou após ${AppConstants.maxRetries} tentativas. Tente novamente.',
      rawResponse: lastException?.rawResponse,
    ));
  }

  @override
  Future<Either<Failure, DeckAnalysisReport>> analyzeDeck({
    required PlayerProfile profile,
    required List<CrBattle> battles,
    required String languageName,
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
        final report = await datasource.analyzeDeck(
          profile: profile,
          battles: battles,
          languageName: languageName,
        );
        return Right(report);
      } on LlmException catch (e) {
        lastException = e;
        if (_isQuotaError(e.message)) {
          return const Left(LlmFailure(
            message: 'Limite da API Gemini atingido. Tente novamente mais tarde.',
            code: 'LLM_QUOTA_EXCEEDED',
          ));
        }
        if (attempt < AppConstants.maxRetries) {
          await Future.delayed(AppConstants.retryBaseDelay * (1 << (attempt - 1)));
        }
      } catch (e) {
        lastException = LlmException(message: e.toString());
        if (attempt < AppConstants.maxRetries) {
          await Future.delayed(AppConstants.retryBaseDelay * (1 << (attempt - 1)));
        }
      }
    }

    return Left(LlmFailure(
      message: 'Análise falhou após ${AppConstants.maxRetries} tentativas.',
      rawResponse: lastException?.rawResponse,
    ));
  }

  @override
  Future<Either<Failure, FullAnalysisReport>> getFullAnalysis({
    required PlayerProfile profile,
    required List<CrBattle> battles,
    required String preferredArchetype,
    required String languageName,
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
        final report = await datasource.getFullAnalysis(
          profile: profile,
          battles: battles,
          preferredArchetype: preferredArchetype,
          languageName: languageName,
        );

        final elixirs = profile.currentDeck
            .where((c) => c.elixirCost != null)
            .map((c) => c.elixirCost!.toDouble())
            .toList();
        final actualAvgElixir = elixirs.isEmpty
            ? report.deckAnalysis.avgElixir
            : elixirs.reduce((a, b) => a + b) / elixirs.length;

        return Right(FullAnalysisReportModel(
          strategy: report.strategy as AiStrategyReportModel,
          deckAnalysis: (report.deckAnalysis as DeckAnalysisReportModel)
              .copyWith(avgElixir: actualAvgElixir),
        ));
      } on LlmException catch (e) {
        lastException = e;
        if (_isQuotaError(e.message)) {
          return const Left(LlmFailure(
            message: 'Limite da API Gemini atingido. Tente novamente mais tarde.',
            code: 'LLM_QUOTA_EXCEEDED',
          ));
        }
        if (attempt < AppConstants.maxRetries) {
          await Future.delayed(AppConstants.retryBaseDelay * (1 << (attempt - 1)));
        }
      } catch (e) {
        lastException = LlmException(message: e.toString());
        if (attempt < AppConstants.maxRetries) {
          await Future.delayed(AppConstants.retryBaseDelay * (1 << (attempt - 1)));
        }
      }
    }

    return Left(LlmFailure(
      message: 'Análise falhou após ${AppConstants.maxRetries} tentativas.',
      rawResponse: lastException?.rawResponse,
    ));
  }

  @override
  Future<Either<Failure, Unit>> saveAnalysis({
    required String playerTag,
    required FullAnalysisReport report,
  }) async {
    try {
      final model = report is FullAnalysisReportModel
          ? report
          : FullAnalysisReportModel(strategy: report.strategy, deckAnalysis: report.deckAnalysis);
      final json = jsonEncode(model.toJson());
      await sharedPreferences.setString(_analysisKey(playerTag), json);
      await sharedPreferences.setString(_analysisDateKey(playerTag), DateTime.now().toIso8601String());
      logger.info('Analysis saved for player $playerTag');
      return const Right(unit);
    } catch (e) {
      logger.warn('Failed to save analysis', metadata: {'error': e.toString()});
      return Left(CacheFailure(message: 'Could not save analysis: $e'));
    }
  }

  @override
  Future<Either<Failure, (FullAnalysisReport, DateTime)?>> loadSavedAnalysis({
    required String playerTag,
  }) async {
    try {
      final json = sharedPreferences.getString(_analysisKey(playerTag));
      if (json == null) return const Right(null);

      final dateStr = sharedPreferences.getString(_analysisDateKey(playerTag));
      final savedAt = dateStr != null ? DateTime.tryParse(dateStr) ?? DateTime.now() : DateTime.now();

      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final report = FullAnalysisReportModel.fromJson(decoded);
      logger.info('Saved analysis loaded for player $playerTag', metadata: {'saved_at': dateStr});
      return Right((report, savedAt));
    } catch (e) {
      logger.warn('Failed to load saved analysis', metadata: {'error': e.toString()});
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, Unit>> clearSavedAnalysis({required String playerTag}) async {
    try {
      await sharedPreferences.remove(_analysisKey(playerTag));
      await sharedPreferences.remove(_analysisDateKey(playerTag));
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure(message: 'Could not clear analysis: $e'));
    }
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

  bool _isQuotaError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('quota') ||
        lower.contains('resource_exhausted') ||
        lower.contains('rate limit') ||
        lower.contains('exceeded your current quota');
  }
}

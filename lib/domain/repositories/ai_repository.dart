import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/ai_strategy_report.dart';
import '../entities/player.dart';
import '../entities/battle.dart';

/// Contract for AI strategy generation.
abstract class AiRepository {
  /// Generates a strategy report using the LLM.
  ///
  /// Includes retry logic and hallucination detection at the data layer.
  /// Returns [LlmFailure] if the LLM fails after all retries.
  Future<Either<Failure, AiStrategyReport>> generateStrategy({
    required PlayerProfile profile,
    required List<CrBattle> battles,
    required String preferredArchetype,
  });

  /// Saves a generated strategy to the cloud (Supabase).
  Future<Either<Failure, void>> saveStrategy({
    required AiStrategyReport report,
    required String playerTag,
  });

  /// Fetches saved strategies for a player.
  Future<Either<Failure, List<AiStrategyReport>>> getSavedStrategies(String playerTag);
}

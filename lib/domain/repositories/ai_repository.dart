import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/ai_strategy_report.dart';
import '../entities/deck_analysis_report.dart';
import '../entities/full_analysis_report.dart';
import '../entities/player.dart';
import '../entities/battle.dart';

abstract class AiRepository {
  Future<Either<Failure, AiStrategyReport>> generateStrategy({
    required PlayerProfile profile,
    required List<CrBattle> battles,
    required String preferredArchetype,
    required String languageName,
  });

  Future<Either<Failure, DeckAnalysisReport>> analyzeDeck({
    required PlayerProfile profile,
    required List<CrBattle> battles,
    required String languageName,
  });

  Future<Either<Failure, FullAnalysisReport>> getFullAnalysis({
    required PlayerProfile profile,
    required List<CrBattle> battles,
    required String preferredArchetype,
    required String languageName,
  });

  Future<Either<Failure, Unit>> saveAnalysis({
    required String playerTag,
    required FullAnalysisReport report,
  });

  /// Returns null when no saved analysis exists for this player.
  Future<Either<Failure, (FullAnalysisReport, DateTime)?>> loadSavedAnalysis({
    required String playerTag,
  });

  Future<Either<Failure, Unit>> clearSavedAnalysis({required String playerTag});

  /// Saves a generated strategy to the cloud (Supabase).
  Future<Either<Failure, void>> saveStrategy({
    required AiStrategyReport report,
    required String playerTag,
  });

  /// Fetches saved strategies for a player.
  Future<Either<Failure, List<AiStrategyReport>>> getSavedStrategies(String playerTag);
}

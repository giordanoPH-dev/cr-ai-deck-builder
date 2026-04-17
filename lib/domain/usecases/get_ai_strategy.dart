import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/ai_strategy_report.dart';
import '../entities/player.dart';
import '../entities/battle.dart';
import '../repositories/ai_repository.dart';

/// Use case: Generate AI strategy report for a player.
///
/// Business rules applied here:
/// - Player must have at least 8 cards in collection
/// - Battles list should not be empty for meaningful analysis
class GetAiStrategy {
  final AiRepository repository;

  GetAiStrategy({required this.repository});

  Future<Either<Failure, AiStrategyReport>> call({
    required PlayerProfile profile,
    required List<CrBattle> battles,
    required String preferredArchetype,
    required String languageName,
  }) async {
    if (profile.cards.length < 8) {
      return const Left(LlmFailure(
        message: 'Player collection has fewer than 8 cards. Cannot suggest a full deck.',
        code: 'INSUFFICIENT_CARDS',
      ));
    }

    return repository.generateStrategy(
      profile: profile,
      battles: battles,
      preferredArchetype: preferredArchetype,
      languageName: languageName,
    );
  }
}

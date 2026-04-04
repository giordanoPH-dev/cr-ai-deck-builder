import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/player.dart';
import '../entities/battle.dart';

/// Contract for player data access.
///
/// The domain layer defines WHAT data it needs,
/// the data layer decides HOW to get it (API, cache, etc.).
abstract class PlayerRepository {
  /// Fetches the player profile by tag.
  /// Returns cached data if offline and cache is available.
  Future<Either<Failure, PlayerProfile>> getPlayerProfile(String tag);

  /// Fetches the player's recent battle log.
  /// Returns cached data if offline and cache is available.
  Future<Either<Failure, List<CrBattle>>> getPlayerBattleLog(String tag);
}

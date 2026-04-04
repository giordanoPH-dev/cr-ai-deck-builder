import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/player.dart';
import '../entities/battle.dart';
import '../repositories/player_repository.dart';

/// Use case: Fetch player profile and battle log in parallel.
///
/// Orchestrates data fetching and returns both results together.
/// If either call fails, the failure is propagated.
class GetPlayerProfile {
  final PlayerRepository repository;

  GetPlayerProfile({required this.repository});

  Future<Either<Failure, PlayerData>> call(String tag) async {
    final results = await Future.wait([
      repository.getPlayerProfile(tag),
      repository.getPlayerBattleLog(tag),
    ]);

    final profileResult = results[0] as Either<Failure, PlayerProfile>;
    final battlesResult = results[1] as Either<Failure, List<CrBattle>>;

    return profileResult.fold(
      (failure) => Left(failure),
      (profile) => battlesResult.fold(
        (failure) => Left(failure),
        (battles) => Right(PlayerData(profile: profile, battles: battles)),
      ),
    );
  }
}

/// Value object combining profile + battles for a single return.
class PlayerData {
  final PlayerProfile profile;
  final List<CrBattle> battles;

  const PlayerData({required this.profile, required this.battles});
}

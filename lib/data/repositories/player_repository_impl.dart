import 'package:dartz/dartz.dart';

import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/network/network_info.dart';
import '../../core/observability/alert_dispatcher.dart';
import '../../core/observability/logger_service.dart';
import '../../domain/entities/player.dart';
import '../../domain/entities/battle.dart';
import '../../domain/repositories/player_repository.dart';
import '../datasources/clash_api_datasource.dart';
import '../datasources/player_local_datasource.dart';

/// Implementation of [PlayerRepository] with:
/// - Network connectivity check (fail-fast offline)
/// - Automatic cache on success
/// - Fallback to cache when offline
/// - Typed error conversion (Exception → Failure)
class PlayerRepositoryImpl implements PlayerRepository {
  final ClashApiDatasource remoteDatasource;
  final PlayerLocalDatasource localDatasource;
  final NetworkInfo networkInfo;
  final LoggerService logger;
  final AlertDispatcher alertDispatcher;

  PlayerRepositoryImpl({
    required this.remoteDatasource,
    required this.localDatasource,
    required this.networkInfo,
    required this.logger,
    required this.alertDispatcher,
  });

  @override
  Future<Either<Failure, PlayerProfile>> getPlayerProfile(String tag) async {
    if (await networkInfo.isConnected) {
      try {
        final profile = await remoteDatasource.getPlayerProfile(tag);
        // Cache on success for offline fallback
        await localDatasource.cacheProfile(profile);
        logger.info('Player profile fetched and cached', metadata: {'tag': tag});
        return Right(profile);
      } on ServerException catch (e) {
        if (e.statusCode == 404) {
          return const Left(PlayerNotFoundFailure());
        }
        alertDispatcher.apiFailure('/players/$tag', e.statusCode);
        return Left(ServerFailure(
          message: _mapStatusCodeToMessage(e.statusCode),
          statusCode: e.statusCode,
        ));
      } on NetworkException {
        return _tryProfileFromCache(tag);
      } catch (e) {
        logger.error('Unexpected error fetching profile', error: e);
        return Left(UnknownFailure(message: 'Erro inesperado: $e'));
      }
    } else {
      // Offline — try cache
      return _tryProfileFromCache(tag);
    }
  }

  @override
  Future<Either<Failure, List<CrBattle>>> getPlayerBattleLog(String tag) async {
    if (await networkInfo.isConnected) {
      try {
        final battles = await remoteDatasource.getPlayerBattleLog(tag);
        // Cache on success
        await localDatasource.cacheBattleLog(battles);
        logger.info('Battle log fetched and cached', metadata: {'tag': tag, 'count': battles.length});
        return Right(battles);
      } on ServerException catch (e) {
        alertDispatcher.apiFailure('/players/$tag/battlelog', e.statusCode);
        return Left(ServerFailure(
          message: _mapStatusCodeToMessage(e.statusCode),
          statusCode: e.statusCode,
        ));
      } on NetworkException {
        return _tryBattlesFromCache(tag);
      } catch (e) {
        logger.error('Unexpected error fetching battle log', error: e);
        return Left(UnknownFailure(message: 'Erro inesperado: $e'));
      }
    } else {
      return _tryBattlesFromCache(tag);
    }
  }

  Future<Either<Failure, PlayerProfile>> _tryProfileFromCache(String tag) async {
    logger.info('Attempting to load profile from cache', metadata: {'tag': tag});
    final cached = await localDatasource.getCachedProfile();
    if (cached != null) {
      logger.info('Serving cached profile', metadata: {'tag': cached.tag});
      return Right(cached);
    }
    return const Left(NetworkFailure());
  }

  Future<Either<Failure, List<CrBattle>>> _tryBattlesFromCache(String tag) async {
    logger.info('Attempting to load battles from cache', metadata: {'tag': tag});
    final cached = await localDatasource.getCachedBattleLog();
    if (cached != null) {
      logger.info('Serving cached battle log', metadata: {'count': cached.length});
      return Right(cached);
    }
    return const Left(NetworkFailure());
  }

  String _mapStatusCodeToMessage(int statusCode) {
    switch (statusCode) {
      case 403:
        return 'Acesso à API negado. Verifique a chave de API.';
      case 404:
        return 'Jogador não encontrado.';
      case 429:
        return 'Limite de requisições excedido. Aguarde um momento.';
      case >= 500:
        return 'Servidores do Clash Royale em manutenção. Tente novamente.';
      default:
        return 'Erro na API: $statusCode';
    }
  }
}

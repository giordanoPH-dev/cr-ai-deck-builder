import '../../core/constants/app_constants.dart';
import '../../core/error/exceptions.dart';
import '../../core/network/http_client.dart';
import '../../core/observability/logger_service.dart';
import '../models/player_model.dart';
import '../models/battle_model.dart';

/// Remote data source for the Clash Royale API.
///
/// Uses [ResilientHttpClient] for automatic retry and timeout handling.
/// Throws typed exceptions ([ServerException], [NetworkException])
/// that the repository converts to [Failure] objects.
abstract class ClashApiDatasource {
  Future<PlayerProfileModel> getPlayerProfile(String tag);
  Future<List<CrBattleModel>> getPlayerBattleLog(String tag);
}

class ClashApiDatasourceImpl implements ClashApiDatasource {
  final ResilientHttpClient httpClient;
  final LoggerService logger;
  final String apiKey;

  ClashApiDatasourceImpl({
    required this.httpClient,
    required this.logger,
    required this.apiKey,
  });

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $apiKey',
        'Accept': 'application/json',
      };

  String _formatTag(String tag) {
    final cleaned = tag.startsWith('#') ? tag.substring(1) : tag;
    return '%23$cleaned';
  }

  @override
  Future<PlayerProfileModel> getPlayerProfile(String tag) async {
    final formattedTag = _formatTag(tag);
    final url = '${AppConstants.clashApiBaseUrl}/players/$formattedTag';

    logger.info('Fetching player profile', metadata: {'tag': tag});

    try {
      final json = await httpClient.get(url, headers: _headers);
      return PlayerProfileModel.fromJson(json);
    } on ServerException catch (e) {
      if (e.statusCode == 404) {
        throw const ServerException(
          message: 'Player not found',
          statusCode: 404,
        );
      }
      rethrow;
    }
  }

  @override
  Future<List<CrBattleModel>> getPlayerBattleLog(String tag) async {
    final formattedTag = _formatTag(tag);
    final url = '${AppConstants.clashApiBaseUrl}/players/$formattedTag/battlelog';

    logger.info('Fetching battle log', metadata: {'tag': tag});

    final jsonList = await httpClient.getList(url, headers: _headers);
    return jsonList
        .map((e) => CrBattleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/error/exceptions.dart';
import '../../core/observability/logger_service.dart';
import '../models/player_model.dart';
import '../models/battle_model.dart';

/// Local data source using SharedPreferences for offline cache.
///
/// Stores the last-fetched player profile and battle log so the app
/// can display data even when offline — critical for kiosk resilience.
abstract class PlayerLocalDatasource {
  Future<PlayerProfileModel?> getCachedProfile();
  Future<List<CrBattleModel>?> getCachedBattleLog();
  Future<void> cacheProfile(PlayerProfileModel profile);
  Future<void> cacheBattleLog(List<CrBattleModel> battles);
}

class PlayerLocalDatasourceImpl implements PlayerLocalDatasource {
  final SharedPreferences sharedPreferences;
  final LoggerService logger;

  PlayerLocalDatasourceImpl({
    required this.sharedPreferences,
    required this.logger,
  });

  @override
  Future<PlayerProfileModel?> getCachedProfile() async {
    try {
      final jsonStr = sharedPreferences.getString(AppConstants.cachedProfileKey);
      if (jsonStr == null) return null;

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      logger.info('Loaded cached profile', metadata: {'tag': json['tag']});
      return PlayerProfileModel.fromCacheJson(json);
    } catch (e) {
      logger.warn('Failed to load cached profile', metadata: {'error': e.toString()});
      return null;
    }
  }

  @override
  Future<List<CrBattleModel>?> getCachedBattleLog() async {
    try {
      final jsonStr = sharedPreferences.getString(AppConstants.cachedBattleLogKey);
      if (jsonStr == null) return null;

      final jsonList = jsonDecode(jsonStr) as List;
      logger.info('Loaded cached battle log', metadata: {'count': jsonList.length});
      return jsonList
          .map((e) => CrBattleModel.fromCacheJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logger.warn('Failed to load cached battle log', metadata: {'error': e.toString()});
      return null;
    }
  }

  @override
  Future<void> cacheProfile(PlayerProfileModel profile) async {
    try {
      final jsonStr = jsonEncode(profile.toJson());
      await sharedPreferences.setString(AppConstants.cachedProfileKey, jsonStr);
      logger.info('Cached profile', metadata: {'tag': profile.tag});
    } catch (e) {
      logger.warn('Failed to cache profile', metadata: {'error': e.toString()});
      throw CacheException(message: 'Failed to cache profile: $e');
    }
  }

  @override
  Future<void> cacheBattleLog(List<CrBattleModel> battles) async {
    try {
      final jsonStr = jsonEncode(battles.map((b) => b.toJson()).toList());
      await sharedPreferences.setString(AppConstants.cachedBattleLogKey, jsonStr);
      logger.info('Cached battle log', metadata: {'count': battles.length});
    } catch (e) {
      logger.warn('Failed to cache battle log', metadata: {'error': e.toString()});
      throw CacheException(message: 'Failed to cache battle log: $e');
    }
  }
}

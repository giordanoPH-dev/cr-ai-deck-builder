import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/ai_datasource.dart';
import '../../data/datasources/clash_api_datasource.dart';
import '../../data/datasources/player_local_datasource.dart';
import '../../data/datasources/supabase_datasource.dart';
import '../../data/repositories/ai_repository_impl.dart';
import '../../data/repositories/player_repository_impl.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../domain/repositories/player_repository.dart';
import '../../domain/usecases/get_ai_strategy.dart';
import '../../domain/usecases/get_full_analysis.dart';
import '../../domain/usecases/get_player_profile.dart';
import '../../domain/usecases/save_ai_strategy.dart';
import '../../domain/usecases/get_saved_strategies.dart';
import '../../presentation/blocs/ai_strategy/ai_strategy_cubit.dart';
import '../../presentation/blocs/ai_strategy/saved_strategies_cubit.dart';
import '../../presentation/blocs/player/player_cubit.dart';
import '../../services/ad_service.dart';
import '../network/http_client.dart';
import '../network/network_info.dart';
import '../observability/alert_dispatcher.dart';
import '../observability/logger_service.dart';

final GetIt sl = GetIt.instance;

/// Initializes all dependencies using the Service Locator pattern.
///
/// Registration order: External → Core → DataSources → Repositories → UseCases → Cubits
Future<void> initDependencies() async {
  // ── Supabase Auth ────────────────────────────────────────────
  try {
    await Supabase.instance.client.auth.signInAnonymously();
  } on AuthException catch (e) {
    debugPrint('Notice: Supabase anonymous sign-in failed: ${e.message}');
  } catch (e) {
    debugPrint('Notice: Supabase anonymous sign-in failed: $e');
  }

  // ── External ────────────────────────────────────────────────
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => Connectivity());

  // ── Core ────────────────────────────────────────────────────
  sl.registerLazySingleton<AlertDispatcher>(() => AlertDispatcher());

  sl.registerLazySingleton<LoggerService>(() => LoggerServiceImpl(
        onCritical: (event) => sl<AlertDispatcher>().dispatch(
          event: event['event'] as String? ?? 'UNKNOWN',
          message: event['message'] as String? ?? 'No message',
          severity: event['severity'] as String? ?? 'CRITICAL',
        ),
      ));

  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(connectivity: sl()),
  );

  sl.registerLazySingleton<ResilientHttpClient>(
    () => ResilientHttpClient(logger: sl()),
  );

  // ── Data Sources ────────────────────────────────────────────
  final clashApiKey = dotenv.env['CLASH_ROYALE_API_KEY'] ?? '';
  final geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  sl.registerLazySingleton<ClashApiDatasource>(
    () => ClashApiDatasourceImpl(
      httpClient: sl(),
      logger: sl(),
      apiKey: clashApiKey,
    ),
  );

  sl.registerLazySingleton<AiDatasource>(
    () => AiDatasourceImpl(
      apiKey: geminiApiKey,
      logger: sl(),
    ),
  );

  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  sl.registerLazySingleton<SupabaseDatasource>(
    () => SupabaseDatasourceImpl(
      supabase: sl(),
      logger: sl(),
    ),
  );

  sl.registerLazySingleton<PlayerLocalDatasource>(
    () => PlayerLocalDatasourceImpl(
      sharedPreferences: sl(),
      logger: sl(),
    ),
  );

  // ── Services ────────────────────────────────────────────────
  sl.registerLazySingleton<AdService>(() => AdService());

  // ── Repositories ────────────────────────────────────────────
  sl.registerLazySingleton<PlayerRepository>(
    () => PlayerRepositoryImpl(
      remoteDatasource: sl(),
      localDatasource: sl(),
      networkInfo: sl(),
      logger: sl(),
      alertDispatcher: sl(),
    ),
  );

  sl.registerLazySingleton<AiRepository>(
    () => AiRepositoryImpl(
      datasource: sl(),
      supabaseDatasource: sl(),
      logger: sl(),
      alertDispatcher: sl(),
      sharedPreferences: sl(),
    ),
  );

  // ── Use Cases ───────────────────────────────────────────────
  sl.registerLazySingleton(() => GetPlayerProfile(repository: sl()));
  sl.registerLazySingleton(() => GetAiStrategy(repository: sl()));
  sl.registerLazySingleton(() => GetFullAnalysis(repository: sl()));
  sl.registerLazySingleton(() => SaveAiStrategy(repository: sl()));
  sl.registerLazySingleton(() => GetSavedStrategies(repository: sl()));

  // ── Cubits (factory = new instance per widget tree) ─────────
  sl.registerFactory(() => PlayerCubit(
        getPlayerProfile: sl(),
        logger: sl(),
      ));

  sl.registerFactory(() => AiStrategyCubit(
        getAiStrategy: sl(),
        getFullAnalysis: sl(),
        aiRepository: sl(),
        logger: sl(),
      ));

  sl.registerFactory(() => SavedStrategiesCubit(
        getSavedStrategies: sl(),
        logger: sl(),
      ));
}

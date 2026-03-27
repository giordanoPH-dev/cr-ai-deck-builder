import 'package:get_it/get_it.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/clash_api_service.dart';
import '../viewmodels/player_viewmodel.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  final apiKey = dotenv.env['CLASH_ROYALE_API_KEY'] ?? '';

  // Services
  locator.registerLazySingleton<ClashApiService>(() => ClashApiService(apiKey: apiKey));
  
  // ViewModels
  locator.registerFactory<PlayerViewModel>(() => PlayerViewModel(locator<ClashApiService>()));
}


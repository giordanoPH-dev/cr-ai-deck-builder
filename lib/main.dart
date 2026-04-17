import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/di/injection_container.dart';
import 'core/observability/logger_service.dart';
import 'services/ad_service.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await dotenv.load(fileName: ".env");

  try {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
  } catch (_) {
    // App continues without Supabase if init fails
  }

  // Initialize all dependencies
  await initDependencies();

  final logger = sl<LoggerService>();
  logger.info('Application starting', metadata: {
    'platform': kIsWeb ? 'web' : 'mobile',
  });

  // Initialize Ads (only on mobile)
  if (!kIsWeb) {
    try {
      await sl<AdService>().init();
      logger.info('AdMob initialized successfully');
    } catch (e) {
      logger.warn('AdMob initialization failed', metadata: {'error': e.toString()});
    }
  }

  FlutterNativeSplash.remove();
  runApp(const App());
}

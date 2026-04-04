import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'core/di/injection_container.dart';
import 'core/observability/logger_service.dart';
import 'services/ad_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

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

  runApp(const App());
}

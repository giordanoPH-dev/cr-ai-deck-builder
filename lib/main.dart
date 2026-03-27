import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'core/locator.dart';
import 'viewmodels/player_viewmodel.dart';
import 'ui/screens/search_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  setupLocator(); // Initialize dependency injection
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => locator<PlayerViewModel>(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CR AI Deck Builder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Clash',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
        ),
        textTheme: Typography.material2021().white.apply(fontFamily: 'Clash'),
        useMaterial3: true,
      ),
      home: const SearchScreen(),
    );
  }
}

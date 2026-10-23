import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://vyiywiteeqkyuroqftkn.supabase.co',
    publishableKey: 'sb_publishable_4kzJ5yc7xLUPXBYoe2V0iQ_YyKEDiDp',
  );
  final prefs = await SharedPreferences.getInstance();
  final welcomeSeen = prefs.getBool('welcome_seen') ?? false;
  runApp(SayidaRozqiApp(showWelcome: !welcomeSeen));
}

class SayidaRozqiApp extends StatelessWidget {
  final bool showWelcome;
  const SayidaRozqiApp({super.key, required this.showWelcome});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'السيدة رزقي',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: showWelcome ? const SplashScreen() : const HomeScreen(),
    );
  }
}

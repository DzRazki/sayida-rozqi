import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://vyiywiteeqkyuroqftkn.supabase.co',
    anonKey: 'sb_publishable_4kzJ5yc7xLUPXBYoe2V0iQ_YyKEDiDp',
  );
  runApp(const SayidaRozqiApp());
}

class SayidaRozqiApp extends StatelessWidget {
  const SayidaRozqiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'السيدة رزقي',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}

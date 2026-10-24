import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  Widget build(BuildContext context) => MaterialApp(
    title: 'السيدة رزقي',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    builder: (context, child) => Directionality(
      textDirection: TextDirection.rtl,
      child: ColoredBox(color: AppColors.cream, child: SafeArea(
        top: false, left: false, right: false,
        child: child ?? const SizedBox.shrink(),
      )),
    ),
    home: SplashScreen(showWelcome: showWelcome),
  );
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _start(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('welcome_seen', true);
    if (!context.mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.darkBrown, AppColors.brown])),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 108, height: 108, decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle), child: const Center(child: Text('🍲', style: TextStyle(fontSize: 48)))),
              const SizedBox(height: 22),
              const Text('السيدة رزقي', style: TextStyle(color: AppColors.gold, fontSize: 32, fontWeight: FontWeight.bold)),
              const Text('أشهى الوصفات الجزائرية', style: TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 14),
              const Text('اكتشفي عالم الوصفات الجزائرية\nوصفات تقليدية عصرية ومجربة بكل حب', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, height: 1.7)),
              const SizedBox(height: 30),
              SizedBox(width: double.infinity, child: FilledButton(onPressed: () => _start(context), child: const Text('ابدأ الآن', style: TextStyle(fontWeight: FontWeight.bold)))),
            ]),
          ),
        ),
      ),
    );
  }
}

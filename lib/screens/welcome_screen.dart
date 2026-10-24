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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.darkBrown, AppColors.brown],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .28),
                        blurRadius: 32,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(child: Text('🍲', style: TextStyle(fontSize: 56))),
                ),
                const SizedBox(height: 28),
                const Text(
                  'السيدة رزقي',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.gold, fontSize: 36, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'وصفات جزائرية أصلية',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                const Text(
                  'اكتشفي أشهى الوصفات الجزائرية التقليدية والعصرية،\nمجربة بكل حب وخطوات واضحة.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, height: 1.7, fontSize: 15),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _start(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.darkBrown,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    icon: const Icon(Icons.restaurant_menu),
                    label: const Text('ابدأ الآن', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 108,
                  height: 108,
                  decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                  child: const Center(child: Text('🍲', style: TextStyle(fontSize: 48))),
                ),
                const SizedBox(height: 22),
                const Text('السيدة رزقي', style: TextStyle(color: AppColors.gold, fontSize: 32, fontWeight: FontWeight.bold)),
                const Text('أشهى الوصفات الجزائرية', style: TextStyle(color: Colors.white, fontSize: 18)),
                const SizedBox(height: 14),
                const Text('اكتشفي عالم الوصفات الجزائرية\nوصفات تقليدية عصرية ومجربة بكل حب', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, height: 1.7)),
                const SizedBox(height: 28),
                _Feature(icon: Icons.play_circle_outline, title: 'فيديوهات تعليمية', subtitle: 'لتسهيل التحضير'),
                _Feature(icon: Icons.list_alt, title: 'مكونات واضحة', subtitle: 'بكل التفاصيل'),
                _Feature(icon: Icons.verified_outlined, title: 'وصفات موثوقة', subtitle: 'مجربة ومضمونة'),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen())),
                    child: const Text('ابدأ الآن', style: TextStyle(fontWeight: FontWeight.bold)),
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

class _Feature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _Feature({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white.withOpacity(.08), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gold),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12))])),
        ],
      ),
    );
  }
}

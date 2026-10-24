import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../widgets/brand_logo.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}
class _WelcomeScreenState extends State<WelcomeScreen> {
  bool starting = false;
  Future<void> start() async {
    if (starting) return;
    setState(() => starting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setBool('welcome_seen', true)) throw StateError('Preference not saved');
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const HomeScreen()));
    } catch (_) {
      if (mounted) {
        setState(() => starting = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر بدء التطبيق. حاولي مجددًا.')));
      }
    }
  }
  Widget feature(IconData icon, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 18, color: AppColors.brown),
    const SizedBox(width: 5),
    Text(label, style: const TextStyle(color: AppColors.darkBrown, fontSize: 12)),
  ]);
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.cream,
    body: SafeArea(child: LayoutBuilder(builder: (context, constraints) => SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFF21150F), Color(0xFF503322)]),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(42)),
          ),
          child: Center(child: BrandLogo(size: (constraints.maxWidth * .64).clamp(140.0, 270.0).toDouble())),
        ),
        Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(children: [
            const Text('مرحبًا بكِ في مطبخ\nالسيدة رزقي', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 26, height: 1.35, fontWeight: FontWeight.bold, color: AppColors.darkBrown)),
            const SizedBox(height: 12),
            const Text('وصفات جزائرية تقليدية وعصرية،\nبخطوات واضحة ولمسة منزلية.', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.6, color: AppColors.brown)),
            const SizedBox(height: 20),
            Wrap(alignment: WrapAlignment.center, spacing: 14, runSpacing: 10, children: [
              feature(Icons.restaurant_menu, 'وصفات متنوعة'),
              feature(Icons.check_circle_outline, 'خطوات سهلة'),
              feature(Icons.favorite_border, 'مفضّلتك معك'),
            ]),
            const SizedBox(height: 26),
            SizedBox(width: double.infinity, child: FilledButton.icon(
              onPressed: starting ? null : start,
              style: FilledButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.darkBrown,
                padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text(starting ? 'لحظات…' : 'اكتشفي الوصفات', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            )),
            const SizedBox(height: 10),
            const Text('تصفّحي الوصفات دون إنشاء حساب', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.brown)),
          ]),
        ))),
      ]),
    ))),
  );
}

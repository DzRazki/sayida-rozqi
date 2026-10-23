import 'package:flutter/material.dart';
import '../theme.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBrown,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(.25), blurRadius: 24)],
              ),
              child: const Center(child: Text('🍲', style: TextStyle(fontSize: 54))),
            ),
            const SizedBox(height: 24),
            const Text('السيدة رزقي', style: TextStyle(color: AppColors.gold, fontSize: 30, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('وصفات جزائرية أصيلة', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

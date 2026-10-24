import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/brand_logo.dart';
import 'home_screen.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  final bool showWelcome;
  const SplashScreen({super.key, this.showWelcome = true});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen> {
  Timer? timer;
  @override
  void initState() {
    super.initState();
    timer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
        builder: (_) => widget.showWelcome ? const WelcomeScreen() : const HomeScreen(),
      ));
    });
  }
  @override
  void dispose() { timer?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.darkBrown,
    body: Container(
      width: double.infinity, height: double.infinity,
      decoration: const BoxDecoration(gradient: RadialGradient(
        colors: [Color(0xFF593A24), Color(0xFF21150F)], radius: 1.1,
      )),
      child: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
        final size = (constraints.maxWidth * .78).clamp(140.0, 320.0).toDouble();
        return SingleChildScrollView(child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24), child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: MediaQuery.of(context).disableAnimations ? 0 : 650),
                builder: (context, value, child) => Opacity(opacity: value, child: child),
                child: BrandLogo(size: size),
              ),
              const SizedBox(height: 20),
              const Text('وصفات أصيلة… بطعم البيت', textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFF6E9D3), fontSize: 18, height: 1.5)),
              const SizedBox(height: 28),
              const SizedBox(width: 100, child: LinearProgressIndicator(
                minHeight: 2, backgroundColor: Colors.white12, color: AppColors.gold,
              )),
            ],
          )),
        ));
      })),
    ),
  );
}

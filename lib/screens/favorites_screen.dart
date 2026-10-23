import 'package:flutter/material.dart';
import '../theme.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المفضلة')),
      body: const Center(child: Text('لا توجد وصفات محفوظة بعد', style: TextStyle(color: AppColors.muted))),
    );
  }
}

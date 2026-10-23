import 'package:flutter/material.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [('أطباق تقليدية', '🍲'), ('حلويات', '🍰'), ('مقبلات', '🥗'), ('شوربات', '🍜'), ('مشروبات', '🥤'), ('أطباق خفيفة', '🥙')];
    return Scaffold(
      appBar: AppBar(title: const Text('التصنيفات')),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        children: categories.map((category) => Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(category.$2, style: const TextStyle(fontSize: 42)), const SizedBox(height: 8), Text(category.$1, style: const TextStyle(fontWeight: FontWeight.bold))])))).toList(),
      ),
    );
  }
}

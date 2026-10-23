import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../theme.dart';

class PreparationStepsScreen extends StatelessWidget {
  final Recipe recipe;
  const PreparationStepsScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('طريقة تحضير ${recipe.name}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: recipe.steps.asMap().entries.map((entry) => Card(margin: const EdgeInsets.only(bottom: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: ListTile(leading: CircleAvatar(backgroundColor: AppColors.gold, child: Text('${entry.key + 1}', style: const TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.bold))), title: Text(entry.value))).toList(),
      ),
    );
  }
}

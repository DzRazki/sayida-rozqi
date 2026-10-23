import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../theme.dart';

class IngredientsScreen extends StatelessWidget {
  final Recipe recipe;
  const IngredientsScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('مكونات ${recipe.name}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: recipe.ingredients.map((item) => Card(margin: const EdgeInsets.only(bottom: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: ListTile(leading: const Icon(Icons.check_circle_outline, color: AppColors.darkBrown), title: Text(item)))).toList(),
      ),
    );
  }
}

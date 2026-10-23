import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../theme.dart';

class RecipeDetailsScreen extends StatelessWidget {
  final Recipe recipe;
  const RecipeDetailsScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: recipe.imageUrl.isEmpty
                  ? Container(color: AppColors.brown, child: const Center(child: Text('🍽️', style: TextStyle(fontSize: 60))))
                  : Image.network(recipe.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.brown)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(recipe.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text('${recipe.category} · ${recipe.time} دقيقة · ${recipe.servings} أشخاص', style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 12),
                Text(recipe.description),
                const SizedBox(height: 18),
                Row(children: [
                  Expanded(child: FilledButton(onPressed: () {}, child: const Text('المكونات'))),
                  const SizedBox(width: 8),
                  Expanded(child: FilledButton(onPressed: () {}, child: const Text('طريقة التحضير'))),
                ]),
                const SizedBox(height: 20),
                const Text('المكونات', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                ...recipe.ingredients.map((item) => ListTile(dense: true, leading: const Icon(Icons.check_circle_outline), title: Text(item))),
                const SizedBox(height: 10),
                const Text('طريقة التحضير', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                ...recipe.steps.asMap().entries.map((entry) => ListTile(dense: true, leading: CircleAvatar(child: Text('${entry.key + 1}')), title: Text(entry.value))),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/favorites_service.dart';
import '../theme.dart';
import 'ingredients_screen.dart';
import 'preparation_steps_screen.dart';
import 'youtube_screen.dart';

class RecipeDetailsScreen extends StatefulWidget {
  final Recipe recipe;
  const RecipeDetailsScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailsScreen> createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> {
  bool favorite = false;

  @override
  void initState() {
    super.initState();
    loadFavorite();
  }

  Future<void> loadFavorite() async {
    favorite = await FavoritesService.isFavorite(widget.recipe.id);
    if (mounted) setState(() {});
  }

  Future<void> toggleFavorite() async {
    await FavoritesService.toggle(widget.recipe.id);
    favorite = await FavoritesService.isFavorite(widget.recipe.id);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            actions: [IconButton(onPressed: toggleFavorite, icon: Icon(favorite ? Icons.favorite : Icons.favorite_border, color: AppColors.gold))],
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
                  Expanded(child: FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IngredientsScreen(recipe: recipe))), child: const Text('المكونات'))),
                  const SizedBox(width: 8),
                  Expanded(child: FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PreparationStepsScreen(recipe: recipe))), child: const Text('التحضير'))),
                ]),
                if (recipe.youtubeUrl.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => YoutubeScreen(recipe: recipe))), icon: const Icon(Icons.play_circle_outline), label: const Text('مشاهدة الفيديو'))),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

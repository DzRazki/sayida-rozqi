import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/favorites_service.dart';
import '../theme.dart';
import '../screens/recipe_details_screen.dart';

class RecipeCard extends StatefulWidget {
  final Recipe recipe;
  const RecipeCard({super.key, required this.recipe});

  @override
  State<RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<RecipeCard> {
  bool favorite = false;

  @override
  void initState() {
    super.initState();
    _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    final value = await FavoritesService.isFavorite(widget.recipe.id);
    if (mounted) setState(() => favorite = value);
  }

  Future<void> _toggleFavorite() async {
    await FavoritesService.toggle(widget.recipe.id);
    final value = await FavoritesService.isFavorite(widget.recipe.id);
    if (mounted) setState(() => favorite = value);
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailsScreen(recipe: recipe))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: recipe.imageUrl.isEmpty
                        ? Container(color: AppColors.brown, child: const Center(child: Text('🍽️', style: TextStyle(fontSize: 42))))
                        : Image.network(recipe.imageUrl, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.brown, child: const Center(child: Text('🍽️', style: TextStyle(fontSize: 42))))),
                  ),
                ),
                Positioned(top: 8, left: 8, child: GestureDetector(onTap: _toggleFavorite, child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(favorite ? Icons.favorite : Icons.favorite_border, color: favorite ? Colors.red : AppColors.muted, size: 20)))),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(recipe.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Row(children: [const Icon(Icons.schedule, size: 14, color: AppColors.muted), const SizedBox(width: 4), Text('${recipe.time} د', style: const TextStyle(fontSize: 11, color: AppColors.muted)), const SizedBox(width: 10), const Icon(Icons.group, size: 14, color: AppColors.muted), const SizedBox(width: 4), Text('${recipe.servings}', style: const TextStyle(fontSize: 11, color: AppColors.muted))]),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

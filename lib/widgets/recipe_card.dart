import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/favorites_service.dart';
import '../theme.dart';
import '../screens/recipe_details_screen.dart';

class RecipeCard extends StatefulWidget {
  final Recipe recipe;
  final bool large;
  const RecipeCard({super.key, required this.recipe, this.large = false});
  @override
  State<RecipeCard> createState() => _RecipeCardState();
}
class _RecipeCardState extends State<RecipeCard> {
  bool favorite = false, saving = false;
  int generation = 0;
  @override
  void initState() { super.initState(); FavoritesService.changes.addListener(changed); _load(); }
  @override
  void dispose() { FavoritesService.changes.removeListener(changed); super.dispose(); }
  void changed() { if (mounted) setState(() => favorite = false); _load(); }
  Future<void> _load() async {
    final token = ++generation;
    try {
      final value = await FavoritesService.isFavorite(widget.recipe.id);
      if (mounted && token == generation) setState(() => favorite = value);
    } catch (_) { if (mounted && token == generation) setState(() => favorite = false); }
  }
  Future<void> _toggle() async {
    if (saving) return;
    setState(() => saving = true);
    try { await FavoritesService.toggle(widget.recipe.id); await _load(); } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر حفظ المفضلة. تحققي من الاتصال وحاولي مجددًا.')));
    } finally { if (mounted) setState(() => saving = false); }
  }
  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    return GestureDetector(
      onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailsScreen(recipe: recipe))); if (mounted) await _load(); },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .08), blurRadius: 18, offset: const Offset(0, 6))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            AspectRatio(aspectRatio: widget.large ? 16 / 9 : 4 / 3, child: recipe.imageUrl.isEmpty ? Container(color: AppColors.brown, child: const Center(child: Text('🍽️', style: TextStyle(fontSize: 46)))) : Image.network(recipe.imageUrl, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.brown, child: const Center(child: Text('🍽️', style: TextStyle(fontSize: 46)))))),
            Positioned(top: 10, left: 10, child: GestureDetector(onTap: saving ? null : _toggle, child: Container(padding: const EdgeInsets.all(7), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(favorite ? Icons.favorite : Icons.favorite_border, color: favorite ? Colors.red : AppColors.muted, size: 20)))),
            if (recipe.featured) Positioned(top: 10, right: 10, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(20)), child: const Text('مميزة', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.darkBrown)))),
          ]),
          Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(recipe.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: widget.large ? 17 : 14, fontWeight: FontWeight.bold)), const SizedBox(height: 6), Row(children: [const Icon(Icons.schedule, size: 14, color: AppColors.muted), const SizedBox(width: 4), Text('${recipe.time} د', style: const TextStyle(fontSize: 11, color: AppColors.muted)), const SizedBox(width: 12), const Icon(Icons.group, size: 14, color: AppColors.muted), const SizedBox(width: 4), Text('${recipe.servings} أشخاص', style: const TextStyle(fontSize: 11, color: AppColors.muted))])])),
        ]),
      ),
    );
  }
}

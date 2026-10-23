import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/favorites_service.dart';
import '../services/supabase_service.dart';
import '../theme.dart';
import '../widgets/recipe_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Recipe> recipes = [];
  Set<String> favorites = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    favorites = await FavoritesService.load();
    recipes = await SupabaseService.fetchRecipes();
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final items = recipes.where((recipe) => favorites.contains(recipe.id)).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('وصفاتي المفضلة')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const Center(child: Text('لا توجد وصفات محفوظة بعد', style: TextStyle(color: AppColors.muted)))
              : GridView.count(padding: const EdgeInsets.all(14), crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .72, children: items.map((recipe) => RecipeCard(recipe: recipe)).toList()),
    );
  }
}

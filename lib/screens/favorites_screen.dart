import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/favorites_service.dart';
import '../services/supabase_service.dart';
import '../theme.dart';
import 'recipe_details_screen.dart';

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
      appBar: AppBar(title: const Text('المفضلة')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const Center(child: Text('لا توجد وصفات محفوظة بعد', style: TextStyle(color: AppColors.muted)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final recipe = items[index];
                    return Card(margin: const EdgeInsets.only(bottom: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), child: ListTile(leading: recipe.imageUrl.isEmpty ? const Text('🍽️', style: TextStyle(fontSize: 26)) : ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(recipe.imageUrl, width: 52, height: 52, fit: BoxFit.cover)), title: Text(recipe.name), subtitle: Text('${recipe.time} دقيقة'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailsScreen(recipe: recipe)))));
                  },
                ),
    );
  }
}

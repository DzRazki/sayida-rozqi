import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/supabase_service.dart';
import '../theme.dart';
import '../widgets/recipe_card.dart';

class CategoriesScreen extends StatefulWidget {
  final String? category;
  const CategoriesScreen({super.key, this.category});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Recipe> recipes = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      recipes = await SupabaseService.fetchRecipes();
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.category;
    final items = selected == null ? recipes : recipes.where((r) => r.category == selected).toList();
    return Scaffold(
      appBar: AppBar(title: Text(selected ?? 'الفئات')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : selected == null
              ? GridView.count(padding: const EdgeInsets.all(16), crossAxisCount: 2, children: recipes.map((r) => r.category).toSet().map((category) => GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoriesScreen(category: category))), child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.line)), child: Center(child: Text(category, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)))))).toList())
              : items.isEmpty
                  ? const Center(child: Text('لا توجد وصفات في هذا التصنيف'))
                  : GridView.count(padding: const EdgeInsets.all(14), crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .72, children: items.map((recipe) => RecipeCard(recipe: recipe)).toList()),
    );
  }
}

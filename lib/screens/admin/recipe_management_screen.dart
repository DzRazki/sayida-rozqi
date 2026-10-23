import 'package:flutter/material.dart';
import '../../models/recipe.dart';
import '../../services/supabase_service.dart';
import '../../theme.dart';
import 'recipe_editor_screen.dart';

class RecipeManagementScreen extends StatefulWidget {
  const RecipeManagementScreen({super.key});

  @override
  State<RecipeManagementScreen> createState() => _RecipeManagementScreenState();
}

class _RecipeManagementScreenState extends State<RecipeManagementScreen> {
  List<Recipe> recipes = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    recipes = await SupabaseService.fetchRecipes(admin: true);
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الوصفات'), actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))]),
      floatingActionButton: FloatingActionButton(backgroundColor: AppColors.gold, onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const RecipeEditorScreen())); load(); }, child: const Icon(Icons.add, color: AppColors.darkBrown)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return Card(margin: const EdgeInsets.only(bottom: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: ListTile(title: Text(recipe.name), subtitle: Text('${recipe.category} · ${recipe.published ? 'منشورة' : 'مسودة'}'), trailing: PopupMenuButton<String>(onSelected: (value) async { if (value == 'edit') { await Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeEditorScreen(recipe: recipe))); load(); } if (value == 'delete') { await SupabaseService.deleteRecipe(recipe.id); load(); } }, itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('تعديل')), PopupMenuItem(value: 'delete', child: Text('حذف'))])));
              },
            ),
    );
  }
}

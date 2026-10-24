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
    setState(() => loading = true);
    recipes = await SupabaseService.fetchRecipes(admin: true);
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('إدارة الوصفات'),
        actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.darkBrown,
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const RecipeEditorScreen()));
          load();
        },
        icon: const Icon(Icons.add),
        label: const Text('وصفة جديدة'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : recipes.isEmpty
              ? const Center(child: Text('لا توجد وصفات بعد'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = recipes[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .06), blurRadius: 18, offset: const Offset(0, 6))],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        leading: recipe.imageUrl.isEmpty
                            ? Container(width: 56, height: 56, decoration: BoxDecoration(color: AppColors.brown.withValues(alpha: .15), borderRadius: BorderRadius.circular(14)), child: const Center(child: Text('🍽️')))
                            : ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(recipe.imageUrl, width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.brown.withValues(alpha: .15), child: const Center(child: Text('🍽️'))))),
                        title: Text(recipe.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkBrown)),
                        subtitle: Text('${recipe.category} · ${recipe.published ? 'منشورة' : 'مسودة'}', style: const TextStyle(color: AppColors.brown)),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'edit') {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeEditorScreen(recipe: recipe)));
                              load();
                            }
                            if (value == 'delete') {
                              await SupabaseService.deleteRecipe(recipe.id);
                              load();
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('تعديل')),
                            PopupMenuItem(value: 'delete', child: Text('حذف')),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

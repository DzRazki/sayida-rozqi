import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/supabase_service.dart';
import '../theme.dart';
import '../widgets/recipe_card.dart';

const categoryPhotos = <String, int>{
  'الأطباق التقليدية': 21531388,
  'الحلويات التقليدية': 18543475,
  'المقبلات والبوراك': 6646081,
  'الشوربات': 1703272,
  'المملحات والمعجنات': 14010373,
  'الخبز والفطائر التقليدية': 32965428,
  'أطباق الدجاج واللحوم': 20371512,
  'الكيك والطورطات': 10865890,
  'المشروبات والعصائر': 158053,
};

String categoryKey(String value) => value.trim().replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll(RegExp(r'\s+'), ' ');

class CategoryPhotoTile extends StatelessWidget {
  final String category;
  final VoidCallback onTap;
  const CategoryPhotoTile({super.key, required this.category, required this.onTap});
  @override
  Widget build(BuildContext context) {
    int? photo;
    for (final entry in categoryPhotos.entries) {
      if (categoryKey(entry.key) == categoryKey(category)) photo = entry.value;
    }
    final fallback = Container(color: AppColors.cream, alignment: Alignment.center, child: const Icon(Icons.restaurant_menu, color: AppColors.brown));
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AspectRatio(
            aspectRatio: 1.4,
            child: photo == null ? fallback : Image.network(
              'https://images.pexels.com/photos/$photo/pexels-photo-$photo.jpeg?auto=compress&cs=tinysrgb&w=480',
              fit: BoxFit.cover,
              width: double.infinity,
              excludeFromSemantics: true,
              loadingBuilder: (context, child, progress) => progress == null ? child : fallback,
              errorBuilder: (_, __, ___) => fallback,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text(category, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, height: 1.25, fontWeight: FontWeight.w600, color: AppColors.darkBrown)),
          ),
        ]),
      ),
    );
  }
}

class CategoriesScreen extends StatefulWidget {
  final String? category;
  const CategoriesScreen({super.key, this.category});
  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Recipe> recipes = [];
  bool loading = true;
  String? error;
  @override
  void initState() { super.initState(); load(); }
  Future<void> load() async {
    setState(() { loading = true; error = null; });
    try {
      final data = await SupabaseService.fetchRecipes();
      if (mounted) setState(() => recipes = data);
    } catch (_) {
      if (mounted) setState(() => error = 'تعذر تحميل الوصفات. حاولي مجددًا.');
    } finally { if (mounted) setState(() => loading = false); }
  }
  @override
  Widget build(BuildContext context) {
    final selected = widget.category;
    final items = selected == null ? recipes : recipes.where((r) => categoryKey(r.category) == categoryKey(selected)).toList();
    final names = <String>[...categoryPhotos.keys];
    for (final recipe in recipes) {
      if (recipe.category.trim().isNotEmpty && !names.any((name) => categoryKey(name) == categoryKey(recipe.category))) names.add(recipe.category);
    }
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(selected ?? 'التصنيفات')),
      body: selected == null
          ? LayoutBuilder(builder: (context, constraints) {
              final columns = constraints.maxWidth >= 600 ? 4 : 3;
              final width = (constraints.maxWidth - 16 - 6 * (columns - 1)) / columns;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(8),
                child: Wrap(spacing: 6, runSpacing: 6, children: names.map((name) => SizedBox(
                  width: width,
                  child: CategoryPhotoTile(category: name, onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => CategoriesScreen(category: name)))),
                )).toList()),
              );
            })
          : loading ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : error != null ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(error!), TextButton(onPressed: load, child: const Text('إعادة المحاولة'))]))
          : items.isEmpty ? const Center(child: Text('لا توجد وصفات في هذا التصنيف'))
          : LayoutBuilder(builder: (context, constraints) {
              final columns = constraints.maxWidth >= 600 ? 3 : 2;
              final width = (constraints.maxWidth - 12 - 6 * (columns - 1)) / columns;
              return SingleChildScrollView(padding: const EdgeInsets.all(6), child: Wrap(
                spacing: 6, runSpacing: 6,
                children: items.map((recipe) => SizedBox(width: width, child: RecipeCard(key: ValueKey(recipe.id), recipe: recipe))).toList(),
              ));
            }),
    );
  }
}

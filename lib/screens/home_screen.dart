import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/supabase_service.dart';
import '../theme.dart';
import 'categories_screen.dart';
import 'favorites_screen.dart';
import 'recipe_details_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Recipe> recipes = [];
  bool loading = true;
  String query = '';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      recipes = await SupabaseService.fetchRecipes();
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final published = recipes;
    final Recipe? featured = published.isNotEmpty ? (published.firstWhere((r) => r.featured, orElse: () => published.first)) : null;
    final filtered = published.where((r) => r.name.contains(query)).take(3).toList();
    final categories = published.map((r) => r.category).toSet().toList();

    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.menu),
        title: const Text('السيدة رزقي', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
        actions: const [Padding(padding: EdgeInsets.all(14), child: Icon(Icons.notifications_none))],
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            TextField(
              onChanged: (value) => setState(() => query = value.trim()),
              decoration: const InputDecoration(hintText: 'ابحثي عن وصفة...', prefixIcon: Icon(Icons.search)),
            ),
            const SizedBox(height: 14),
            if (featured != null) _FeaturedCard(recipe: featured),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('التصنيفات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkBrown)),
                TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen())), child: const Text('عرض الكل')),
              ],
            ),
            SizedBox(
              height: 96,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: categories.map((category) => _CategoryCard(name: category, emoji: '🍽️')).toList(),
              ),
            ),
            const SizedBox(height: 12),
            const Text('أحدث الوصفات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkBrown)),
            const SizedBox(height: 10),
            if (loading) const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator())),
            ...filtered.map((recipe) => _RecipeCard(recipe: recipe)),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen()));
          if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()));
          if (index == 3) Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.category_outlined), label: 'التصنيفات'),
          NavigationDestination(icon: Icon(Icons.favorite_border), label: 'المفضلة'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'الإعدادات'),
        ],
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final Recipe recipe;
  const _FeaturedCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          SizedBox(
            height: 205,
            width: double.infinity,
            child: recipe.imageUrl.isEmpty
                ? Container(color: AppColors.brown, child: const Center(child: Text('🍽️', style: TextStyle(fontSize: 50))))
                : Image.network(recipe.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.brown)),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, AppColors.darkBrown.withOpacity(.9)])),
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(recipe.name, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailsScreen(recipe: recipe))), child: const Text('عرض الوصفة')),
            ]),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String name;
  final String emoji;
  const _CategoryCard({required this.name, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(emoji, style: const TextStyle(fontSize: 28)), const SizedBox(height: 5), Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)]),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  const _RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 96,
              height: 82,
              child: recipe.imageUrl.isEmpty
                  ? Container(color: AppColors.brown, child: const Center(child: Text('🍽️', style: TextStyle(fontSize: 28))))
                  : Image.network(recipe.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.brown)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(recipe.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text('${recipe.time} دقيقة · ${recipe.servings} أشخاص', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ]),
          ),
          IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailsScreen(recipe: recipe))), icon: const Icon(Icons.arrow_back_ios_new, size: 18)),
        ],
      ),
    );
  }
}

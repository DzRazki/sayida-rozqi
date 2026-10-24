import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/supabase_service.dart';
import '../theme.dart';
import '../widgets/recipe_card.dart';
import 'admin/admin_login_screen.dart';
import 'admin/recipe_management_screen.dart';
import 'categories_screen.dart';
import 'favorites_screen.dart';
import 'notifications_screen.dart';
import 'recipe_details_screen.dart';
import 'youtube_channel_screen.dart';

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

  List<Recipe> get filtered => recipes.where((r) => r.name.contains(query)).toList();

  List<Map<String, String>> get categories => const [
        {'name': 'أطباق تقليدية', 'emoji': '🍲'},
        {'name': 'حلويات', 'emoji': '🍰'},
        {'name': 'مقبلات', 'emoji': '🥗'},
        {'name': 'شوربات', 'emoji': '🍜'},
        {'name': 'مشروبات', 'emoji': '🥤'},
        {'name': 'أطباق خفيفة', 'emoji': '🥙'},
        {'name': 'أخرى', 'emoji': '🍽️'},
      ];

  @override
  Widget build(BuildContext context) {
    final daily = recipes.isNotEmpty ? recipes.first : null;
    final latest = recipes.take(6).toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4EF),
      appBar: AppBar(
        backgroundColor: AppColors.darkBrown,
        title: const Text('السيدة رزقي', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.notifications_none, color: Colors.white), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())))],
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          TextField(onChanged: (value) => setState(() => query = value.trim()), decoration: InputDecoration(hintText: 'ابحث عن وصفة ...', prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none))),
          const SizedBox(height: 20),
          if (daily != null)
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailsScreen(recipe: daily))),
              child: Container(
                height: 220,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .12), blurRadius: 20, offset: const Offset(0, 8))]),
                child: Stack(fit: StackFit.expand, children: [
                  daily.imageUrl.isEmpty ? Container(color: AppColors.brown) : Image.network(daily.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.brown)),
                  Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: .75)]))),
                  Padding(padding: const EdgeInsets.all(18), child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('وصفة اليوم', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)), const SizedBox(height: 6), Text(daily.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 4), const Text('نكهة الأصالة في كل لقمة', style: TextStyle(color: Colors.white70)), const SizedBox(height: 12), FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailsScreen(recipe: daily))), child: const Text('عرض الوصفة'))])),
                ]),
              ),
            ),
          const SizedBox(height: 24),
          const Text('التصنيفات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(height: 104, child: ListView(scrollDirection: Axis.horizontal, children: categories.map((category) => GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoriesScreen(category: category['name']))), child: Container(width: 88, margin: const EdgeInsets.only(left: 10), child: Column(children: [Container(width: 64, height: 64, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]), child: Center(child: Text(category['emoji']!, style: const TextStyle(fontSize: 28)))), const SizedBox(height: 6), Text(category['name']!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))])))).toList())),
          const SizedBox(height: 24),
          const Text('أحدث الوصفات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (loading) const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator())),
          if (!loading && filtered.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('لا توجد وصفات بعد'))),
          if (!loading) GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: .68, children: latest.map((recipe) => RecipeCard(recipe: recipe)).toList()),
        ]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => const YouTubeChannelScreen()));
          if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()));
          if (index == 3) Navigator.push(context, MaterialPageRoute(builder: (_) => SupabaseService.isAdmin() ? const RecipeManagementScreen() : const AdminLoginScreen()));
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.play_circle_outline), selectedIcon: Icon(Icons.play_circle), label: 'القناة'),
          NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'المفضلة'),
          NavigationDestination(icon: Icon(Icons.admin_panel_settings_outlined), selectedIcon: Icon(Icons.admin_panel_settings), label: 'الإدارة'),
        ],
      ),
    );
  }
}

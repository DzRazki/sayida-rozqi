import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/supabase_service.dart';
import '../theme.dart';
import '../widgets/recipe_card.dart';
import 'categories_screen.dart';
import 'favorites_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'admin/admin_login_screen.dart';
import 'admin/recipe_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Recipe> recipes = [];
  bool loading = true;
  String query = '';
  String selectedCategory = 'الكل';

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

  List<Recipe> get filtered {
    var items = recipes.where((r) => r.name.contains(query)).toList();
    if (selectedCategory != 'الكل') items = items.where((r) => r.category == selectedCategory).toList();
    items.sort((a, b) => (b.featured ? 1 : 0).compareTo(a.featured ? 1 : 0));
    return items;
  }

  List<String> get categories => ['الكل', ...recipes.map((r) => r.category).toSet()];

  @override
  Widget build(BuildContext context) {
    final featured = recipes.where((r) => r.featured).take(3).toList();
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: AppColors.darkBrown),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('🍲', style: TextStyle(fontSize: 34)),
                  SizedBox(height: 8),
                  Text('السيدة رزقي', style: TextStyle(color: AppColors.gold, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('أشهى الوصفات الجزائرية', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            ListTile(leading: const Icon(Icons.home_outlined), title: const Text('الرئيسية'), onTap: () => Navigator.pop(context)),
            ListTile(leading: const Icon(Icons.category_outlined), title: const Text('الفئات'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen())); }),
            ListTile(leading: const Icon(Icons.favorite_border), title: const Text('المفضلة'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen())); }),
            ListTile(leading: const Icon(Icons.notifications_none), title: const Text('الإشعارات'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())); }),
            ListTile(leading: const Icon(Icons.settings_outlined), title: const Text('الإعدادات'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())); }),
            if (SupabaseService.isAdmin()) ListTile(leading: const Icon(Icons.admin_panel_settings), title: const Text('لوحة الإدارة'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const RecipeManagementScreen())); }) else ListTile(leading: const Icon(Icons.admin_panel_settings_outlined), title: const Text('دخول الإدارة'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminLoginScreen())); }),
          ],
        ),
      ),
      appBar: AppBar(
        leading: Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer())),
        title: const Text('السيدة رزقي', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.notifications_none), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())))],
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            TextField(onChanged: (value) => setState(() => query = value.trim()), decoration: const InputDecoration(hintText: 'ابحثي عن وصفة...', prefixIcon: Icon(Icons.search))),
            const SizedBox(height: 14),
            SizedBox(height: 42, child: ListView(scrollDirection: Axis.horizontal, children: categories.map((category) => Padding(padding: const EdgeInsets.only(left: 8), child: ChoiceChip(label: Text(category), selected: selectedCategory == category, onSelected: (_) => setState(() => selectedCategory = category)))).toList())),
            const SizedBox(height: 16),
            if (selectedCategory == 'الكل' && featured.isNotEmpty) ...[
              const Text('وصفات مميزة', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SizedBox(height: 230, child: ListView(scrollDirection: Axis.horizontal, children: featured.map((recipe) => SizedBox(width: 250, child: RecipeCard(recipe: recipe))).toList())),
              const SizedBox(height: 20),
            ],
            Text(selectedCategory == 'الكل' ? 'أحدث الوصفات' : selectedCategory, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (loading) const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator())),
            if (!loading && filtered.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('لا توجد وصفات في هذا التصنيف'))),
            if (!loading) GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .72, children: filtered.map((recipe) => RecipeCard(recipe: recipe)).toList()),
          ],
        ),
      ),
    );
  }
}

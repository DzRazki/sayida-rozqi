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
  String selectedCategory = 'الكل';
  int adminTaps = 0;

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

  void _secretAdminTap() {
    adminTaps++;
    if (adminTaps >= 20) {
      adminTaps = 0;
      Navigator.push(context, MaterialPageRoute(builder: (_) => SupabaseService.isAdmin() ? const RecipeManagementScreen() : const AdminLoginScreen()));
    }
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
    final featured = recipes.where((r) => r.featured).take(5).toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EE),
      appBar: AppBar(
        backgroundColor: AppColors.darkBrown,
        title: GestureDetector(onTap: _secretAdminTap, child: const Text('السيدة رزقي', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold))),
        actions: [IconButton(icon: const Icon(Icons.notifications_none, color: Colors.white), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())))],
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          TextField(onChanged: (value) => setState(() => query = value.trim()), decoration: InputDecoration(hintText: 'ابحثي عن وصفة...', prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
          const SizedBox(height: 16),
          SizedBox(height: 44, child: ListView(scrollDirection: Axis.horizontal, children: categories.map((category) => Padding(padding: const EdgeInsets.only(left: 8), child: ChoiceChip(label: Text(category), selected: selectedCategory == category, onSelected: (_) => setState(() => selectedCategory = category)))).toList())),
          const SizedBox(height: 20),
          if (selectedCategory == 'الكل' && featured.isNotEmpty) ...[
            const Text('وصفات مميزة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(height: 290, child: ListView(scrollDirection: Axis.horizontal, children: featured.map((recipe) => SizedBox(width: 290, child: RecipeCard(recipe: recipe, large: true))).toList())),
            const SizedBox(height: 24),
          ],
          Text(selectedCategory == 'الكل' ? 'أحدث الوصفات' : selectedCategory, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (loading) const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator())),
          if (!loading && filtered.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('لا توجد وصفات في هذا التصنيف'))),
          if (!loading) GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: .68, children: filtered.map((recipe) => RecipeCard(recipe: recipe)).toList()),
        ]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()));
          if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (_) => const YouTubeChannelScreen()));
          if (index == 3) Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'المفضلة'),
          NavigationDestination(icon: Icon(Icons.play_circle_outline), selectedIcon: Icon(Icons.play_circle), label: 'يوتيوب'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'الإعدادات'),
        ],
      ),
    );
  }
}

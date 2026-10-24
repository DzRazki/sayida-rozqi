import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/supabase_service.dart';
import '../theme.dart';
import '../widgets/recipe_card.dart';
import 'admin/admin_login_screen.dart';
import 'categories_screen.dart';
import 'favorites_screen.dart';
import 'notifications_screen.dart';
import 'recipe_details_screen.dart';
import 'youtube_channel_screen.dart';
import 'account_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Recipe> recipes = [];
  bool loading = true;
  String query = '';
  String? error;
  int adminTaps = 0;
  final search = TextEditingController();
  final PageController sliderController = PageController(viewportFraction: .88);

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    search.dispose();
    sliderController.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() { loading = true; error = null; });
    try {
      final data = await SupabaseService.fetchRecipes();
      if (!mounted) return;
      setState(() => recipes = data);
    } catch (_) {
      if (mounted) setState(() => error = 'تعذر تحميل الوصفات. اسحبي لإعادة المحاولة.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void open(Widget page) => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));

  void secret() {
    adminTaps++;
    if (adminTaps == 20) { adminTaps = 0; open(const AdminLoginScreen()); }
  }

  Widget heading(String title, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 12),
    child: Row(children: [
      Container(width: 5, height: 22, decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 10),
      Expanded(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkBrown))),
      TextButton(onPressed: onTap, child: const Text('عرض الكل', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600))),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final items = recipes.where((r) => r.name.contains(query) || r.ingredients.any((i) => i.contains(query))).toList();
    final latest = recipes.take(4).toList();
    final categories = recipes.map((r) => r.category).toSet().take(4).toList();

    return Scaffold(
      backgroundColor: AppColors.cream,
      drawer: Drawer(
        child: SafeArea(
          child: ListView(children: [
            const Padding(padding: EdgeInsets.all(22), child: Text('السيدة رزقي', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkBrown))),
            ListTile(leading: const Icon(Icons.home_outlined), title: const Text('الرئيسية'), onTap: () => Navigator.pop(context)),
            ListTile(leading: const Icon(Icons.category_outlined), title: const Text('التصنيفات'), onTap: () { Navigator.pop(context); open(const CategoriesScreen()); }),
            ListTile(leading: const Icon(Icons.favorite_border), title: const Text('المفضلة'), onTap: () { Navigator.pop(context); open(const FavoritesScreen()); }),
            ListTile(leading: const Icon(Icons.play_circle_outline), title: const Text('القناة'), onTap: () { Navigator.pop(context); open(const YouTubeChannelScreen()); }),
            ListTile(leading: const Icon(Icons.notifications_none), title: const Text('الإشعارات'), onTap: () { Navigator.pop(context); open(const NotificationsScreen()); }),
          ]),
        ),
      ),
      appBar: AppBar(
        backgroundColor: AppColors.darkBrown,
        foregroundColor: Colors.white,
        title: GestureDetector(onTap: secret, child: const Text('السيدة رزقي', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold))),
        actions: [IconButton(onPressed: () => open(const NotificationsScreen()), icon: const Icon(Icons.notifications_none))],
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(0, 18, 0, 24),
          children: [
            if (latest.isNotEmpty)
              SizedBox(
                height: 210,
                child: PageView.builder(
                  controller: sliderController,
                  itemCount: latest.length,
                  itemBuilder: (context, index) {
                    final recipe = latest[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: InkWell(
                        onTap: () => open(RecipeDetailsScreen(recipe: recipe)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: recipe.imageUrl.isEmpty
                              ? const ColoredBox(color: AppColors.brown, child: Center(child: Icon(Icons.restaurant, color: Colors.white)))
                              : Image.network(recipe.imageUrl, fit: BoxFit.cover, filterQuality: FilterQuality.high, gaplessPlayback: true, errorBuilder: (_, __, ___) => const ColoredBox(color: AppColors.brown, child: Center(child: Icon(Icons.restaurant, color: Colors.white)))),
                        ),
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: TextField(
                controller: search,
                onChanged: (v) => setState(() => query = v.trim()),
                decoration: InputDecoration(
                  hintText: 'ابحثي عن وصفة أو مكوّن...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.brown),
                  suffixIcon: query.isEmpty ? null : IconButton(onPressed: () { search.clear(); setState(() => query = ''); }, icon: const Icon(Icons.close)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                ),
              ),
            ),
            if (query.isEmpty && categories.isNotEmpty) ...[
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: heading('التصنيفات', () => open(const CategoriesScreen()))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: categories.map((c) => Expanded(child: InkWell(onTap: () => open(CategoriesScreen(category: c)), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6), child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 58, height: 58, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .06), blurRadius: 12, offset: const Offset(0, 4))]), child: const Center(child: Icon(Icons.restaurant_menu, color: AppColors.brown))),
                  const SizedBox(height: 8),
                  Text(c, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.darkBrown)),
                ]))))).toList()),
              ),
            ],
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: heading(query.isEmpty ? 'كل الوصفات' : 'نتائج البحث', () => open(const CategoriesScreen()))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: [
                if (loading) const Center(child: Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator())),
                if (error != null) Text(error!),
                if (!loading && error == null && items.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('لا توجد وصفات مطابقة')),
                if (!loading)
                  LayoutBuilder(builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 600 ? 3 : 2;
                    final width = (constraints.maxWidth - 14 * (columns - 1)) / columns;
                    return Wrap(spacing: 14, runSpacing: 14, children: items.map((r) => SizedBox(width: width, child: RecipeCard(key: ValueKey(r.id), recipe: r))).toList());
                  }),
              ]),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.gold.withValues(alpha: .22),
        selectedIndex: 0,
        onDestinationSelected: (i) {
          if (i == 1) open(const YouTubeChannelScreen());
          if (i == 2) open(const FavoritesScreen());
          if (i == 3) open(const AccountScreen());
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.play_circle_outline), label: 'القناة'),
          NavigationDestination(icon: Icon(Icons.favorite_border), label: 'المفضلة'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'حسابي'),
        ],
      ),
    );
  }
}

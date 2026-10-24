import 'dart:async';
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
  final PageController sliderController = PageController();
  Timer? sliderTimer;
  @override
  void initState() {
    super.initState(); load();
    sliderTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      final count = recipes.take(4).length;
      if (!mounted || count < 2 || !sliderController.hasClients) return;
      final next = ((sliderController.page?.round() ?? 0) + 1) % count;
      sliderController.animateToPage(next, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    });
  }
  @override
  void dispose() { search.dispose(); sliderTimer?.cancel(); sliderController.dispose(); super.dispose(); }
  Future<void> load() async {
    setState(() { loading = true; error = null; });
    try {
      final data = await SupabaseService.fetchRecipes();
      if (mounted) setState(() => recipes = data);
    } catch (_) {
      if (mounted) setState(() => error = 'تعذر تحميل الوصفات. اسحبي لإعادة المحاولة.');
    } finally { if (mounted) setState(() => loading = false); }
  }
  void open(Widget page) => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
  void secret() { adminTaps++; if (adminTaps == 20) { adminTaps = 0; open(const AdminLoginScreen()); } }
  Widget heading(String title) => Row(children: [
    Container(width: 4, height: 20, color: AppColors.gold),
    const SizedBox(width: 8),
    Expanded(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkBrown))),
    TextButton(onPressed: () => open(const CategoriesScreen()), child: const Text('عرض الكل', style: TextStyle(color: AppColors.gold))),
  ]);
  @override
  Widget build(BuildContext context) {
    final items = recipes.where((r) => r.name.contains(query) || r.ingredients.any((i) => i.contains(query))).toList();
    final latest = recipes.take(4).toList();
    return Scaffold(
      backgroundColor: AppColors.cream,
      drawer: Drawer(child: SafeArea(child: ListView(children: [
        const Padding(padding: EdgeInsets.all(22), child: Text('السيدة رزقي', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkBrown))),
        ListTile(leading: const Icon(Icons.home_outlined), title: const Text('الرئيسية'), onTap: () => Navigator.pop(context)),
        ListTile(leading: const Icon(Icons.category_outlined), title: const Text('التصنيفات'), onTap: () { Navigator.pop(context); open(const CategoriesScreen()); }),
        ListTile(leading: const Icon(Icons.favorite_border), title: const Text('المفضلة'), onTap: () { Navigator.pop(context); open(const FavoritesScreen()); }),
        ListTile(leading: const Icon(Icons.play_circle_outline), title: const Text('القناة'), onTap: () { Navigator.pop(context); open(const YouTubeChannelScreen()); }),
        ListTile(leading: const Icon(Icons.notifications_none), title: const Text('الإشعارات'), onTap: () { Navigator.pop(context); open(const NotificationsScreen()); }),
      ]))),
      appBar: AppBar(
        backgroundColor: AppColors.darkBrown, foregroundColor: Colors.white,
        title: GestureDetector(onTap: secret, child: const Text('السيدة رزقي', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold))),
        actions: [IconButton(onPressed: () => open(const NotificationsScreen()), icon: const Icon(Icons.notifications_none))],
      ),
      body: RefreshIndicator(onRefresh: load, child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 12),
        children: [
          if (latest.isNotEmpty) Stack(children: [
            AspectRatio(aspectRatio: 16 / 9, child: PageView.builder(
              controller: sliderController, itemCount: latest.length,
              itemBuilder: (context, index) {
                final recipe = latest[index];
                final fallback = Container(color: AppColors.brown, child: const Center(child: Icon(Icons.restaurant, color: Colors.white)));
                return InkWell(onTap: () => open(RecipeDetailsScreen(recipe: recipe)), child: recipe.imageUrl.isEmpty ? fallback : Image.network(
                  recipe.imageUrl, width: double.infinity, fit: BoxFit.cover, filterQuality: FilterQuality.high, gaplessPlayback: true, errorBuilder: (_, __, ___) => fallback,
                ));
              },
            )),
            Positioned(left: 12, bottom: 12, child: IconButton(
              onPressed: () {
                final current = sliderController.hasClients ? (sliderController.page?.round() ?? 0) : 0;
                sliderController.animateToPage(current == 0 ? latest.length - 1 : current - 1, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
              },
              style: IconButton.styleFrom(backgroundColor: Colors.black.withValues(alpha: .45), foregroundColor: Colors.white), icon: const Icon(Icons.chevron_left),
            )),
            Positioned(right: 12, bottom: 12, child: IconButton(
              onPressed: () {
                final current = sliderController.hasClients ? (sliderController.page?.round() ?? 0) : 0;
                sliderController.animateToPage(current == latest.length - 1 ? 0 : current + 1, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
              },
              style: IconButton.styleFrom(backgroundColor: Colors.black.withValues(alpha: .45), foregroundColor: Colors.white), icon: const Icon(Icons.chevron_right),
            )),
          ]),
          Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 0), child: TextField(
            controller: search, onChanged: (value) => setState(() => query = value.trim()),
            decoration: InputDecoration(
              hintText: 'ابحثي عن وصفة أو مكوّن...', prefixIcon: const Icon(Icons.search, color: AppColors.brown),
              suffixIcon: query.isEmpty ? null : IconButton(onPressed: () { search.clear(); setState(() => query = ''); }, icon: const Icon(Icons.close)),
              filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            ),
          )),
          if (query.isEmpty) Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Column(children: [
            heading('التصنيفات'),
            SingleChildScrollView(
              key: const PageStorageKey<String>('home-category-strip'),
              scrollDirection: Axis.horizontal,
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: categoryPhotos.keys.map((name) => Padding(
                padding: const EdgeInsetsDirectional.only(end: 6),
                child: SizedBox(width: 116, child: CategoryPhotoTile(category: name, onTap: () => open(CategoriesScreen(category: name)))),
              )).toList()),
            ),
          ])),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: heading(query.isEmpty ? 'كل الوصفات' : 'نتائج البحث')),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Column(children: [
            if (loading) const Center(child: Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator())),
            if (error != null) Text(error!),
            if (!loading && error == null && items.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('لا توجد وصفات مطابقة')),
            if (!loading) LayoutBuilder(builder: (context, constraints) {
              final columns = constraints.maxWidth >= 600 ? 3 : 2;
              final width = (constraints.maxWidth - 14 * (columns - 1)) / columns;
              return Wrap(spacing: 14, runSpacing: 14, children: items.map((recipe) => SizedBox(width: width, child: RecipeCard(key: ValueKey(recipe.id), recipe: recipe))).toList());
            }),
          ])),
        ],
      )),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white, indicatorColor: AppColors.gold.withValues(alpha: .22), selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) open(const YouTubeChannelScreen());
          if (index == 2) open(const FavoritesScreen());
          if (index == 3) open(const AccountScreen());
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

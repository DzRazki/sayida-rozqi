import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/favorites_service.dart';
import '../services/supabase_service.dart';
import '../widgets/recipe_card.dart';
import 'user_auth_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}
class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Recipe> items = [];
  bool loading = true, importing = false, offerImport = false;
  String? error;
  int generation = 0;
  @override
  void initState() { super.initState(); FavoritesService.changes.addListener(changed); load(); }
  @override
  void dispose() { FavoritesService.changes.removeListener(changed); super.dispose(); }
  void changed() { load(); }
  Future<void> load() async {
    final token = ++generation;
    setState(() { loading = true; items = []; error = null; offerImport = false; });
    try {
      final ids = await FavoritesService.load();
      final recipes = await SupabaseService.fetchRecipes();
      final offer = await FavoritesService.canImport();
      if (!mounted || token != generation) return;
      setState(() { items = recipes.where((r) => ids.contains(r.id)).toList(); offerImport = offer; });
    } catch (_) {
      if (mounted && token == generation) setState(() => error = 'تعذر تحميل المفضلة. تحققي من الاتصال وتفعيل account_favorites.sql.');
    } finally { if (mounted && token == generation) setState(() => loading = false); }
  }
  Future<void> importFavorites() async {
    if (importing) return;
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return;
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('استيراد المفضلة'),
      content: Text('إضافة مفضلة هذا الهاتف إلى حساب ${user.email ?? user.id}؟ ستبقى النسخة المحلية دون حذف.'),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')), TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('استيراد'))],
    ));
    if (!mounted || ok != true) return;
    setState(() => importing = true);
    try { await FavoritesService.importLocal(user.id); await load(); } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر الاستيراد. لم نحذف المفضلة المحلية.')));
    } finally { if (mounted) setState(() => importing = false); }
  }
  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.client.auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('وصفاتي المفضلة'), actions: [IconButton(onPressed: loading || importing ? null : load, icon: const Icon(Icons.refresh))]),
      body: Column(children: [
        if (user == null) ListTile(title: const Text('المفضلة محفوظة على هذا الهاتف فقط'), subtitle: const Text('سجّلي الدخول للمزامنة، ثم اختاري استيراد المفضلة المحلية إن رغبتِ.'), trailing: TextButton(onPressed: () async {
          await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const UserAuthScreen()));
          if (mounted) await load();
        }, child: const Text('دخول'))),
        if (user != null) Padding(padding: const EdgeInsets.all(8), child: Text('مفضلة حساب: ${user.email ?? ''}')),
        if (offerImport && !loading) ListTile(title: const Text('توجد مفضلة قديمة على هذا الهاتف'), trailing: TextButton(onPressed: importing ? null : importFavorites, child: const Text('استيراد'))),
        if (importing) const LinearProgressIndicator(),
        Expanded(child: loading ? const Center(child: CircularProgressIndicator()) : error != null
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(error!), TextButton(onPressed: load, child: const Text('إعادة المحاولة'))]))
          : items.isEmpty ? const Center(child: Text('لا توجد وصفات محفوظة بعد'))
          : RefreshIndicator(onRefresh: load, child: GridView.count(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(14), crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .72, children: items.map((r) => RecipeCard(key: ValueKey(r.id), recipe: r)).toList()))),
      ]),
    );
  }
}

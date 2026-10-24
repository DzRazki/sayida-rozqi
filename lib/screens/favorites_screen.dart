import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/favorites_service.dart';
import '../services/supabase_service.dart';
import '../theme.dart';
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
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('وصفاتي المفضلة'), actions: [IconButton(onPressed: loading || importing ? null : load, icon: const Icon(Icons.refresh))]),
      body: Column(children: [
        if (user == null) Container(
          margin: const EdgeInsets.all(14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .06), blurRadius: 18, offset: const Offset(0, 6))]),
          child: Row(children: [
            const Icon(Icons.favorite_border, color: AppColors.gold),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('المفضلة محفوظة على هذا الهاتف فقط', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkBrown)), const SizedBox(height: 4), const Text('سجّلي الدخول للمزامنة، ثم اختاري استيراد المفضلة المحلية إن رغبتِ.', style: TextStyle(color: AppColors.brown))])),
            TextButton(onPressed: () async {
              await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const UserAuthScreen()));
              if (mounted) await load();
            }, child: const Text('دخول', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold))),
          ]),
        ),
        if (user != null) Padding(padding: const EdgeInsets.all(12), child: Text('مفضلة حساب: ${user.email ?? ''}', style: const TextStyle(color: AppColors.brown))),
        if (offerImport && !loading) Container(
          margin: const EdgeInsets.symmetric(horizontal: 14),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: .15), borderRadius: BorderRadius.circular(16)),
          child: Row(children: [const Icon(Icons.download, color: AppColors.darkBrown), const SizedBox(width: 10), const Expanded(child: Text('توجد مفضلة قديمة على هذا الهاتف', style: TextStyle(color: AppColors.darkBrown))), TextButton(onPressed: importing ? null : importFavorites, child: const Text('استيراد', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)))]),
        ),
        if (importing) const LinearProgressIndicator(color: AppColors.gold),
        Expanded(child: loading ? const Center(child: CircularProgressIndicator(color: AppColors.gold)) : error != null
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(error!, textAlign: TextAlign.center), TextButton(onPressed: load, child: const Text('إعادة المحاولة', style: TextStyle(color: AppColors.gold)))]))
          : items.isEmpty ? const Center(child: Text('لا توجد وصفات محفوظة بعد'))
          : RefreshIndicator(onRefresh: load, child: GridView.count(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(14), crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .72, children: items.map((r) => RecipeCard(key: ValueKey(r.id), recipe: r)).toList()))),
      ]),
    );
  }
}

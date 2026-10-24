import 'package:flutter/material.dart';
import '../../models/recipe.dart';
import '../../services/supabase_service.dart';
import '../../theme.dart';
import 'recipe_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<Recipe> recipes = [];
  Map<String, int> recipeViews = {};
  int views = 0;
  int likes = 0;
  int dislikes = 0;
  bool loading = true;
  String? error;

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    setState(() { loading = true; error = null; });
    try {
      if (!SupabaseService.isAdmin()) throw StateError('Unauthorized');
      final fetched = await SupabaseService.fetchRecipes(admin: true);
      final rows = await SupabaseService.client.from('recipe_stats').select('recipe_id,views,likes,dislikes');
      final counts = <String, int>{};
      var totalViews = 0;
      var totalLikes = 0;
      var totalDislikes = 0;
      for (final row in rows) {
        final count = int.tryParse('${row['views']}') ?? 0;
        counts['${row['recipe_id']}'] = count;
        totalViews += count;
        totalLikes += int.tryParse('${row['likes']}') ?? 0;
        totalDislikes += int.tryParse('${row['dislikes']}') ?? 0;
      }
      fetched.sort((a, b) {
        final result = (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0);
        return result == 0 ? a.name.compareTo(b.name) : result;
      });
      if (!mounted) return;
      setState(() { recipes = fetched; recipeViews = counts; views = totalViews; likes = totalLikes; dislikes = totalDislikes; });
    } catch (_) {
      if (mounted) setState(() => error = 'تعذر تحميل الإحصائيات. تحققي من الاتصال وتهيئة جدول الإحصائيات وصلاحيات الإدارة.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget metric(String title, int value, IconData icon) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .06), blurRadius: 18, offset: const Offset(0, 6))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.gold),
        const SizedBox(height: 10),
        Text('$value', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkBrown)),
        Text(title, style: const TextStyle(color: AppColors.brown)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (!SupabaseService.isAdmin()) return Scaffold(appBar: AppBar(title: const Text('الإدارة')), body: const Center(child: Text('يلزم تسجيل دخول الإدارة')));
    final ranked = recipes.where((r) => (recipeViews[r.id] ?? 0) > 0).take(5).toList();
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('لوحة الإحصائيات'), actions: [IconButton(onPressed: loading ? null : load, tooltip: 'تحديث', icon: const Icon(Icons.refresh))]),
      body: loading ? const Center(child: CircularProgressIndicator(color: AppColors.gold)) : RefreshIndicator(onRefresh: load, child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(16), children: [
        if (error != null) ...[Text(error!), const SizedBox(height: 12), OutlinedButton(onPressed: load, child: const Text('إعادة المحاولة'))] else ...[
          Row(children: [Expanded(child: metric('إجمالي الوصفات', recipes.length, Icons.restaurant_menu)), const SizedBox(width: 12), Expanded(child: metric('إجمالي المشاهدات', views, Icons.visibility))]),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: metric('الإعجابات', likes, Icons.thumb_up)), const SizedBox(width: 12), Expanded(child: metric('عدم الإعجاب', dislikes, Icons.thumb_down))]),
          const SizedBox(height: 16),
          const Text('أكثر الوصفات مشاهدة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkBrown)),
          const SizedBox(height: 12),
          if (ranked.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('لا توجد مشاهدات مسجلة بعد')),
          ...ranked.map((r) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .06), blurRadius: 16, offset: const Offset(0, 5))]),
            child: ListTile(title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkBrown)), subtitle: Text(r.category), trailing: Text('${recipeViews[r.id]} مشاهدة', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold))),
          )),
          const SizedBox(height: 12),
          const Text('فتحات الوصفات ليست عدد الزوار الفريدين. عدادات التفاعل الحالية لا تضمن تفاعلًا واحدًا لكل مستخدم.'),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const RecipeManagementScreen())),
            style: FilledButton.styleFrom(backgroundColor: AppColors.darkBrown, foregroundColor: AppColors.gold, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
            icon: const Icon(Icons.edit_note),
            label: const Text('إدارة الوصفات'),
          ),
        ),
      ])),
    );
  }
}

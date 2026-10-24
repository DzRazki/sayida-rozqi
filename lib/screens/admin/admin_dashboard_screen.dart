import 'package:flutter/material.dart';
import '../../models/recipe.dart';
import '../../services/supabase_service.dart';
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

  Widget metric(String title, int value) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$value', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), Text(title)])));

  @override
  Widget build(BuildContext context) {
    if (!SupabaseService.isAdmin()) return Scaffold(appBar: AppBar(title: const Text('الإدارة')), body: const Center(child: Text('يلزم تسجيل دخول الإدارة')));
    final ranked = recipes.where((r) => (recipeViews[r.id] ?? 0) > 0).take(5).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة الإحصائيات'), actions: [IconButton(onPressed: loading ? null : load, tooltip: 'تحديث', icon: const Icon(Icons.refresh))]),
      body: loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(onRefresh: load, child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(16), children: [
        if (error != null) ...[Text(error!), const SizedBox(height: 12), OutlinedButton(onPressed: load, child: const Text('إعادة المحاولة'))] else ...[
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: metric('إجمالي الوصفات', recipes.length)), Expanded(child: metric('إجمالي فتحات الوصفات', views))]),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: metric('الإعجابات المسجلة', likes)), Expanded(child: metric('عدم الإعجاب المسجل', dislikes))]),
          const SizedBox(height: 12),
          const Text('فتحات الوصفات ليست عدد الزوار الفريدين. عدادات التفاعل الحالية لا تضمن تفاعلًا واحدًا لكل مستخدم.'),
          const SizedBox(height: 16),
          const Text('أكثر الوصفات مشاهدة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (ranked.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('لا توجد مشاهدات مسجلة بعد')),
          ...ranked.map((r) => Card(child: ListTile(title: Text(r.name), subtitle: Text(r.category), trailing: Text('${recipeViews[r.id]}')))),
          const SizedBox(height: 12),
          const Text('عدد زوار التطبيق وإجمالي المفضلات: لم يتم تفعيل جمعهما بعد.'),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const RecipeManagementScreen())), icon: const Icon(Icons.edit_note), label: const Text('إدارة الوصفات')),
      ])),
    );
  }
}

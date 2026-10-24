import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/supabase_service.dart';
import '../theme.dart';
import 'recipe_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<Recipe> recipes = [];
  int views = 0;
  int likes = 0;
  int dislikes = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      recipes = await SupabaseService.fetchRecipes(admin: true);
      final stats = await SupabaseService.client.from('recipe_stats').select('views,likes,dislikes');
      views = 0;
      likes = 0;
      dislikes = 0;
      for (final item in stats) {
        views += int.tryParse(item['views']?.toString() ?? '') ?? 0;
        likes += int.tryParse(item['likes']?.toString() ?? '') ?? 0;
        dislikes += int.tryParse(item['dislikes']?.toString() ?? '') ?? 0;
      }
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة الإحصائيات')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              Row(children: [
                Expanded(child: _StatCard(title: 'الوصفات', value: '${recipes.length}', icon: Icons.restaurant_menu)),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(title: 'المشاهدات', value: '$views', icon: Icons.visibility)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _StatCard(title: 'الإعجابات', value: '$likes', icon: Icons.thumb_up)),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(title: 'عدم الإعجاب', value: '$dislikes', icon: Icons.thumb_down)),
              ]),
              const SizedBox(height: 20),
              FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecipeManagementScreen())), icon: const Icon(Icons.edit_note), label: const Text('إدارة الوصفات')),
              const SizedBox(height: 20),
              const Text('أكثر الوصفات مشاهدة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...recipes.take(5).map((recipe) => Card(margin: const EdgeInsets.only(bottom: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: ListTile(leading: const Icon(Icons.local_fire_department, color: AppColors.gold), title: Text(recipe.name), subtitle: Text(recipe.category)))),
            ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .06), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: AppColors.gold), const SizedBox(height: 10), Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), Text(title, style: const TextStyle(color: AppColors.muted, fontSize: 12))]),
    );
  }
}

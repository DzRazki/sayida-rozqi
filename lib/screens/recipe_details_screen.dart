import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipe.dart';
import '../services/favorites_service.dart';
import '../services/recipe_stats_service.dart';
import '../theme.dart';
import 'ingredients_screen.dart';
import 'preparation_steps_screen.dart';
import 'user_auth_screen.dart';

class RecipeDetailsScreen extends StatefulWidget {
  final Recipe recipe;
  const RecipeDetailsScreen({super.key, required this.recipe});
  @override
  State<RecipeDetailsScreen> createState() => _RecipeDetailsScreenState();
}
class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> {
  bool favorite = false, busy = true, available = false;
  String? selected, error;
  RecipeStats stats = const RecipeStats(views: 0, likes: 0, dislikes: 0);
  WebViewController? video;
  SupabaseClient get client => Supabase.instance.client;
  @override
  void initState() {
    super.initState();
    loadFavorite();
    refresh(countView: true);
    final url = Uri.tryParse(widget.recipe.youtubeUrl);
    final id = url?.queryParameters['v'] ?? url?.pathSegments.lastOrNull;
    if (id != null && id.isNotEmpty) {
      video = WebViewController()..setJavaScriptMode(JavaScriptMode.unrestricted)..loadRequest(Uri.parse('https://www.youtube.com/embed/$id?playsinline=1'));
    }
  }
  void report(Object e) {
    if (!mounted) return;
    setState(() => error = e is PostgrestException ? 'تعذر تنفيذ الطلب: ${e.code}. تحققي من تفعيل ملف account_reactions.sql وتأكيد البريد.' : 'تعذر الاتصال. حاولي تحديث الإحصائيات.');
  }
  Future<void> loadFavorite() async {
    try {
      final value = await FavoritesService.isFavorite(widget.recipe.id);
      if (mounted) setState(() => favorite = value);
    } catch (e) { report(e); }
  }
  Future<void> toggleFavorite() async {
    try { await FavoritesService.toggle(widget.recipe.id); await loadFavorite(); } catch (e) { report(e); }
  }
  Future<void> readState() async {
    final userId = client.auth.currentUser?.id;
    final row = await client.from('recipe_stats').select('views,likes,dislikes').eq('recipe_id', widget.recipe.id).maybeSingle();
    final own = userId == null ? null : await client.from('account_recipe_reactions').select('reaction').eq('recipe_id', widget.recipe.id).eq('user_id', userId).maybeSingle();
    if (!mounted || userId != client.auth.currentUser?.id) return;
    setState(() {
      stats = row == null ? const RecipeStats(views: 0, likes: 0, dislikes: 0) : RecipeStats.fromJson(row);
      selected = own?['reaction'] as String?; available = true;
    });
  }
  Future<void> refresh({bool countView = false}) async {
    setState(() { busy = true; error = null; });
    try {
      if (countView) {
        try { await client.rpc('increment_recipe_view', params: {'recipe_id': widget.recipe.id}); } catch (e) { report(e); }
      }
      await readState();
    } catch (e) { report(e); } finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> react(String choice) async {
    if (busy) return;
    setState(() { busy = true; error = null; });
    bool saved = false;
    try {
      if (client.auth.currentUser == null) {
        await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const UserAuthScreen()));
        if (!mounted || client.auth.currentUser == null) return;
      }
      await readState();
      if (!mounted) return;
      await client.rpc('set_recipe_reaction', params: {'p_recipe_id': widget.recipe.id, 'p_reaction': selected == choice ? null : choice});
      saved = true;
      await readState();
    } catch (e) {
      if (saved && mounted) {
        setState(() => error = 'تم الحفظ لكن تعذر تحديث العرض. اضغطي تحديث الإحصائيات قبل التفاعل مجددًا.');
      } else { report(e); }
    } finally { if (mounted) setState(() => busy = false); }
  }
  Widget reaction(String choice, IconData outline, IconData filled, int count) => Expanded(child: FilledButton.tonalIcon(
    onPressed: busy ? null : () => react(choice),
    icon: Icon(selected == choice ? filled : outline, color: selected == choice ? AppColors.gold : null),
    label: Text(available ? '$count' : (choice == 'like' ? 'إعجاب' : 'عدم إعجاب')),
  ));
  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    return Scaffold(body: CustomScrollView(slivers: [
      SliverAppBar(expandedHeight: 260, pinned: true,
        actions: [IconButton(onPressed: toggleFavorite, icon: Icon(favorite ? Icons.favorite : Icons.favorite_border, color: AppColors.gold))],
        flexibleSpace: FlexibleSpaceBar(background: recipe.imageUrl.isEmpty
          ? Container(color: AppColors.brown, child: const Center(child: Text('🍽️', style: TextStyle(fontSize: 60))))
          : Image.network(recipe.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.brown))),
      ),
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(recipe.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('${recipe.category} · ${recipe.time} دقيقة · ${recipe.servings} أشخاص', style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 10),
        Text(available ? '${stats.views} مشاهدة' : 'المشاهدات غير متاحة', style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 12), Text(recipe.description), const SizedBox(height: 16),
        if (busy) const LinearProgressIndicator(),
        Row(children: [reaction('like', Icons.thumb_up_outlined, Icons.thumb_up, stats.likes), const SizedBox(width: 8), reaction('dislike', Icons.thumb_down_outlined, Icons.thumb_down, stats.dislikes)]),
        if (error != null) ...[const SizedBox(height: 8), Text(error!)],
        TextButton(onPressed: busy ? null : () => refresh(), child: const Text('تحديث الإحصائيات')),
        const SizedBox(height: 18),
        if (video != null) ...[
          const Text('فيديو الوصفة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 10),
          ClipRRect(borderRadius: BorderRadius.circular(16), child: AspectRatio(aspectRatio: 16 / 9, child: WebViewWidget(controller: video!))), const SizedBox(height: 18),
        ],
        Row(children: [
          Expanded(child: FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IngredientsScreen(recipe: recipe))), child: const Text('المكونات'))),
          const SizedBox(width: 8),
          Expanded(child: FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PreparationStepsScreen(recipe: recipe))), child: const Text('التحضير'))),
        ]),
      ]))),
    ]));
  }
}

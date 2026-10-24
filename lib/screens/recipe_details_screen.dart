import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipe.dart';
import '../services/favorites_service.dart';
import '../services/recipe_stats_service.dart';
import '../theme.dart';
import 'ingredients_screen.dart';
import 'preparation_steps_screen.dart';

class RecipeDetailsScreen extends StatefulWidget {
  final Recipe recipe;
  const RecipeDetailsScreen({super.key, required this.recipe});
  @override
  State<RecipeDetailsScreen> createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> {
  bool favorite = false;
  bool sending = false;
  bool statsLoading = true;
  bool statsAvailable = false;
  String? statsError;
  RecipeStats stats = const RecipeStats(views: 0, likes: 0, dislikes: 0);
  WebViewController? youtubeController;
  SupabaseClient get client => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    loadFavorite();
    loadStats(countView: true);
    final id = videoId;
    if (id != null && id.isNotEmpty) {
      youtubeController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse('https://www.youtube.com/embed/$id?playsinline=1'));
    }
  }

  String? get videoId {
    final url = widget.recipe.youtubeUrl;
    if (url.isEmpty) return null;
    return Uri.tryParse(url)?.queryParameters['v'] ?? Uri.tryParse(url)?.pathSegments.lastOrNull;
  }

  void notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String failure(Object error) {
    if (error is PostgrestException) {
      return 'تعذر تنفيذ الطلب. رمز قاعدة البيانات: ${error.code}';
    }
    return 'تعذر الاتصال بالخادم. تحققي من الاتصال وحاولي مجددًا.';
  }

  Future<void> loadFavorite() async {
    try {
      final value = await FavoritesService.isFavorite(widget.recipe.id);
      if (mounted) setState(() => favorite = value);
    } catch (_) {
      notify('تعذر تحميل حالة المفضلة');
    }
  }

  Future<void> toggleFavorite() async {
    try {
      await FavoritesService.toggle(widget.recipe.id);
      await loadFavorite();
    } catch (_) {
      notify('تعذر تحديث المفضلة');
    }
  }

  Future<RecipeStats> readStats() async {
    final row = await client.from('recipe_stats').select('views,likes,dislikes').eq('recipe_id', widget.recipe.id).maybeSingle();
    return row == null ? const RecipeStats(views: 0, likes: 0, dislikes: 0) : RecipeStats.fromJson(row);
  }

  Future<void> loadStats({bool countView = false}) async {
    setState(() { statsLoading = true; statsError = null; });
    String? viewError;
    if (countView) {
      try {
        await client.rpc('increment_recipe_view', params: {'recipe_id': widget.recipe.id});
      } catch (error) {
        viewError = 'تعذر تسجيل المشاهدة. ${failure(error)}';
      }
    }
    try {
      final value = await readStats();
      if (mounted) setState(() { stats = value; statsAvailable = true; statsError = viewError; });
    } catch (error) {
      if (mounted) setState(() { statsAvailable = false; statsError = failure(error); });
    } finally {
      if (mounted) setState(() => statsLoading = false);
    }
  }

  Future<void> react(bool like) async {
    if (sending || statsLoading) return;
    setState(() => sending = true);
    bool saved = false;
    try {
      await client.rpc('react_to_recipe', params: {'recipe_id': widget.recipe.id, 'reaction': like ? 'like' : 'dislike'});
      saved = true;
      final value = await readStats();
      if (mounted) setState(() { stats = value; statsAvailable = true; statsError = null; });
      notify('تم تسجيل التفاعل');
    } catch (error) {
      final message = saved
          ? 'تم تسجيل التفاعل لكن تعذر تحديث العداد. حدّثي الإحصائيات بدل إعادة الضغط.'
          : 'لم يتم تأكيد تسجيل التفاعل. ${failure(error)}';
      if (mounted) setState(() => statsError = message);
      notify(message);
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    return Scaffold(body: CustomScrollView(slivers: [
      SliverAppBar(
        expandedHeight: 260, pinned: true,
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
        Row(children: [
          const Icon(Icons.visibility, size: 18, color: AppColors.muted),
          const SizedBox(width: 4),
          Text(statsAvailable ? '${stats.views} مشاهدة' : 'المشاهدات غير متاحة', style: const TextStyle(color: AppColors.muted)),
        ]),
        const SizedBox(height: 12),
        Text(recipe.description),
        const SizedBox(height: 16),
        if (statsLoading || sending) const LinearProgressIndicator(),
        Row(children: [
          Expanded(child: FilledButton.tonalIcon(onPressed: sending || statsLoading ? null : () => react(true), icon: const Icon(Icons.thumb_up_outlined), label: Text(statsAvailable ? '${stats.likes}' : 'إعجاب'))),
          const SizedBox(width: 8),
          Expanded(child: FilledButton.tonalIcon(onPressed: sending || statsLoading ? null : () => react(false), icon: const Icon(Icons.thumb_down_outlined), label: Text(statsAvailable ? '${stats.dislikes}' : 'عدم إعجاب'))),
        ]),
        if (statsError != null) ...[
          const SizedBox(height: 8), Text(statsError!),
          TextButton(onPressed: sending || statsLoading ? null : () => loadStats(), child: const Text('تحديث الإحصائيات')),
        ],
        const SizedBox(height: 18),
        if (youtubeController != null) ...[
          const Text('فيديو الوصفة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ClipRRect(borderRadius: BorderRadius.circular(16), child: AspectRatio(aspectRatio: 16 / 9, child: WebViewWidget(controller: youtubeController!))),
          const SizedBox(height: 18),
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

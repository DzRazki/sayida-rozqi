import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
  bool videoLoading = false;
  String? selected, error, videoError;
  RecipeStats stats = const RecipeStats(views: 0, likes: 0, dislikes: 0);
  WebViewController? video;
  SupabaseClient get client => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    loadFavorite();
    refresh(countView: true);
    if (widget.recipe.youtubeUrl.trim().isNotEmpty) prepareVideo();
  }

  Future<void> prepareVideo() async {
    if (videoLoading) return;
    setState(() { videoLoading = true; videoError = null; });
    try {
      final url = Uri.tryParse(widget.recipe.youtubeUrl.trim());
      final host = url?.host.toLowerCase() ?? '';
      if (!(host == 'youtu.be' || host == 'youtube.com' || host.endsWith('.youtube.com') || host == 'youtube-nocookie.com' || host.endsWith('.youtube-nocookie.com'))) {
        throw const FormatException('Invalid YouTube URL');
      }
      final id = url?.queryParameters['v'] ?? url?.pathSegments.lastOrNull;
      if (id == null || !RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(id)) throw const FormatException('Invalid video ID');
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      final identity = Uri(scheme: 'https', host: info.packageName.toLowerCase()).toString();
      final controller = WebViewController();
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setNavigationDelegate(NavigationDelegate(onWebResourceError: (event) {
        if (event.isForMainFrame == true && mounted) setState(() => videoError = 'تعذر تحميل الفيديو. تحققي من الاتصال وأعيدي المحاولة.');
      }));
      final embed = Uri.https('www.youtube.com', '/embed/$id', {'playsinline': '1', 'origin': identity});
      await controller.loadRequest(embed, headers: {'Referer': identity});
      if (mounted) setState(() => video = controller);
    } on FormatException {
      if (mounted) setState(() => videoError = 'رابط فيديو الوصفة غير صالح.');
    } catch (_) {
      if (mounted) setState(() => videoError = 'تعذر تهيئة المشغل. أعيدي المحاولة.');
    } finally { if (mounted) setState(() => videoLoading = false); }
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

  Widget reaction(String choice, IconData outline, IconData filled, int count) => Expanded(
    child: FilledButton.tonalIcon(
      onPressed: busy ? null : () => react(choice),
      style: FilledButton.styleFrom(
        backgroundColor: selected == choice ? AppColors.gold.withValues(alpha: .22) : Colors.white,
        foregroundColor: AppColors.darkBrown,
      ),
      icon: Icon(selected == choice ? filled : outline, color: selected == choice ? AppColors.gold : AppColors.brown),
      label: Text(available ? '$count' : (choice == 'like' ? 'إعجاب' : 'عدم إعجاب')),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4EF),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.darkBrown,
            actions: [
              IconButton(
                onPressed: toggleFavorite,
                icon: Icon(favorite ? Icons.favorite : Icons.favorite_border, color: AppColors.gold),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: recipe.imageUrl.isEmpty
                  ? Container(color: AppColors.brown, child: const Center(child: Text('🍽️', style: TextStyle(fontSize: 60))))
                  : Image.network(
                      recipe.imageUrl,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                      gaplessPlayback: true,
                      errorBuilder: (_, __, ___) => Container(color: AppColors.brown),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.name, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: AppColors.darkBrown)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip(recipe.category),
                      _chip('${recipe.time} دقيقة'),
                      _chip('${recipe.servings} أشخاص'),
                      _chip(available ? '${stats.views} مشاهدة' : 'المشاهدات غير متاحة'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(recipe.description, style: const TextStyle(height: 1.6, color: AppColors.darkBrown)),
                  const SizedBox(height: 16),
                  if (busy) const LinearProgressIndicator(color: AppColors.gold),
                  const SizedBox(height: 12),
                  Row(children: [
                    reaction('like', Icons.thumb_up_outlined, Icons.thumb_up, stats.likes),
                    const SizedBox(width: 8),
                    reaction('dislike', Icons.thumb_down_outlined, Icons.thumb_down, stats.dislikes),
                  ]),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  ],
                  TextButton(
                    onPressed: busy ? null : () => refresh(),
                    child: const Text('تحديث الإحصائيات', style: TextStyle(color: AppColors.gold)),
                  ),
                  const SizedBox(height: 18),
                  if (recipe.youtubeUrl.trim().isNotEmpty) ...[
                    const Text('فيديو الوصفة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkBrown)),
                    const SizedBox(height: 10),
                    if (videoLoading) const LinearProgressIndicator(color: AppColors.gold),
                    if (video != null) LayoutBuilder(builder: (context, constraints) {
                      final height = constraints.maxWidth / (16 / 9);
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: SizedBox(height: height < 200 ? 200 : height, child: WebViewWidget(controller: video!)),
                      );
                    }),
                    if (videoError != null) Text(videoError!),
                    TextButton.icon(
                      onPressed: videoLoading ? null : prepareVideo,
                      icon: const Icon(Icons.refresh, color: AppColors.gold),
                      label: const Text('إعادة تحميل الفيديو', style: TextStyle(color: AppColors.gold)),
                    ),
                    const SizedBox(height: 18),
                  ],
                  Row(children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IngredientsScreen(recipe: recipe))),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.darkBrown, foregroundColor: AppColors.gold, padding: const EdgeInsets.symmetric(vertical: 14)),
                        icon: const Icon(Icons.list_alt),
                        label: const Text('المكونات'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PreparationStepsScreen(recipe: recipe))),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.darkBrown, padding: const EdgeInsets.symmetric(vertical: 14)),
                        icon: const Icon(Icons.soup_kitchen),
                        label: const Text('التحضير'),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.gold.withValues(alpha: .45))),
    child: Text(text, style: const TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.w600)),
  );
}

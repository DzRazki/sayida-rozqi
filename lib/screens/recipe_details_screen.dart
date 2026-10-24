import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
  RecipeStats stats = const RecipeStats(views: 0, likes: 0, dislikes: 0);
  WebViewController? youtubeController;

  @override
  void initState() {
    super.initState();
    loadFavorite();
    loadStats();
    _prepareVideo();
  }

  String? get videoId {
    final url = widget.recipe.youtubeUrl;
    if (url.isEmpty) return null;
    return Uri.tryParse(url)?.queryParameters['v'] ?? Uri.tryParse(url)?.pathSegments.lastOrNull;
  }

  void _prepareVideo() {
    final id = videoId;
    if (id == null || id.isEmpty) return;
    youtubeController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://www.youtube.com/embed/$id?playsinline=1'));
  }

  Future<void> loadFavorite() async {
    favorite = await FavoritesService.isFavorite(widget.recipe.id);
    if (mounted) setState(() {});
  }

  Future<void> toggleFavorite() async {
    await FavoritesService.toggle(widget.recipe.id);
    favorite = await FavoritesService.isFavorite(widget.recipe.id);
    if (mounted) setState(() {});
  }

  Future<void> loadStats() async {
    await RecipeStatsService.incrementView(widget.recipe.id);
    final value = await RecipeStatsService.fetch(widget.recipe.id);
    if (mounted) setState(() => stats = value);
  }

  Future<void> react(bool like) async {
    await RecipeStatsService.react(widget.recipe.id, like);
    final value = await RecipeStatsService.fetch(widget.recipe.id);
    if (mounted) setState(() => stats = value);
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            actions: [IconButton(onPressed: toggleFavorite, icon: Icon(favorite ? Icons.favorite : Icons.favorite_border, color: AppColors.gold))],
            flexibleSpace: FlexibleSpaceBar(
              background: recipe.imageUrl.isEmpty
                  ? Container(color: AppColors.brown, child: const Center(child: Text('🍽️', style: TextStyle(fontSize: 60))))
                  : Image.network(recipe.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.brown)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(recipe.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('${recipe.category} · ${recipe.time} دقيقة · ${recipe.servings} أشخاص', style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 10),
                Row(children: [
                  const Icon(Icons.visibility, size: 18, color: AppColors.muted),
                  const SizedBox(width: 4),
                  Text('${stats.views} مشاهدة', style: const TextStyle(color: AppColors.muted)),
                ]),
                const SizedBox(height: 12),
                Text(recipe.description),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: FilledButton.tonalIcon(onPressed: () => react(true), icon: const Icon(Icons.thumb_up_outlined), label: Text('${stats.likes}'))),
                  const SizedBox(width: 8),
                  Expanded(child: FilledButton.tonalIcon(onPressed: () => react(false), icon: const Icon(Icons.thumb_down_outlined), label: Text('${stats.dislikes}'))),
                ]),
                const SizedBox(height: 18),
                if (youtubeController != null) ...[
                  const Text('فيديو الوصفة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(aspectRatio: 16 / 9, child: WebViewWidget(controller: youtubeController!)),
                  ),
                  const SizedBox(height: 18),
                ],
                Row(children: [
                  Expanded(child: FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IngredientsScreen(recipe: recipe))), child: const Text('المكونات'))),
                  const SizedBox(width: 8),
                  Expanded(child: FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PreparationStepsScreen(recipe: recipe))), child: const Text('التحضير'))),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

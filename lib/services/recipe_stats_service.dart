import 'package:supabase_flutter/supabase_flutter.dart';

class RecipeStats {
  final int views;
  final int likes;
  final int dislikes;
  const RecipeStats({required this.views, required this.likes, required this.dislikes});

  factory RecipeStats.fromJson(Map<String, dynamic> json) => RecipeStats(
        views: int.tryParse(json['views']?.toString() ?? '') ?? 0,
        likes: int.tryParse(json['likes']?.toString() ?? '') ?? 0,
        dislikes: int.tryParse(json['dislikes']?.toString() ?? '') ?? 0,
      );
}

class RecipeStatsService {
  static final _client = Supabase.instance.client;

  static Future<RecipeStats> fetch(String recipeId) async {
    try {
      final data = await _client.from('recipe_stats').select('*').eq('recipe_id', recipeId).maybeSingle();
      if (data == null) return const RecipeStats(views: 0, likes: 0, dislikes: 0);
      return RecipeStats.fromJson(data);
    } catch (_) {
      return const RecipeStats(views: 0, likes: 0, dislikes: 0);
    }
  }

  static Future<void> incrementView(String recipeId) async {
    try {
      await _client.rpc('increment_recipe_view', params: {'recipe_id': recipeId});
    } catch (_) {}
  }

  static Future<void> react(String recipeId, bool like) async {
    try {
      await _client.rpc('react_to_recipe', params: {'recipe_id': recipeId, 'reaction': like ? 'like' : 'dislike'});
    } catch (_) {}
  }
}

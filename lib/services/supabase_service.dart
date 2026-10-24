import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipe.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  static final _client = Supabase.instance.client;

  static Future<List<Recipe>> fetchRecipes({bool admin = false, bool newestFirst = false}) async {
    if (newestFirst) {
      final recipes = <Recipe>[];
      const batchSize = 200;
      int offset = 0;
      while (true) {
        var query = _client.from('recipes').select('*');
        if (!admin) query = query.eq('published', true);
        final data = await query.order('created_at', ascending: false).order('id', ascending: false).range(offset, offset + batchSize - 1);
        recipes.addAll(data.map<Recipe>((item) => Recipe.fromJson(item)));
        if (data.length < batchSize) break;
        offset += batchSize;
      }
      return recipes;
    }
    var query = _client.from('recipes').select('*');
    if (!admin) query = query.eq('published', true);
    final data = await query.order('featured', ascending: false).order('created_at', ascending: false);
    return data.map<Recipe>((item) => Recipe.fromJson(item)).toList();
  }

  static Future<void> saveRecipe(Map<String, dynamic> values, {String? id}) async {
    if (id == null) {
      await _client.from('recipes').insert(values);
    } else {
      await _client.from('recipes').update(values).eq('id', id);
    }
  }

  static Future<void> deleteRecipe(String id) async {
    await _client.from('recipes').delete().eq('id', id);
  }

  static bool isAdmin() {
    final user = _client.auth.currentUser;
    return user?.id == 'e33bc325-89f7-49ab-afdb-17794b06fc7d';
  }

  static Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<void> signOut() => _client.auth.signOut();
}

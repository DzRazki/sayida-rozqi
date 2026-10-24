import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesService {
  static const _key = 'rozqi-favorites';
  static final changes = ValueNotifier<int>(0);
  static final _pending = <String>{};
  static bool _watching = false;
  static SupabaseClient get _client => Supabase.instance.client;
  static void _watch() {
    if (_watching) return;
    _watching = true;
    _client.auth.onAuthStateChange.listen((_) => changes.value++);
  }
  static void _check(String? user) {
    if (_client.auth.currentUser?.id != user) throw StateError('Account changed');
  }
  static Future<Set<String>> local() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? []).toSet();
  }
  static Future<Set<String>> load() async {
    _watch();
    final user = _client.auth.currentUser?.id;
    if (user == null) {
      final values = await local(); _check(user); return values;
    }
    final values = <String>{};
    var offset = 0;
    while (true) {
      final rows = await _client.from('account_recipe_favorites').select('recipe_id').eq('user_id', user).order('recipe_id').range(offset, offset + 499);
      _check(user);
      values.addAll(rows.map((r) => r['recipe_id'] as String));
      if (rows.length < 500) break;
      offset += 500;
    }
    return values;
  }
  static Future<bool> isFavorite(String id) async => (await load()).contains(id);
  static Future<void> toggle(String id) async {
    _watch();
    final user = _client.auth.currentUser?.id;
    final key = '${user ?? 'guest'}:$id';
    if (!_pending.add(key)) return;
    try {
      if (user == null) {
        final prefs = await SharedPreferences.getInstance();
        final items = (prefs.getStringList(_key) ?? []).toSet();
        _check(user);
        if (!items.add(id)) items.remove(id);
        if (!await prefs.setStringList(_key, items.toList())) throw StateError('Local save failed');
      } else {
        final row = await _client.from('account_recipe_favorites').select('recipe_id').eq('user_id', user).eq('recipe_id', id).maybeSingle();
        _check(user);
        if (row == null) {
          await _client.from('account_recipe_favorites').upsert({'user_id': user, 'recipe_id': id}, onConflict: 'user_id,recipe_id', ignoreDuplicates: true);
        } else {
          await _client.from('account_recipe_favorites').delete().eq('user_id', user).eq('recipe_id', id);
        }
        _check(user);
      }
      changes.value++;
    } finally { _pending.remove(key); }
  }
  static Future<bool> canImport() async {
    final user = _client.auth.currentUser?.id;
    if (user == null) return false;
    final prefs = await SharedPreferences.getInstance();
    final hasItems = (prefs.getStringList(_key) ?? []).isNotEmpty;
    _check(user);
    return hasItems && !(prefs.getBool('favorites-imported:$user') ?? false);
  }
  static Future<void> importLocal(String expectedUser) async {
    _check(expectedUser);
    final ids = await local();
    final valid = <String>{};
    final list = ids.toList();
    for (var i = 0; i < list.length; i += 100) {
      final end = i + 100 < list.length ? i + 100 : list.length;
      final rows = await _client.from('recipes').select('id').eq('published', true).inFilter('id', list.sublist(i, end));
      _check(expectedUser);
      valid.addAll(rows.map((r) => r['id'] as String));
    }
    if (valid.isNotEmpty) {
      await _client.from('account_recipe_favorites').upsert(valid.map((id) => {'user_id': expectedUser, 'recipe_id': id}).toList(), onConflict: 'user_id,recipe_id', ignoreDuplicates: true);
    }
    _check(expectedUser);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('favorites-imported:$expectedUser', true);
    changes.value++;
  }
}

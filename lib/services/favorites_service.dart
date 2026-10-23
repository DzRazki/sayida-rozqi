import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const _key = 'rozqi-favorites';

  static Future<Set<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? []).toSet();
  }

  static Future<void> toggle(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final items = (prefs.getStringList(_key) ?? []).toSet();
    if (!items.add(id)) items.remove(id);
    await prefs.setStringList(_key, items.toList());
  }

  static Future<bool> isFavorite(String id) async {
    final items = await load();
    return items.contains(id);
  }
}

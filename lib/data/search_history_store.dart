import 'package:shared_preferences/shared_preferences.dart';

const _kSearchHistoryKey = 'search_history';
const _kMaxHistory = 8;

/// Local (per-device) recent-search list — same direct
/// SharedPreferences.getInstance() pattern already used by ThemeController,
/// no separate storage abstraction. Most-recent first, deduplicated,
/// capped at [_kMaxHistory].
class SearchHistoryStore {
  SearchHistoryStore._();

  static Future<List<String>> recent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kSearchHistoryKey) ?? const [];
  }

  static Future<void> add(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_kSearchHistoryKey) ?? const [];
    final updated = [
      trimmed,
      ...current.where((q) => q.toLowerCase() != trimmed.toLowerCase()),
    ].take(_kMaxHistory).toList();
    await prefs.setStringList(_kSearchHistoryKey, updated);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSearchHistoryKey);
  }
}

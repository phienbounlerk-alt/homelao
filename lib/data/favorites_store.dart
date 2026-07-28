import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'analytics_repository.dart';

/// App-wide favorited-listing state for the signed-in user, backed by the
/// `favorites` table. A single shared instance so the heart toggle on a
/// card stays in sync no matter which screen (Home, Search, Detail) shows
/// that listing.
class FavoritesStore extends ChangeNotifier {
  FavoritesStore._();

  static final instance = FavoritesStore._();

  final Set<String> _favoriteIds = {};
  static SupabaseClient get _client => Supabase.instance.client;

  bool isFavorite(String propertyId) => _favoriteIds.contains(propertyId);

  int get count => _favoriteIds.length;

  /// Fetches the current user's favorites. Call after sign-in.
  Future<void> loadForCurrentUser() async {
    final userId = _client.auth.currentUser?.id;
    _favoriteIds.clear();
    if (userId != null) {
      final rows = await _client
          .from('favorites')
          .select('property_id')
          .eq('user_id', userId);
      for (final row in rows as List) {
        _favoriteIds.add(row['property_id'] as String);
      }
    }
    notifyListeners();
  }

  /// Clears local state. Call on sign-out.
  void clear() {
    _favoriteIds.clear();
    notifyListeners();
  }

  /// Returns whether the toggle actually persisted, so callers can tell the
  /// user when it silently reverted instead of leaving them to wonder why
  /// the heart didn't stay filled.
  Future<bool> toggle(String propertyId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final wasFavorite = _favoriteIds.contains(propertyId);
    wasFavorite
        ? _favoriteIds.remove(propertyId)
        : _favoriteIds.add(propertyId);
    notifyListeners();

    try {
      if (wasFavorite) {
        await _client.from('favorites').delete().match({
          'user_id': userId,
          'property_id': propertyId,
        });
      } else {
        await _client.from('favorites').insert({
          'user_id': userId,
          'property_id': propertyId,
        });
        AnalyticsRepository.track('favorited', {'property_id': propertyId});
      }
      return true;
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      wasFavorite
          ? _favoriteIds.add(propertyId)
          : _favoriteIds.remove(propertyId);
      notifyListeners();
      return false;
    }
  }
}

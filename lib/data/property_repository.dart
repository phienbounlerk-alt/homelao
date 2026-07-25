import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/property.dart';

class PropertyRepository {
  PropertyRepository._();

  static final _client = Supabase.instance.client;

  /// One page of search results, filtered server-side.
  static Future<List<Property>> fetchPage({
    required int page,
    int pageSize = 10,
    String? query,
    String? category,
    double? minPrice,
    double? maxPrice,
    int? minBeds,
    String? location,
  }) async {
    final trimmedQuery = query?.trim();
    final trimmedCategory = category?.trim();
    final trimmedLocation = location?.trim();

    var builder = _client.from('properties').select();
    if (trimmedQuery != null && trimmedQuery.isNotEmpty) {
      final escaped = trimmedQuery.replaceAll(',', ' ').replaceAll('%', ' ');
      builder = builder.or('title.ilike.%$escaped%,location.ilike.%$escaped%');
    }
    if (trimmedCategory != null && trimmedCategory.isNotEmpty) {
      builder = builder.ilike('title', '%$trimmedCategory%');
    }
    if (minPrice != null) builder = builder.gte('price_lak', minPrice);
    if (maxPrice != null) builder = builder.lte('price_lak', maxPrice);
    if (minBeds != null) builder = builder.gte('beds', minBeds);
    if (trimmedLocation != null && trimmedLocation.isNotEmpty) {
      builder = builder.ilike('location', '$trimmedLocation%');
    }

    final from = page * pageSize;
    final to = from + pageSize - 1;
    final rows = await builder
        .order('featured', ascending: false)
        .order('created_at', ascending: false)
        .range(from, to);
    return (rows as List)
        .map((row) => Property.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Currently-boosted listings (paid, admin-confirmed, still within their
  /// window) for the Home screen's featured section.
  static Future<List<Property>> fetchFeatured({int limit = 8}) async {
    final rows = await _client
        .from('properties')
        .select()
        .eq('featured', true)
        .gt('featured_until', DateTime.now().toIso8601String())
        .order('featured_until', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((row) => Property.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Distinct district names, for the search filter sheet's location chips.
  static Future<List<String>> fetchLocations() async {
    final rows = await _client.from('properties').select('location');
    return (rows as List)
        .map((row) => (row as Map<String, dynamic>)['location'] as String)
        .map((loc) => loc.split(',').first.trim())
        .toSet()
        .toList();
  }

  static Future<List<Property>> fetchRecommended({int limit = 5}) async {
    final rows = await _client
        .from('properties')
        .select()
        .order('rating', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((row) => Property.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Property>> fetchNewest({int limit = 4}) async {
    final rows = await _client
        .from('properties')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((row) => Property.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Listings posted by the current user.
  static Future<List<Property>> fetchMine() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final rows = await _client
        .from('properties')
        .select()
        .eq('owner_id', userId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((row) => Property.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Listings the current user has favorited.
  static Future<List<Property>> fetchSaved() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final rows = await _client
        .from('favorites')
        .select('properties(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map(
          (row) => Property.fromMap(
            (row as Map<String, dynamic>)['properties'] as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}

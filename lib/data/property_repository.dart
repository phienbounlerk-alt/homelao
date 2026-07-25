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

  /// Single listing by id — used to open a property from a notification.
  /// Null if it no longer exists or isn't visible to the current user (RLS).
  static Future<Property?> fetchById(String id) async {
    final row = await _client
        .from('properties')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return Property.fromMap(row);
  }

  /// Listings within [radiusKm] of a point, nearest first. Only rows with a
  /// saved lat/lng are ever candidates — most existing listings predate
  /// geotagging and simply won't appear here.
  static Future<List<Property>> fetchNear({
    required double lat,
    required double lng,
    double radiusKm = 15,
  }) async {
    final ranked = await _client.rpc(
      'properties_near',
      params: {'origin_lat': lat, 'origin_lng': lng, 'radius_km': radiusKm},
    ) as List;
    if (ranked.isEmpty) return [];
    final distanceById = <String, double>{
      for (final row in ranked)
        (row as Map<String, dynamic>)['id'] as String:
            (row['distance_km'] as num).toDouble(),
    };
    final rows = await _client
        .from('properties')
        .select()
        .inFilter('id', distanceById.keys.toList());
    final properties = (rows as List)
        .map((row) => Property.fromMap(row as Map<String, dynamic>))
        .map((p) => p.withDistance(distanceById[p.id]!))
        .toList();
    properties.sort((a, b) => a.distanceKm!.compareTo(b.distanceKm!));
    return properties;
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

  /// Live-updating "newest listings" — RLS still applies per-connection, so
  /// a viewer only ever sees rows they're allowed to see (approved, or
  /// their own/admin). New approvals appear here without a manual refresh.
  static Stream<List<Property>> streamNewest({int limit = 4}) {
    return _client
        .from('properties')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(limit)
        .map(
          (rows) =>
              rows.map((row) => Property.fromMap(row)).toList(growable: false),
        );
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

  /// Edits an existing listing and re-queues it for moderation — the RLS
  /// with-check pins the resulting status to 'pending' regardless of what's
  /// passed here, so this can't be used to self-approve.
  static Future<void> update({
    required String id,
    required String imageUrl,
    required List<String> photos,
    required int priceLak,
    required String title,
    required String location,
    required int beds,
    required int baths,
    required int areaSqm,
    required String description,
    double? lat,
    double? lng,
  }) async {
    await _client
        .from('properties')
        .update({
          'image_url': imageUrl,
          'photos': photos,
          'price_lak': priceLak,
          'title': title,
          'location': location,
          'beds': beds,
          'baths': baths,
          'area_sqm': areaSqm,
          'description': description,
          'status': 'pending',
          'lat': ?lat,
          'lng': ?lng,
        })
        .eq('id', id);
  }

  static Future<void> delete(String id) async {
    await _client.from('properties').delete().eq('id', id);
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

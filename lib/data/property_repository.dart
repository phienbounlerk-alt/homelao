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
    bool? parking,
    bool? petFriendly,
  }) async {
    final trimmedQuery = query?.trim();
    final trimmedCategory = category?.trim();
    final trimmedLocation = location?.trim();

    var builder = _client.from('properties').select();
    if (trimmedQuery != null && trimmedQuery.isNotEmpty) {
      // Matched per word (not as one whole phrase) — a cleaned-up natural-
      // language query like "ຫ້ອງ ມະຫາວິທະຍາໄລ" would never appear
      // verbatim in a listing's title/location/description, but each word
      // individually is a real, useful match against them.
      final words = trimmedQuery
          .split(RegExp(r'\s+'))
          .map((w) => w.replaceAll(',', ' ').replaceAll('%', ' ').trim())
          .where((w) => w.isNotEmpty);
      final clauses = [
        for (final w in words) ...[
          'title.ilike.%$w%',
          'location.ilike.%$w%',
          'description.ilike.%$w%',
        ],
      ];
      if (clauses.isNotEmpty) builder = builder.or(clauses.join(','));
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
    if (parking == true) builder = builder.eq('parking', true);
    if (petFriendly == true) builder = builder.eq('pet_friendly', true);

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

  /// Listings whose lat/lng fall inside a map viewport ("search this area"),
  /// honoring the same filters as [fetchPage]. A bounding box is just a
  /// range comparison — no RPC needed like [fetchNear]'s Haversine math —
  /// and Postgres treats `NULL >= x` as false, so ungeotagged rows are
  /// excluded automatically by the lat/lng comparisons below.
  static Future<List<Property>> fetchInBounds({
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
    String? query,
    String? category,
    double? minPrice,
    double? maxPrice,
    int? minBeds,
    bool? parking,
    bool? petFriendly,
    int limit = 200,
  }) async {
    final trimmedQuery = query?.trim();
    final trimmedCategory = category?.trim();

    var builder = _client.from('properties').select();
    if (trimmedQuery != null && trimmedQuery.isNotEmpty) {
      final words = trimmedQuery
          .split(RegExp(r'\s+'))
          .map((w) => w.replaceAll(',', ' ').replaceAll('%', ' ').trim())
          .where((w) => w.isNotEmpty);
      final clauses = [
        for (final w in words) ...[
          'title.ilike.%$w%',
          'location.ilike.%$w%',
          'description.ilike.%$w%',
        ],
      ];
      if (clauses.isNotEmpty) builder = builder.or(clauses.join(','));
    }
    if (trimmedCategory != null && trimmedCategory.isNotEmpty) {
      builder = builder.ilike('title', '%$trimmedCategory%');
    }
    if (minPrice != null) builder = builder.gte('price_lak', minPrice);
    if (maxPrice != null) builder = builder.lte('price_lak', maxPrice);
    if (minBeds != null) builder = builder.gte('beds', minBeds);
    if (parking == true) builder = builder.eq('parking', true);
    if (petFriendly == true) builder = builder.eq('pet_friendly', true);

    final rows = await builder
        .gte('lat', swLat)
        .lte('lat', neLat)
        .gte('lng', swLng)
        .lte('lng', neLng)
        .order('featured', ascending: false)
        .limit(limit);
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
        .gt('featured_until', DateTime.now().toUtc().toIso8601String())
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
  /// Distinct districts (the part before the first comma in each
  /// listing's location string), computed and de-duplicated server-side
  /// via a small RPC rather than fetching every row's location column —
  /// the result set stays small regardless of how many listings exist.
  static Future<List<String>> fetchLocations() async {
    final rows = await _client.rpc('distinct_property_districts') as List;
    return rows
        .map((row) => (row as Map<String, dynamic>)['district'] as String)
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
    bool parking = false,
    bool petFriendly = false,
    String? phoneNumber,
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
          'parking': parking,
          'pet_friendly': petFriendly,
          'phone_number': phoneNumber,
          'lat': ?lat,
          'lng': ?lng,
        })
        .eq('id', id);
  }

  /// Other listings that resemble [property] — same district, a similar
  /// price (±20%), or the same bed count. Not a learned/ML similarity —
  /// just an honest heuristic over columns that already exist, ranked by
  /// rating since there's no relevance score to sort by.
  static Future<List<Property>> fetchSimilar(
    Property property, {
    int limit = 6,
  }) async {
    final district = property.location.split(',').first.trim();
    final minPrice = (property.priceLak * 0.8).round();
    final maxPrice = (property.priceLak * 1.2).round();
    final rows = await _client
        .from('properties')
        .select()
        .neq('id', property.id)
        .or(
          'location.ilike.$district%,'
          'and(price_lak.gte.$minPrice,price_lak.lte.$maxPrice),'
          'beds.eq.${property.beds}',
        )
        .order('rating', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((row) => Property.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  static Future<void> delete(String id) async {
    await _client.from('properties').delete().eq('id', id);
  }

  /// Owner-only occupancy toggle — goes through a dedicated RPC rather than
  /// a plain update because the general owner-update RLS policy forces
  /// `status`/`verified` back into moderation on every write, which is
  /// wrong for a lightweight status flip like this one.
  static Future<void> setRented(String id, bool isRented) async {
    await _client.rpc(
      'toggle_property_rented',
      params: {'p_property_id': id, 'p_is_rented': isRented},
    );
  }

  /// Resets the listing's expiry to 90 days from now. Returns the new
  /// expiry so the caller can update its local state without refetching.
  static Future<DateTime> renew(String id) async {
    final result = await _client.rpc(
      'renew_property_listing',
      params: {'p_property_id': id},
    );
    return DateTime.parse(result as String);
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

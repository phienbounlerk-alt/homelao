import 'dart:convert';

import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import '../models/poi.dart';

/// Thrown when the caller asks for POIs over too wide an area — Overpass's
/// free public instance asks integrators to keep queries reasonably scoped,
/// so this is enforced before a request is ever sent, not just documented.
class OverpassAreaTooLarge implements Exception {}

/// Nearby-places lookups against the free, keyless OpenStreetMap Overpass
/// API — the same data source backing the map's OSM tiles, so no separate
/// account or billing is needed for "nearby schools/hospitals/..." either.
class OverpassRepository {
  OverpassRepository._();

  static const _endpoint = 'https://overpass-api.de/api/interpreter';

  /// A single bounding-box side beyond this is almost certainly a zoomed-
  /// out view of an entire city or region — exactly what Overpass's usage
  /// guidelines ask callers not to query broadly, and what would return an
  /// unhelpfully huge, slow result anyway.
  static const _maxSpanDegrees = 0.15;

  /// Per-session cache keyed by category + a rounded bounding box, so
  /// toggling a category off and back on (or re-settling on nearly the same
  /// viewport) doesn't re-hit the public endpoint for the same answer.
  static final _cache = <String, List<Poi>>{};

  static Future<List<Poi>> fetchNearby({
    required PoiCategory category,
    required LatLngBounds bounds,
  }) async {
    if (bounds.north - bounds.south > _maxSpanDegrees ||
        bounds.east - bounds.west > _maxSpanDegrees) {
      throw OverpassAreaTooLarge();
    }

    final key = _cacheKey(category, bounds);
    final cached = _cache[key];
    if (cached != null) return cached;

    final bbox = '${bounds.south},${bounds.west},${bounds.north},${bounds.east}';
    final fragment = category.overpassFragment.replaceAll('{{bbox}}', bbox);
    final query = '[out:json][timeout:25];($fragment);out center 60;';

    final response = await http
        .post(Uri.parse(_endpoint), body: {'data': query})
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception('Overpass request failed: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = (decoded['elements'] as List).cast<Map<String, dynamic>>();
    final pois = elements
        .map((e) {
          final center = e['center'] as Map<String, dynamic>?;
          final lat = (e['lat'] as num?) ?? (center?['lat'] as num?);
          final lng = (e['lon'] as num?) ?? (center?['lon'] as num?);
          if (lat == null || lng == null) return null;
          final tags = e['tags'] as Map<String, dynamic>? ?? const {};
          return Poi(
            id: '${e['type']}/${e['id']}',
            name: (tags['name'] as String?) ?? category.label,
            lat: lat.toDouble(),
            lng: lng.toDouble(),
            category: category,
          );
        })
        .whereType<Poi>()
        .toList();

    _cache[key] = pois;
    return pois;
  }

  static String _cacheKey(PoiCategory category, LatLngBounds bounds) {
    String round(double v) => v.toStringAsFixed(3);
    return '${category.name}:${round(bounds.south)},${round(bounds.west)},'
        '${round(bounds.north)},${round(bounds.east)}';
  }
}

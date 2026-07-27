import 'package:flutter/material.dart';

/// Nearby point-of-interest categories sourced from OpenStreetMap via the
/// Overpass API — same free, keyless stack as the map tiles themselves.
/// Each category carries its own Overpass QL fragment (with `{{bbox}}`
/// substituted for `south,west,north,east`) and its own marker color/icon
/// so multiple categories stay visually distinct if toggled one after
/// another.
enum PoiCategory {
  school(
    label: 'ໂຮງຮຽນ',
    icon: Icons.school_rounded,
    color: Color(0xFF3F51B5),
    overpassFragment: 'node["amenity"="school"]({{bbox}});'
        'way["amenity"="school"]({{bbox}});',
  ),
  hospital(
    label: 'ໂຮງໝໍ',
    icon: Icons.local_hospital_rounded,
    color: Color(0xFFE53935),
    overpassFragment: 'node["amenity"~"hospital|clinic"]({{bbox}});'
        'way["amenity"~"hospital|clinic"]({{bbox}});',
  ),
  market(
    label: 'ຕະຫຼາດ',
    icon: Icons.storefront_rounded,
    color: Color(0xFFFB8C00),
    overpassFragment: 'node["shop"="supermarket"]({{bbox}});'
        'way["shop"="supermarket"]({{bbox}});'
        'node["amenity"="marketplace"]({{bbox}});'
        'way["amenity"="marketplace"]({{bbox}});',
  ),
  restaurant(
    label: 'ຮ້ານອາຫານ',
    icon: Icons.restaurant_rounded,
    color: Color(0xFFD84315),
    overpassFragment: 'node["amenity"="restaurant"]({{bbox}});'
        'way["amenity"="restaurant"]({{bbox}});',
  ),
  bank(
    label: 'ທະນາຄານ',
    icon: Icons.account_balance_rounded,
    color: Color(0xFF00897B),
    overpassFragment: 'node["amenity"="bank"]({{bbox}});'
        'way["amenity"="bank"]({{bbox}});',
  ),
  busStation(
    label: 'ສະຖານີລົດເມ',
    icon: Icons.directions_bus_rounded,
    color: Color(0xFF546E7A),
    overpassFragment: 'node["amenity"="bus_station"]({{bbox}});'
        'way["amenity"="bus_station"]({{bbox}});'
        'node["highway"="bus_stop"]({{bbox}});',
  );

  const PoiCategory({
    required this.label,
    required this.icon,
    required this.color,
    required this.overpassFragment,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String overpassFragment;
}

/// A single nearby place returned by Overpass.
class Poi {
  const Poi({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.category,
  });

  final String id;
  final String name;
  final double lat;
  final double lng;
  final PoiCategory category;
}

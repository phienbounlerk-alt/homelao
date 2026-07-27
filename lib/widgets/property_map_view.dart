import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../data/geolocation.dart';
import '../data/property_repository.dart';
import '../models/property.dart';
import '../screens/property_detail_screen.dart';
import '../theme/app_theme.dart';
import 'filter_sheet.dart';

/// Vientiane — the default center when there's no "near me" origin and no
/// geotagged results to frame yet.
const _defaultCenter = LatLng(17.9757, 102.6331);

/// Airbnb-style browsable map: price-pin markers (clustered), current-
/// location, and results that refresh as the viewport settles after a pan
/// or zoom ("search this area" / live filtering), honoring the same filters
/// as the list view.
class PropertyMapView extends StatefulWidget {
  const PropertyMapView({
    super.key,
    required this.filters,
    this.query,
    this.category,
    this.initialCenter,
  });

  final SearchFilters filters;
  final String? query;
  final String? category;
  final LatLng? initialCenter;

  @override
  State<PropertyMapView> createState() => _PropertyMapViewState();
}

class _PropertyMapViewState extends State<PropertyMapView> {
  final _mapController = MapController();
  Timer? _debounce;

  List<Property> _markers = [];
  bool _loading = true;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchForBounds(_mapController.camera.visibleBounds);
    });
  }

  @override
  void didUpdateWidget(PropertyMapView old) {
    super.didUpdateWidget(old);
    // Filters/query/category changed from outside (e.g. the filter sheet) —
    // re-run against whatever the map is already showing, without waiting
    // for the user to pan.
    if (old.filters != widget.filters ||
        old.query != widget.query ||
        old.category != widget.category) {
      _fetchForBounds(_mapController.camera.visibleBounds);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchForBounds(LatLngBounds bounds) async {
    setState(() => _loading = true);
    try {
      final results = await PropertyRepository.fetchInBounds(
        swLat: bounds.south,
        swLng: bounds.west,
        neLat: bounds.north,
        neLng: bounds.east,
        query: widget.query,
        category: widget.category,
        minPrice: widget.filters.priceRange.start,
        maxPrice: widget.filters.priceRange.end,
        minBeds: widget.filters.minBeds,
        parking: widget.filters.parking ? true : null,
        petFriendly: widget.filters.petFriendly ? true : null,
      );
      if (!mounted) return;
      setState(() {
        _markers = results;
        _loading = false;
      });
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (!hasGesture) return;
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 600),
      () => _fetchForBounds(camera.visibleBounds),
    );
  }

  Future<void> _goToCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final (lat, lng) = await currentLatLng();
      if (!mounted) return;
      _mapController.move(LatLng(lat, lng), 15);
      setState(() => _locating = false);
      await _fetchForBounds(_mapController.camera.visibleBounds);
    } on GeolocationDenied {
      if (!mounted) return;
      setState(() => _locating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ກະລຸນາອະນຸຍາດການເຂົ້າເຖິງຕຳແໜ່ງ'),
        ),
      );
    } on GeolocationUnavailable {
      if (!mounted) return;
      setState(() => _locating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ກະລຸນາເປີດການບໍລິການຕຳແໜ່ງຂອງອຸປະກອນ')),
      );
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      setState(() => _locating = false);
    }
  }

  void _openProperty(Property property) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => PropertyDetailScreen(property: property)));
  }

  @override
  Widget build(BuildContext context) {
    final center = widget.initialCenter ?? _defaultCenter;
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: widget.initialCenter != null ? 14 : 12,
            onPositionChanged: _onPositionChanged,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'la.homelao.app',
            ),
            MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                maxClusterRadius: 60,
                size: const Size(40, 40),
                zoomToBoundsOnClick: true,
                markers: [
                  for (final property in _markers)
                    Marker(
                      point: LatLng(property.lat!, property.lng!),
                      width: 84,
                      height: 36,
                      alignment: Alignment.center,
                      child: _PricePin(
                        property: property,
                        onTap: () => _openProperty(property),
                      ),
                    ),
                ],
                builder: (context, markers) => _ClusterBubble(count: markers.length),
              ),
            ),
          ],
        ),
        Positioned(
          left: 12,
          right: 12,
          top: 12,
          child: IgnorePointer(
            ignoring: true,
            child: AnimatedOpacity(
              opacity: _loading ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ກຳລັງຄົ້ນຫາພື້ນທີ່ນີ້...',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 12,
          bottom: 24,
          child: Material(
            color: AppColors.surface,
            shape: const CircleBorder(),
            elevation: 3,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _locating ? null : _goToCurrentLocation,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _locating
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryGreen,
                        ),
                      )
                    : Tooltip(
                        message: 'ຕຳແໜ່ງປັດຈຸບັນ',
                        child: Icon(
                          Icons.my_location_rounded,
                          color: AppColors.primaryGreen,
                          size: 20,
                        ),
                      ),
              ),
            ),
          ),
        ),
        if (!_loading)
          Positioned(
            left: 12,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Text(
                _markers.isEmpty
                    ? 'ບໍ່ພົບຊັບສິນໃນພື້ນທີ່ນີ້'
                    : 'ພົບ ${_markers.length} ຊັບສິນ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PricePin extends StatelessWidget {
  const _PricePin({required this.property, required this.onTap});

  final Property property;
  final VoidCallback onTap;

  String get _compactPrice {
    final price = property.priceLak;
    if (price >= 1000000) {
      final millions = price / 1000000;
      return '${millions % 1 == 0 ? millions.toStringAsFixed(0) : millions.toStringAsFixed(1)}ລ້ານ';
    }
    if (price >= 1000) return '${(price / 1000).round()}ພັນ';
    return '$price';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.primaryGreen, width: 1.4),
          ),
          child: Text(
            _compactPrice,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryGreen,
            ),
          ),
        ),
      ),
    );
  }
}

class _ClusterBubble extends StatelessWidget {
  const _ClusterBubble({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

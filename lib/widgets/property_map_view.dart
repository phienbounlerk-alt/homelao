import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/geolocation.dart';
import '../data/overpass_repository.dart';
import '../data/property_repository.dart';
import '../models/poi.dart';
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
  Property? _selected;

  PoiCategory? _activePoi;
  List<Poi> _pois = [];
  bool _loadingPois = false;

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
    // The selected pin may pan off-screen — drop the preview rather than
    // leave it pointing at a marker the user can no longer see.
    if (_selected != null) setState(() => _selected = null);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      _fetchForBounds(camera.visibleBounds);
      if (_activePoi != null) _fetchPois(camera.visibleBounds);
    });
  }

  Future<void> _fetchPois(LatLngBounds bounds) async {
    final category = _activePoi;
    if (category == null) return;
    setState(() => _loadingPois = true);
    try {
      final results = await OverpassRepository.fetchNearby(
        category: category,
        bounds: bounds,
      );
      if (!mounted || _activePoi != category) return;
      setState(() {
        _pois = results;
        _loadingPois = false;
      });
    } on OverpassAreaTooLarge {
      if (!mounted) return;
      setState(() => _loadingPois = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ກະລຸນາຊູມເຂົ້າໃກ້ຂຶ້ນເພື່ອຄົ້ນຫາສະຖານທີ່ໃກ້ຄຽງ')),
      );
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      setState(() => _loadingPois = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ຄົ້ນຫາສະຖານທີ່ໃກ້ຄຽງບໍ່ສຳເລັດ — ກະລຸນາລອງໃໝ່')),
      );
    }
  }

  void _togglePoi(PoiCategory category) {
    if (_activePoi == category) {
      setState(() {
        _activePoi = null;
        _pois = [];
      });
      return;
    }
    setState(() {
      _activePoi = category;
      _pois = [];
    });
    _fetchPois(_mapController.camera.visibleBounds);
  }

  Future<void> _goToCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final (lat, lng) = await currentLatLng();
      if (!mounted) return;
      _mapController.move(LatLng(lat, lng), 15);
      setState(() => _locating = false);
      await _fetchForBounds(_mapController.camera.visibleBounds);
      if (_activePoi != null) await _fetchPois(_mapController.camera.visibleBounds);
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

  Future<void> _openDirections(Property property) async {
    // A universal Google Maps deep link — resolves to whatever maps app the
    // user already has, no API key or billing needed since this just opens
    // a URL rather than calling any Maps API.
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${property.lat},${property.lng}',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ເປີດແຜນທີ່ນຳທາງບໍ່ສຳເລັດ — ກະລຸນາລອງໃໝ່')),
      );
    }
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
                        selected: _selected?.id == property.id,
                        onTap: () => setState(() => _selected = property),
                      ),
                    ),
                ],
                builder: (context, markers) => _ClusterBubble(count: markers.length),
              ),
            ),
            MarkerLayer(
              markers: [
                for (final poi in _pois)
                  Marker(
                    point: LatLng(poi.lat, poi.lng),
                    width: 30,
                    height: 30,
                    child: _PoiMarker(poi: poi),
                  ),
              ],
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 12,
          child: SizedBox(
            height: 34,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemCount: PoiCategory.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final category = PoiCategory.values[i];
                final active = _activePoi == category;
                return Material(
                  color: active ? category.color : AppColors.surface,
                  borderRadius: BorderRadius.circular(17),
                  elevation: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(17),
                    onTap: () => _togglePoi(category),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            category.icon,
                            size: 14,
                            color: active ? Colors.white : category.color,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            category.label,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: active
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          top: 54,
          child: IgnorePointer(
            ignoring: true,
            child: AnimatedOpacity(
              opacity: (_loading || _loadingPois) ? 1 : 0,
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
                        _loadingPois
                            ? 'ກຳລັງຄົ້ນຫາສະຖານທີ່ໃກ້ຄຽງ...'
                            : 'ກຳລັງຄົ້ນຫາພື້ນທີ່ນີ້...',
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
        if (!_loading && _selected == null)
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
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) => SlideTransition(
              position: Tween(begin: const Offset(0, 0.3), end: Offset.zero)
                  .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: _selected == null
                ? const SizedBox.shrink()
                : _PropertyPreviewCard(
                    key: ValueKey(_selected!.id),
                    property: _selected!,
                    onClose: () => setState(() => _selected = null),
                    onViewDetails: () => _openProperty(_selected!),
                    onDirections: () => _openDirections(_selected!),
                  ),
          ),
        ),
      ],
    );
  }
}

class _PricePin extends StatelessWidget {
  const _PricePin({
    required this.property,
    required this.onTap,
    this.selected = false,
  });

  final Property property;
  final VoidCallback onTap;
  final bool selected;

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
      color: selected ? AppColors.primaryGreen : AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      elevation: selected ? 4 : 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
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
              color: selected ? Colors.white : AppColors.primaryGreen,
            ),
          ),
        ),
      ),
    );
  }
}

class _PropertyPreviewCard extends StatelessWidget {
  const _PropertyPreviewCard({
    super.key,
    required this.property,
    required this.onClose,
    required this.onViewDetails,
    required this.onDirections,
  });

  final Property property;
  final VoidCallback onClose;
  final VoidCallback onViewDetails;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 6,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onViewDetails,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      property.imageUrl,
                      width: 76,
                      height: 76,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          width: 76,
                          height: 76,
                          color: AppColors.surfaceAlt,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${property.formattedPrice} ກີບ/ເດືອນ',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          property.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          property.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.bed_outlined,
                              size: 13,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${property.beds}',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.bathtub_outlined,
                              size: 13,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${property.baths}',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.star,
                              size: 13,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${property.rating}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: onClose,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDirections,
                      icon: Icon(
                        Icons.directions_rounded,
                        size: 16,
                        color: AppColors.primaryGreen,
                      ),
                      label: Text(
                        'ນຳທາງ',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.primaryGreen),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onViewDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'ລາຍລະອຽດ',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PoiMarker extends StatelessWidget {
  const _PoiMarker({required this.poi});

  final Poi poi;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: poi.name,
      child: Container(
        decoration: BoxDecoration(
          color: poi.category.color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(poi.category.icon, size: 14, color: Colors.white),
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

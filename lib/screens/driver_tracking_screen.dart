import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/driver_repository.dart';
import '../models/driver.dart';
import '../theme/app_theme.dart';
import '../widgets/error_state.dart';

class DriverTrackingScreen extends StatefulWidget {
  const DriverTrackingScreen({super.key, required this.driverId});

  final String driverId;

  @override
  State<DriverTrackingScreen> createState() => _DriverTrackingScreenState();
}

class _DriverTrackingScreenState extends State<DriverTrackingScreen> {
  final _mapController = MapController();
  late Stream<Driver?> _driverStream = DriverRepository.streamDriver(
    widget.driverId,
  );
  bool _centeredOnce = false;

  void _retry() {
    setState(() {
      _driverStream = DriverRepository.streamDriver(widget.driverId);
    });
  }

  // Purely to refresh the "updated N seconds ago" label between location
  // pushes — the map itself only moves when a new StreamBuilder snapshot
  // actually carries a new position.
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _tickTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  String _freshness(DateTime updatedAt) {
    final seconds = DateTime.now().difference(updatedAt).inSeconds;
    if (seconds < 60) return 'ອັບເດດ $seconds ວິນາທີກ່ອນ';
    final minutes = seconds ~/ 60;
    return 'ອັບເດດ $minutes ນາທີກ່ອນ';
  }

  Future<void> _callDriver(String phone) async {
    try {
      await launchUrl(Uri(scheme: 'tel', path: phone));
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ໂທອອກບໍ່ສຳເລັດ — ກະລຸນາລອງໃໝ່')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 12),
              child: Row(
                children: [
                  Material(
                    color: AppColors.surface,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).pop(),
                      child: Tooltip(
                        message: 'ກັບຄືນ',
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'ຕິດຕາມການຂົນສົ່ງ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<Driver?>(
                stream: _driverStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return ErrorState(onRetry: _retry);
                  }
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryGreen,
                      ),
                    );
                  }
                  final driver = snapshot.data;
                  final lat = driver?.currentLat;
                  final lng = driver?.currentLng;
                  final updatedAt = driver?.locationUpdatedAt;
                  if (driver == null || lat == null || lng == null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_searching_rounded,
                              size: 48,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'ຄົນຂັບຍັງບໍ່ໄດ້ແບ່ງປັນຕຳແໜ່ງ',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'ຕຳແໜ່ງຈະສະແດງທັນທີທີ່ຄົນຂັບເປີດໜ້າ "ວຽກຂອງຂ້ອຍ" ຄ້າງໄວ້.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final point = LatLng(lat, lng);
                  if (!_centeredOnce) {
                    _centeredOnce = true;
                  } else {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _mapController.move(point, _mapController.camera.zoom);
                    });
                  }

                  return Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: point,
                          initialZoom: 15,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'la.homelao.app',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: point,
                                width: 44,
                                height: 44,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGreen,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.25,
                                        ),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.local_shipping_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.local_shipping_rounded,
                                size: 16,
                                color: AppColors.primaryGreen,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${driver.driverName} — ${driver.vehiclePlate}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (updatedAt != null)
                                      Text(
                                        _freshness(updatedAt),
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Material(
                                color: AppColors.secondaryGreen,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: () => _callDriver(driver.phone),
                                  child: Tooltip(
                                    message: 'ໂທຫາຄົນຂັບ',
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Icon(
                                        Icons.call_rounded,
                                        size: 16,
                                        color: AppColors.primaryGreen,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '© OpenStreetMap contributors',
                            style: TextStyle(fontSize: 8, color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

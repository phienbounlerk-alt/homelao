import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../data/geolocation.dart';
import '../theme/app_theme.dart';

/// Vientiane — the default center when the poster has no saved location and
/// declines the GPS prompt.
const _defaultCenter = LatLng(17.9757, 102.6331);

/// Airbnb/Uber-style "drag the map, pin stays centered" location picker.
/// Returns the confirmed (lat, lng), or null if dismissed without choosing.
Future<(double, double)?> showLocationPicker(
  BuildContext context, {
  double? initialLat,
  double? initialLng,
}) {
  return showModalBottomSheet<(double, double)>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.88,
      child: _LocationPickerSheet(initialLat: initialLat, initialLng: initialLng),
    ),
  );
}

class _LocationPickerSheet extends StatefulWidget {
  const _LocationPickerSheet({this.initialLat, this.initialLng});

  final double? initialLat;
  final double? initialLng;

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  final _mapController = MapController();
  bool _locating = false;

  Future<void> _goToCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final (lat, lng) = await currentLatLng();
      if (!mounted) return;
      _mapController.move(LatLng(lat, lng), 16);
      setState(() => _locating = false);
    } on GeolocationDenied {
      if (!mounted) return;
      setState(() => _locating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ກະລຸນາອະນຸຍາດການເຂົ້າເຖິງຕຳແໜ່ງ')),
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

  void _confirm() {
    final center = _mapController.camera.center;
    Navigator.of(context).pop((center.latitude, center.longitude));
  }

  @override
  Widget build(BuildContext context) {
    final center = widget.initialLat != null && widget.initialLng != null
        ? LatLng(widget.initialLat!, widget.initialLng!)
        : _defaultCenter;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        color: AppColors.background,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'ປັກໝາຍຕຳແໜ່ງເທິງແຜນທີ່',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).pop(),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          Icons.close_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Text(
                'ລາກແຜນທີ່ເພື່ອຍ້າຍໝາຍໄປບ່ອນທີ່ຊັບສິນຕັ້ງຢູ່',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(initialCenter: center, initialZoom: 15),
                    children: [
                      ValueListenableBuilder<ThemeMode>(
                        valueListenable: ThemeController.instance,
                        builder: (context, mode, _) {
                          final isDark = ThemeController.instance.isDark;
                          return TileLayer(
                            urlTemplate: isDark
                                ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                                : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            subdomains: isDark
                                ? const ['a', 'b', 'c', 'd']
                                : const [],
                            userAgentPackageName: 'la.homelao.app',
                          );
                        },
                      ),
                    ],
                  ),
                  // The pin stays fixed at screen-center while the map moves
                  // underneath it — its tip (not its center) marks the
                  // chosen point, hence the bottom padding offset.
                  IgnorePointer(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 36),
                        child: Icon(
                          Icons.location_on_rounded,
                          size: 44,
                          color: AppColors.primaryGreen,
                          shadows: const [
                            Shadow(color: Colors.black38, blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
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
                              : Icon(
                                  Icons.my_location_rounded,
                                  color: AppColors.primaryGreen,
                                  size: 20,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Material(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _confirm,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Center(
                      child: Text(
                        'ຢືນຢັນຕຳແໜ່ງນີ້',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

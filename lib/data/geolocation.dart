import 'package:geolocator/geolocator.dart';

class GeolocationDenied implements Exception {}

class GeolocationUnavailable implements Exception {}

/// Prompts the browser's location permission (if needed) and returns the
/// user's current position. Throws [GeolocationDenied] if the user refuses,
/// [GeolocationUnavailable] if location services are off.
Future<(double lat, double lng)> currentLatLng() async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) throw GeolocationUnavailable();

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw GeolocationDenied();
  }

  final position = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.medium,
    ),
  );
  return (position.latitude, position.longitude);
}

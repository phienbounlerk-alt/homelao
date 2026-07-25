class Driver {
  const Driver({
    required this.id,
    required this.userId,
    required this.driverName,
    required this.phone,
    required this.vehicleType,
    required this.vehiclePlate,
    this.vehiclePhotoUrl,
    this.status = 'pending',
    this.currentLat,
    this.currentLng,
    this.locationUpdatedAt,
  });

  factory Driver.fromMap(Map<String, dynamic> map) => Driver(
    id: map['id'] as String,
    userId: map['user_id'] as String,
    driverName: map['driver_name'] as String,
    phone: map['phone'] as String,
    vehicleType: map['vehicle_type'] as String,
    vehiclePlate: map['vehicle_plate'] as String,
    vehiclePhotoUrl: map['vehicle_photo_url'] as String?,
    status: map['status'] as String? ?? 'pending',
    currentLat: (map['current_lat'] as num?)?.toDouble(),
    currentLng: (map['current_lng'] as num?)?.toDouble(),
    locationUpdatedAt: map['location_updated_at'] != null
        ? DateTime.parse(map['location_updated_at'] as String)
        : null,
  );

  final String id;
  final String userId;
  final String driverName;
  final String phone;
  final String vehicleType;
  final String vehiclePlate;
  final String? vehiclePhotoUrl;

  /// 'pending' | 'approved' | 'rejected' — admin-moderated, same as listings.
  final String status;

  /// Last GPS fix pushed while a job was active — null until the driver's
  /// first location update, since sharing only happens with an active job
  /// and the app open in the foreground.
  final double? currentLat;
  final double? currentLng;
  final DateTime? locationUpdatedAt;
}

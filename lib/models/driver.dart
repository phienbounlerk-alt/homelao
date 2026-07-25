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
}

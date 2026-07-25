class MovingRequest {
  const MovingRequest({
    required this.id,
    required this.customerId,
    this.driverId,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.vehicleType,
    required this.preferredDate,
    this.notes = '',
    this.status = 'pending',
  });

  factory MovingRequest.fromMap(Map<String, dynamic> map) => MovingRequest(
    id: map['id'] as String,
    customerId: map['customer_id'] as String,
    driverId: map['driver_id'] as String?,
    pickupLocation: map['pickup_location'] as String,
    dropoffLocation: map['dropoff_location'] as String,
    vehicleType: map['vehicle_type'] as String,
    preferredDate: DateTime.parse(map['preferred_date'] as String),
    notes: map['notes'] as String? ?? '',
    status: map['status'] as String? ?? 'pending',
  );

  final String id;
  final String customerId;
  final String? driverId;
  final String pickupLocation;
  final String dropoffLocation;
  final String vehicleType;
  final DateTime preferredDate;
  final String notes;

  /// 'pending' | 'accepted' | 'in_progress' | 'completed' | 'cancelled'.
  final String status;
}

import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_repository.dart';
import '../models/driver.dart';
import '../models/moving_request.dart';

class DriverRepository {
  DriverRepository._();

  static SupabaseClient get _client => Supabase.instance.client;

  /// The current user's own driver profile, regardless of approval status —
  /// null if they've never registered.
  static Future<Driver?> fetchMine() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    final row = await _client
        .from('drivers')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return null;
    return Driver.fromMap(row);
  }

  static Future<void> register({
    required String driverName,
    required String phone,
    required String vehicleType,
    required String vehiclePlate,
    String? vehiclePhotoUrl,
  }) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('drivers').insert({
      'user_id': userId,
      'driver_name': driverName,
      'phone': phone,
      'vehicle_type': vehicleType,
      'vehicle_plate': vehiclePlate,
      'vehicle_photo_url': vehiclePhotoUrl,
    });
  }

  static Future<Driver?> fetchById(String id) async {
    final row = await _client
        .from('drivers')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return Driver.fromMap(row);
  }

  /// Open jobs any approved driver can claim.
  static Future<List<MovingRequest>> fetchPendingForDrivers() async {
    final rows = await _client
        .from('moving_requests')
        .select()
        .eq('status', 'pending')
        .order('created_at');
    return (rows as List)
        .map((row) => MovingRequest.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Jobs assigned to the current user's driver profile, newest first.
  static Future<List<MovingRequest>> fetchMyJobs() async {
    final driver = await fetchMine();
    if (driver == null) return [];
    final rows = await _client
        .from('moving_requests')
        .select()
        .eq('driver_id', driver.id)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((row) => MovingRequest.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  static Future<void> acceptRequest(MovingRequest request) async {
    final driver = await fetchMine();
    if (driver == null) throw StateError('not a registered driver');
    await _client
        .from('moving_requests')
        .update({
          'driver_id': driver.id,
          'status': 'accepted',
          'accepted_at': DateTime.now().toIso8601String(),
        })
        .eq('id', request.id);
    await NotificationRepository.notify(
      userId: request.customerId,
      title: 'ຄົນຂັບຮັບຄຳຮ້ອງແລ້ວ',
      body: '${driver.driverName} (${driver.vehiclePlate}) ຮັບຄຳຮ້ອງຂົນສົ່ງຂອງທ່ານແລ້ວ',
      type: 'moving_accepted',
    );
  }

  static Future<void> updateStatus(
    MovingRequest request,
    String status,
  ) async {
    await _client
        .from('moving_requests')
        .update({
          'status': status,
          if (status == 'completed')
            'completed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', request.id);
    await NotificationRepository.notify(
      userId: request.customerId,
      title: status == 'completed'
          ? 'ຂົນສົ່ງສຳເລັດແລ້ວ'
          : 'ຄົນຂັບກຳລັງດຳເນີນການຂົນສົ່ງ',
      body: status == 'completed'
          ? 'ການຂົນສົ່ງຂອງທ່ານສຳເລັດແລ້ວ ຂອບໃຈທີ່ໃຊ້ບໍລິການ'
          : 'ຄົນຂັບອອກເດີນທາງໄປຮັບເຄື່ອງຂອງທ່ານແລ້ວ',
      type: 'moving_$status',
    );
  }

  static Future<void> submitRequest({
    required String pickupLocation,
    required String dropoffLocation,
    required String vehicleType,
    required DateTime preferredDate,
    String notes = '',
  }) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('moving_requests').insert({
      'customer_id': userId,
      'pickup_location': pickupLocation,
      'dropoff_location': dropoffLocation,
      'vehicle_type': vehicleType,
      'preferred_date':
          '${preferredDate.year.toString().padLeft(4, '0')}-'
          '${preferredDate.month.toString().padLeft(2, '0')}-'
          '${preferredDate.day.toString().padLeft(2, '0')}',
      'notes': notes,
    });
  }

  /// Live-updating list of the current user's own moving requests.
  ///
  /// Deduped by id — a freshly-inserted row can otherwise arrive twice in
  /// one snapshot when the stream's initial fetch races its own realtime
  /// INSERT event.
  static Stream<List<MovingRequest>> streamMyRequests() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.value(const []);
    return _client
        .from('moving_requests')
        .stream(primaryKey: ['id'])
        .eq('customer_id', userId)
        .order('created_at', ascending: false)
        .map((rows) {
          final seen = <String>{};
          final result = <MovingRequest>[];
          for (final row in rows) {
            final request = MovingRequest.fromMap(row);
            if (seen.add(request.id)) result.add(request);
          }
          return result;
        });
  }

  static Future<void> cancelRequest(MovingRequest request) async {
    await _client
        .from('moving_requests')
        .update({'status': 'cancelled'})
        .eq('id', request.id);
  }
}

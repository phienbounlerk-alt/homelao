import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_repository.dart';
import '../models/driver.dart';
import '../models/featured_request.dart';
import '../models/property.dart';

class AdminRepository {
  AdminRepository._();

  static SupabaseClient get _client => Supabase.instance.client;

  static Future<bool> isCurrentUserAdmin() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    final row = await _client
        .from('admins')
        .select('user_id')
        .eq('user_id', userId)
        .maybeSingle();
    return row != null;
  }

  static Future<List<Property>> fetchPendingProperties() async {
    final rows = await _client
        .from('properties')
        .select()
        .eq('status', 'pending')
        .order('created_at');
    return (rows as List)
        .map((row) => Property.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  static Future<void> setStatus(Property property, String status) async {
    await _client
        .from('properties')
        .update({'status': status})
        .eq('id', property.id);
    final ownerId = property.ownerId;
    if (ownerId == null) return;
    final approved = status == 'approved';
    await NotificationRepository.notify(
      userId: ownerId,
      title: approved ? 'ປະກາດຖືກອະນຸມັດແລ້ວ' : 'ປະກາດຖືກປະຕິເສດ',
      body: approved
          ? '"${property.title}" ອະນຸມັດແລ້ວ, ຄົນອື່ນເຫັນໄດ້ແລ້ວ.'
          : '"${property.title}" ຖືກປະຕິເສດ, ກະລຸນາກວດສອບຂໍ້ມູນອີກຄັ້ງ.',
      type: approved ? 'listing_approved' : 'listing_rejected',
      relatedPropertyId: property.id,
    );
  }

  static Future<List<FeaturedRequest>> fetchPendingFeatureRequests() async {
    final rows = await _client
        .from('featured_requests')
        .select('*, properties(title)')
        .eq('status', 'pending_review')
        .order('created_at');
    return (rows as List)
        .map((row) => FeaturedRequest.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Approving sets the request to confirmed and marks the property
  /// featured for [durationDays] from now; rejecting just closes the
  /// request out. These are two separate updates (no stored procedures in
  /// this schema) — if the second one fails after the first succeeds, the
  /// request is simply still reachable to retry from the pending list.
  static Future<void> reviewFeatureRequest({
    required FeaturedRequest request,
    required bool approve,
  }) async {
    await _client
        .from('featured_requests')
        .update({
          'status': approve ? 'confirmed' : 'rejected',
          // .toUtc() before serializing — a local DateTime's
          // toIso8601String() has no offset, which Postgres reads as UTC,
          // silently shifting the stored instant by the local UTC offset.
          'reviewed_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', request.id);
    if (approve) {
      final until = DateTime.now().add(Duration(days: request.durationDays));
      await _client
          .from('properties')
          .update({
            'featured': true,
            'featured_until': until.toUtc().toIso8601String(),
          })
          .eq('id', request.propertyId);
    }
    await NotificationRepository.notify(
      userId: request.ownerId,
      title: approve ? 'ຢືນຢັນການໂອນເງິນແລ້ວ' : 'ຄຳຮ້ອງເດັ່ນຖືກປະຕິເສດ',
      body: approve
          ? '"${request.propertyTitle}" ຂຶ້ນເດັ່ນແລ້ວ ${request.durationDays} ວັນ.'
          : 'ຄຳຮ້ອງເຮັດໃຫ້ "${request.propertyTitle}" ເດັ່ນຖືກປະຕິເສດ — ກະລຸນາກວດສອບຫຼັກຖານການໂອນ.',
      type: approve ? 'feature_confirmed' : 'feature_rejected',
      relatedPropertyId: request.propertyId,
    );
  }

  static Future<List<Driver>> fetchPendingDrivers() async {
    final rows = await _client
        .from('drivers')
        .select()
        .eq('status', 'pending')
        .order('created_at');
    return (rows as List)
        .map((row) => Driver.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  static Future<void> setDriverStatus(Driver driver, String status) async {
    await _client.from('drivers').update({'status': status}).eq(
      'id',
      driver.id,
    );
    final approved = status == 'approved';
    await NotificationRepository.notify(
      userId: driver.userId,
      title: approved ? 'ບັນຊີຄົນຂັບຖືກອະນຸມັດແລ້ວ' : 'ບັນຊີຄົນຂັບຖືກປະຕິເສດ',
      body: approved
          ? 'ຍິນດີດ້ວຍ! ທ່ານສາມາດຮັບວຽກຂົນສົ່ງໄດ້ແລ້ວ.'
          : 'ການສະໝັກເປັນຄົນຂັບຂອງທ່ານຖືກປະຕິເສດ — ກະລຸນາຕິດຕໍ່ທີມງານ.',
      type: approved ? 'driver_approved' : 'driver_rejected',
    );
  }
}

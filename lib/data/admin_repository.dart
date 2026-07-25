import 'package:supabase_flutter/supabase_flutter.dart';
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

  static Future<void> setStatus(String propertyId, String status) async {
    await _client
        .from('properties')
        .update({'status': status})
        .eq('id', propertyId);
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
          'reviewed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', request.id);
    if (approve) {
      final until = DateTime.now().add(Duration(days: request.durationDays));
      await _client
          .from('properties')
          .update({'featured': true, 'featured_until': until.toIso8601String()})
          .eq('id', request.propertyId);
    }
  }
}

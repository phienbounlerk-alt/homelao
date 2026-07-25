import 'package:supabase_flutter/supabase_flutter.dart';
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
}

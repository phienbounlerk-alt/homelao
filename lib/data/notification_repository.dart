import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_notification.dart';

class NotificationRepository {
  NotificationRepository._();

  static SupabaseClient get _client => Supabase.instance.client;

  /// Live-updating list of the current user's notifications, newest first.
  /// Emits immediately with the current rows, then again on every change —
  /// the same pattern already used for chat messages.
  static Stream<List<AppNotification>> streamMine() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.value(const []);
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map(
          (rows) => rows
              .map((row) => AppNotification.fromMap(row))
              .toList(growable: false),
        );
  }

  static Future<void> markRead(String id) async {
    await _client.from('notifications').update({'read': true}).eq('id', id);
  }

  static Future<void> markAllRead(List<String> ids) async {
    if (ids.isEmpty) return;
    await _client
        .from('notifications')
        .update({'read': true})
        .inFilter('id', ids);
  }

  /// Used by admin actions (listing/feature-request review) to notify the
  /// owner — insert is only permitted for admins, enforced by RLS.
  static Future<void> notify({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? relatedPropertyId,
  }) async {
    await _client.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'related_property_id': relatedPropertyId,
    });
  }
}

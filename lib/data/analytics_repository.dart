import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/property.dart';

class AnalyticsRepository {
  AnalyticsRepository._();

  static SupabaseClient get _client => Supabase.instance.client;

  /// Fire-and-forget event log — never awaited by callers, and a failure
  /// here only reaches Sentry, never the user, since analytics breaking
  /// shouldn't affect the feature the user is actually using.
  static void track(String eventType, [Map<String, dynamic>? metadata]) {
    _client
        .from('analytics_events')
        .insert({
          'user_id': _client.auth.currentUser?.id,
          'event_type': eventType,
          'metadata': metadata ?? {},
        })
        .catchError((Object e, StackTrace st) {
          Sentry.captureException(e, stackTrace: st);
        });
  }

  static Future<List<({DateTime day, int events, int users})>> dailyCounts({
    int daysBack = 14,
  }) async {
    final rows =
        await _client.rpc(
              'analytics_daily_counts',
              params: {'days_back': daysBack},
            )
            as List;
    return rows.map((row) {
      final map = row as Map<String, dynamic>;
      return (
        day: DateTime.parse(map['day'] as String),
        events: (map['event_count'] as num).toInt(),
        users: (map['distinct_users'] as num).toInt(),
      );
    }).toList();
  }

  /// Most-viewed properties in the window, paired with their view count and
  /// resolved via the properties table — rows for properties since deleted
  /// are silently skipped.
  static Future<List<(Property, int)>> topProperties({
    int daysBack = 7,
  }) async {
    final ranked =
        await _client.rpc(
              'analytics_top_properties',
              params: {'days_back': daysBack},
            )
            as List;
    if (ranked.isEmpty) return [];
    final viewsById = <String, int>{
      for (final row in ranked)
        (row as Map<String, dynamic>)['property_id'] as String:
            (row['view_count'] as num).toInt(),
    };
    final rows = await _client
        .from('properties')
        .select()
        .inFilter('id', viewsById.keys.toList());
    final properties = (rows as List)
        .map((row) => Property.fromMap(row as Map<String, dynamic>))
        .toList();
    final result = [
      for (final p in properties) (p, viewsById[p.id] ?? 0),
    ];
    result.sort((a, b) => b.$2.compareTo(a.$2));
    return result;
  }

  static Future<List<(String, int)>> topSearches({int daysBack = 7}) async {
    final rows =
        await _client.rpc(
              'analytics_top_searches',
              params: {'days_back': daysBack},
            )
            as List;
    return rows.map((row) {
      final map = row as Map<String, dynamic>;
      return (map['query'] as String, (map['search_count'] as num).toInt());
    }).toList();
  }
}

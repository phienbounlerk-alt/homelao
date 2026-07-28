import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/daily_event.dart';
import '../models/owner_dashboard_summary.dart';

enum ChartPeriod { daily, weekly, monthly, yearly }

class OwnerDashboardRepository {
  OwnerDashboardRepository._();

  static SupabaseClient get _client => Supabase.instance.client;

  static Future<OwnerDashboardSummary> fetchSummary() async {
    final rows = await _client.rpc('owner_dashboard_summary') as List;
    if (rows.isEmpty) return OwnerDashboardSummary.empty;
    return OwnerDashboardSummary.fromMap(rows.first as Map<String, dynamic>);
  }

  /// Raw daily-bucketed activity, furthest-back `daysBack` days. Days with
  /// no activity simply don't appear — callers that need gap-free series
  /// should account for that, matching how the admin dashboard's chart
  /// already handles sparse daily data.
  static Future<List<DailyEvent>> fetchDailyEvents({
    int daysBack = 365,
  }) async {
    final rows =
        await _client.rpc(
              'owner_dashboard_daily_events',
              params: {'p_days_back': daysBack},
            )
            as List;
    return rows
        .map((row) => DailyEvent.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Buckets daily rows into weekly/monthly/yearly totals for the
  /// dashboard's period toggle. Weeks start on Monday. Returned newest
  /// first, same ordering as [fetchDailyEvents].
  static List<DailyEvent> resample(List<DailyEvent> daily, ChartPeriod period) {
    if (period == ChartPeriod.daily) return daily;

    DateTime bucketKey(DateTime day) => switch (period) {
      ChartPeriod.weekly => day.subtract(Duration(days: day.weekday - 1)),
      ChartPeriod.monthly => DateTime(day.year, day.month),
      ChartPeriod.yearly => DateTime(day.year),
      ChartPeriod.daily => day,
    };

    final buckets = <DateTime, List<DailyEvent>>{};
    for (final event in daily) {
      buckets.putIfAbsent(bucketKey(event.day), () => []).add(event);
    }

    final resampled = buckets.entries.map((entry) {
      final bucket = entry.value;
      return DailyEvent(
        day: entry.key,
        views: bucket.fold(0, (sum, e) => sum + e.views),
        favorites: bucket.fold(0, (sum, e) => sum + e.favorites),
        phoneClicks: bucket.fold(0, (sum, e) => sum + e.phoneClicks),
        messages: bucket.fold(0, (sum, e) => sum + e.messages),
        bookings: bucket.fold(0, (sum, e) => sum + e.bookings),
      );
    }).toList();
    resampled.sort((a, b) => b.day.compareTo(a.day));
    return resampled;
  }
}

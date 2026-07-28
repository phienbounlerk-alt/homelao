import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/daily_event.dart';
import '../models/owner_booking.dart';
import '../models/owner_dashboard_summary.dart';
import '../models/review.dart';
import 'property_repository.dart';

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

  /// Bookings made on any of the current owner's listings, newest first.
  /// bookings.user_id references auth.users (not profiles), so renter
  /// name/avatar are fetched separately and stitched in client-side rather
  /// than embedded in one query.
  static Future<List<OwnerBooking>> fetchOwnerBookings() async {
    final properties = await PropertyRepository.fetchMine();
    if (properties.isEmpty) return [];
    final propertyById = {for (final p in properties) p.id: p};
    final rows = await _client
        .from('bookings')
        .select('id, property_id, user_id, scheduled_at')
        .inFilter('property_id', propertyById.keys.toList())
        .order('scheduled_at', ascending: false)
        .limit(200);
    final bookingRows = (rows as List).cast<Map<String, dynamic>>();
    if (bookingRows.isEmpty) return [];

    final renterIds = bookingRows
        .map((r) => r['user_id'] as String)
        .toSet()
        .toList();
    final profileRows = await _client
        .from('profiles')
        .select('id, name, avatar_url')
        .inFilter('id', renterIds);
    final profileById = {
      for (final p in profileRows as List)
        (p as Map<String, dynamic>)['id'] as String: p,
    };

    return bookingRows.map((row) {
      final property = propertyById[row['property_id']]!;
      final profile = profileById[row['user_id']];
      final name = profile?['name'] as String?;
      return OwnerBooking(
        id: row['id'] as String,
        propertyId: property.id,
        propertyTitle: property.title,
        propertyImageUrl: property.imageUrl,
        scheduledAt: DateTime.parse(row['scheduled_at'] as String),
        renterName: name?.isNotEmpty == true ? name! : 'ຜູ້ໃຊ້',
        renterAvatarUrl: profile?['avatar_url'] as String?,
      );
    }).toList();
  }

  /// Reviews on any of the current owner's listings — the same
  /// publicly-visible rows any visitor would see (hidden reviews stay
  /// hidden), newest first.
  static Future<List<Review>> fetchOwnerReviews() async {
    final properties = await PropertyRepository.fetchMine();
    if (properties.isEmpty) return [];
    final rows = await _client
        .from('reviews')
        .select('*, profiles(name, avatar_url)')
        .inFilter('property_id', properties.map((p) => p.id).toList())
        .order('created_at', ascending: false)
        .limit(200);
    return (rows as List)
        .map((row) => Review.fromMap(row as Map<String, dynamic>))
        .toList();
  }
}

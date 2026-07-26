import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/property.dart';

class Booking {
  const Booking({required this.property, required this.scheduledAt});

  /// Null when the listing this booking was made against has since been
  /// deleted — the booking itself is kept (the appointment happened), the
  /// FK just no longer resolves to a listing.
  final Property? property;
  final DateTime scheduledAt;
}

class BookingRepository {
  BookingRepository._();

  static SupabaseClient get _client => Supabase.instance.client;

  static Future<List<Booking>> fetchMine() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final rows = await _client
        .from('bookings')
        .select('scheduled_at, properties(*)')
        .eq('user_id', userId)
        .order('scheduled_at', ascending: false);
    return (rows as List).map((row) {
      final map = row as Map<String, dynamic>;
      final propertyMap = map['properties'] as Map<String, dynamic>?;
      return Booking(
        property: propertyMap == null ? null : Property.fromMap(propertyMap),
        scheduledAt: DateTime.parse(map['scheduled_at'] as String),
      );
    }).toList();
  }
}

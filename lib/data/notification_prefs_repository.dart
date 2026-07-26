import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationPrefs {
  const NotificationPrefs({
    this.listingUpdates = true,
    this.driverUpdates = true,
    this.movingUpdates = true,
  });

  factory NotificationPrefs.fromMap(Map<String, dynamic> map) {
    return NotificationPrefs(
      listingUpdates: map['listing_updates'] as bool? ?? true,
      driverUpdates: map['driver_updates'] as bool? ?? true,
      movingUpdates: map['moving_updates'] as bool? ?? true,
    );
  }

  final bool listingUpdates;
  final bool driverUpdates;
  final bool movingUpdates;

  NotificationPrefs copyWith({
    bool? listingUpdates,
    bool? driverUpdates,
    bool? movingUpdates,
  }) {
    return NotificationPrefs(
      listingUpdates: listingUpdates ?? this.listingUpdates,
      driverUpdates: driverUpdates ?? this.driverUpdates,
      movingUpdates: movingUpdates ?? this.movingUpdates,
    );
  }

  /// Whether a notification of [type] should be shown, given these prefs.
  /// Unrecognized types always show — muting only applies to the
  /// categories the settings screen actually exposes.
  bool allowsType(String type) {
    if (type.startsWith('listing_') || type.startsWith('feature_')) {
      return listingUpdates;
    }
    if (type.startsWith('driver_')) return driverUpdates;
    if (type.startsWith('moving_')) return movingUpdates;
    return true;
  }
}

class NotificationPrefsRepository {
  NotificationPrefsRepository._();

  static SupabaseClient get _client => Supabase.instance.client;

  /// A missing row means every category defaults to true, so there's
  /// nothing to fall back to on failure beyond the same default.
  static Future<NotificationPrefs> fetchMine() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const NotificationPrefs();
    final row = await _client
        .from('notification_prefs')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return const NotificationPrefs();
    return NotificationPrefs.fromMap(row);
  }

  /// Upserts a single column; columns not present keep their existing
  /// value on conflict, or the table default on first insert.
  static Future<void> setPref({
    required String column,
    required bool value,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('notification_prefs').upsert({
      'user_id': userId,
      column: value,
    });
  }
}

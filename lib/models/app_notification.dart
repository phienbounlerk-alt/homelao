class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.read,
    required this.createdAt,
    this.relatedPropertyId,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      type: map['type'] as String,
      read: map['read'] as bool,
      createdAt: DateTime.parse(map['created_at'] as String),
      relatedPropertyId: map['related_property_id'] as String?,
    );
  }

  final String id;
  final String title;
  final String body;

  /// 'listing_approved' | 'listing_rejected' | 'feature_confirmed' |
  /// 'feature_rejected' | 'driver_approved' | 'driver_rejected' |
  /// 'moving_accepted' | 'moving_in_progress' | 'moving_completed'.
  final String type;
  final bool read;
  final DateTime createdAt;
  final String? relatedPropertyId;
}

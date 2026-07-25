class FeaturedRequest {
  const FeaturedRequest({
    required this.id,
    required this.propertyId,
    required this.propertyTitle,
    required this.amountLak,
    required this.durationDays,
    required this.status,
    required this.createdAt,
    this.proofImageUrl,
  });

  factory FeaturedRequest.fromMap(Map<String, dynamic> map) {
    final property = map['properties'] as Map<String, dynamic>?;
    return FeaturedRequest(
      id: map['id'] as String,
      propertyId: map['property_id'] as String,
      propertyTitle: property?['title'] as String? ?? '',
      amountLak: map['amount_lak'] as int,
      durationDays: map['duration_days'] as int,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      proofImageUrl: map['proof_image_url'] as String?,
    );
  }

  final String id;
  final String propertyId;
  final String propertyTitle;
  final int amountLak;
  final int durationDays;

  /// 'pending_review' | 'confirmed' | 'rejected'.
  final String status;
  final DateTime createdAt;
  final String? proofImageUrl;
}

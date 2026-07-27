class Review {
  const Review({
    required this.id,
    required this.propertyId,
    required this.userId,
    required this.cleanliness,
    required this.locationRating,
    required this.safety,
    required this.internet,
    required this.parking,
    required this.value,
    required this.overall,
    required this.comment,
    required this.photos,
    required this.helpfulCount,
    required this.hidden,
    required this.createdAt,
    required this.reviewerName,
    this.reviewerAvatarUrl,
  });

  final String id;
  final String propertyId;
  final String userId;
  final int cleanliness;
  final int locationRating;
  final int safety;
  final int internet;
  final int parking;
  final int value;
  final double overall;
  final String comment;
  final List<String> photos;
  final int helpfulCount;
  final bool hidden;
  final DateTime createdAt;
  final String reviewerName;
  final String? reviewerAvatarUrl;

  Review copyWith({int? helpfulCount}) {
    return Review(
      id: id,
      propertyId: propertyId,
      userId: userId,
      cleanliness: cleanliness,
      locationRating: locationRating,
      safety: safety,
      internet: internet,
      parking: parking,
      value: value,
      overall: overall,
      comment: comment,
      photos: photos,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      hidden: hidden,
      createdAt: createdAt,
      reviewerName: reviewerName,
      reviewerAvatarUrl: reviewerAvatarUrl,
    );
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>?;
    final name = profile?['name'] as String?;
    return Review(
      id: map['id'] as String,
      propertyId: map['property_id'] as String,
      userId: map['user_id'] as String,
      cleanliness: (map['cleanliness'] as num).toInt(),
      locationRating: (map['location_rating'] as num).toInt(),
      safety: (map['safety'] as num).toInt(),
      internet: (map['internet'] as num).toInt(),
      parking: (map['parking'] as num).toInt(),
      value: (map['value'] as num).toInt(),
      overall: (map['overall'] as num).toDouble(),
      comment: map['comment'] as String? ?? '',
      photos: (map['photos'] as List?)?.cast<String>() ?? const [],
      helpfulCount: (map['helpful_count'] as num?)?.toInt() ?? 0,
      hidden: map['hidden'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      reviewerName: name?.isNotEmpty == true ? name! : 'ຜູ້ໃຊ້',
      reviewerAvatarUrl: profile?['avatar_url'] as String?,
    );
  }
}

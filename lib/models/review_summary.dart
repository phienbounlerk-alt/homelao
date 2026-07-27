/// Aggregate rating data for a property, computed server-side by the
/// `property_rating_summary` RPC rather than pulled from every review row.
class ReviewSummary {
  const ReviewSummary({
    required this.reviewCount,
    required this.avgOverall,
    required this.avgCleanliness,
    required this.avgLocation,
    required this.avgSafety,
    required this.avgInternet,
    required this.avgParking,
    required this.avgValue,
    required this.star1,
    required this.star2,
    required this.star3,
    required this.star4,
    required this.star5,
  });

  final int reviewCount;
  final double avgOverall;
  final double avgCleanliness;
  final double avgLocation;
  final double avgSafety;
  final double avgInternet;
  final double avgParking;
  final double avgValue;
  final int star1;
  final int star2;
  final int star3;
  final int star4;
  final int star5;

  static const empty = ReviewSummary(
    reviewCount: 0,
    avgOverall: 0,
    avgCleanliness: 0,
    avgLocation: 0,
    avgSafety: 0,
    avgInternet: 0,
    avgParking: 0,
    avgValue: 0,
    star1: 0,
    star2: 0,
    star3: 0,
    star4: 0,
    star5: 0,
  );

  factory ReviewSummary.fromMap(Map<String, dynamic> map) {
    return ReviewSummary(
      reviewCount: (map['review_count'] as num?)?.toInt() ?? 0,
      avgOverall: (map['avg_overall'] as num?)?.toDouble() ?? 0,
      avgCleanliness: (map['avg_cleanliness'] as num?)?.toDouble() ?? 0,
      avgLocation: (map['avg_location'] as num?)?.toDouble() ?? 0,
      avgSafety: (map['avg_safety'] as num?)?.toDouble() ?? 0,
      avgInternet: (map['avg_internet'] as num?)?.toDouble() ?? 0,
      avgParking: (map['avg_parking'] as num?)?.toDouble() ?? 0,
      avgValue: (map['avg_value'] as num?)?.toDouble() ?? 0,
      star1: (map['star_1'] as num?)?.toInt() ?? 0,
      star2: (map['star_2'] as num?)?.toInt() ?? 0,
      star3: (map['star_3'] as num?)?.toInt() ?? 0,
      star4: (map['star_4'] as num?)?.toInt() ?? 0,
      star5: (map['star_5'] as num?)?.toInt() ?? 0,
    );
  }

  int get maxStarBucket => [
    star1,
    star2,
    star3,
    star4,
    star5,
  ].reduce((a, b) => a > b ? a : b);
}

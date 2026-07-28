class OwnerDashboardSummary {
  const OwnerDashboardSummary({
    required this.totalListings,
    required this.activeListings,
    required this.rentedListings,
    required this.occupancyRate,
    required this.totalViews,
    required this.totalFavorites,
    required this.totalPhoneClicks,
    required this.totalMessages,
    required this.totalBookings,
    required this.avgRating,
    required this.estimatedMonthlyRevenue,
  });

  factory OwnerDashboardSummary.fromMap(Map<String, dynamic> map) {
    return OwnerDashboardSummary(
      totalListings: map['total_listings'] as int,
      activeListings: map['active_listings'] as int,
      rentedListings: map['rented_listings'] as int,
      occupancyRate: (map['occupancy_rate'] as num).toDouble(),
      totalViews: map['total_views'] as int,
      totalFavorites: map['total_favorites'] as int,
      totalPhoneClicks: map['total_phone_clicks'] as int,
      totalMessages: map['total_messages'] as int,
      totalBookings: map['total_bookings'] as int,
      avgRating: (map['avg_rating'] as num).toDouble(),
      estimatedMonthlyRevenue: map['estimated_monthly_revenue'] as int,
    );
  }

  static const empty = OwnerDashboardSummary(
    totalListings: 0,
    activeListings: 0,
    rentedListings: 0,
    occupancyRate: 0,
    totalViews: 0,
    totalFavorites: 0,
    totalPhoneClicks: 0,
    totalMessages: 0,
    totalBookings: 0,
    avgRating: 0,
    estimatedMonthlyRevenue: 0,
  );

  final int totalListings;
  final int activeListings;
  final int rentedListings;

  /// Percentage (0-100) of active listings currently marked rented.
  final double occupancyRate;

  final int totalViews;
  final int totalFavorites;
  final int totalPhoneClicks;
  final int totalMessages;
  final int totalBookings;
  final double avgRating;

  /// Sum of `price_lak` across active listings — an estimate of potential
  /// monthly income, not real collected revenue (HomeLao has no
  /// rent-collection infrastructure).
  final int estimatedMonthlyRevenue;
}

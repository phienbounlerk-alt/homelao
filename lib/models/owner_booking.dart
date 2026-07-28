class OwnerBooking {
  const OwnerBooking({
    required this.id,
    required this.propertyId,
    required this.propertyTitle,
    required this.propertyImageUrl,
    required this.scheduledAt,
    required this.renterName,
    required this.renterAvatarUrl,
  });

  final String id;
  final String propertyId;
  final String propertyTitle;
  final String propertyImageUrl;
  final DateTime scheduledAt;
  final String renterName;
  final String? renterAvatarUrl;
}

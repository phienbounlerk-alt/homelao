class Property {
  const Property({
    required this.id,
    required this.imageUrl,
    required this.priceLak,
    required this.title,
    required this.location,
    required this.beds,
    required this.baths,
    required this.areaSqm,
    required this.rating,
    required this.views,
    this.verified = true,
    this.landlordAvatarUrl =
        'https://images.unsplash.com/photo-1633332755192-727a05c4013d?w=100&q=80',
    this.landlordName = 'ເຈົ້າຂອງຊັບສິນ',
    this.description =
        'ຊັບສິນນີ້ຢູ່ໃນທຳເລດີ ໃກ້ສິ່ງອຳນວຍຄວາມສະດວກ ເໝາະສຳລັບຢູ່ອາໄສ. '
        'ຫ້ອງສະອາດ ພ້ອມເຟີນິເຈີພື້ນຖານ ແລະ ຄວາມປອດໄພຕະຫຼອດ 24 ຊົ່ວໂມງ. '
        'ຕິດຕໍ່ເຈົ້າຂອງເພື່ອນັດເບິ່ງຫ້ອງໄດ້ທັນທີ.',
    this.status = 'approved',
    this.featured = false,
    this.featuredUntil,
    this.ownerId,
    this.distanceKm,
    this.photos = const [],
    this.parking = false,
    this.petFriendly = false,
    this.lat,
    this.lng,
  });

  /// Supabase-issued row id (`properties.id`).
  factory Property.fromMap(Map<String, dynamic> map) {
    return Property(
      id: map['id'] as String,
      imageUrl: map['image_url'] as String,
      priceLak: map['price_lak'] as int,
      title: map['title'] as String,
      location: map['location'] as String,
      beds: map['beds'] as int,
      baths: map['baths'] as int,
      areaSqm: map['area_sqm'] as int,
      rating: (map['rating'] as num).toDouble(),
      views: map['views'] as int,
      verified: map['verified'] as bool? ?? true,
      landlordAvatarUrl:
          map['landlord_avatar_url'] as String? ??
          'https://images.unsplash.com/photo-1633332755192-727a05c4013d?w=100&q=80',
      landlordName: (map['landlord_name'] as String?)?.isNotEmpty == true
          ? map['landlord_name'] as String
          : 'ເຈົ້າຂອງຊັບສິນ',
      description: (map['description'] as String?)?.isNotEmpty == true
          ? map['description'] as String
          : 'ຊັບສິນນີ້ຢູ່ໃນທຳເລດີ ໃກ້ສິ່ງອຳນວຍຄວາມສະດວກ ເໝາະສຳລັບຢູ່ອາໄສ. '
                'ຫ້ອງສະອາດ ພ້ອມເຟີນິເຈີພື້ນຖານ ແລະ ຄວາມປອດໄພຕະຫຼອດ 24 ຊົ່ວໂມງ. '
                'ຕິດຕໍ່ເຈົ້າຂອງເພື່ອນັດເບິ່ງຫ້ອງໄດ້ທັນທີ.',
      status: map['status'] as String? ?? 'approved',
      featured: map['featured'] as bool? ?? false,
      featuredUntil: map['featured_until'] != null
          ? DateTime.parse(map['featured_until'] as String)
          : null,
      ownerId: map['owner_id'] as String?,
      photos: (map['photos'] as List?)?.cast<String>() ?? const [],
      parking: map['parking'] as bool? ?? false,
      petFriendly: map['pet_friendly'] as bool? ?? false,
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
    );
  }

  final String id;
  final String imageUrl;
  final int priceLak;
  final String title;
  final String location;
  final int beds;
  final int baths;
  final int areaSqm;
  final double rating;
  final int views;
  final bool verified;
  final String landlordAvatarUrl;
  final String landlordName;
  final String description;

  /// Moderation state: 'pending' | 'approved' | 'rejected'. Only the owner
  /// and admins ever see a non-approved row — RLS hides it from everyone
  /// else at the query level.
  final String status;

  final bool featured;
  final DateTime? featuredUntil;
  final String? ownerId;

  /// All photos for this listing, in upload order. Falls back to just
  /// [imageUrl] for rows that predate this field.
  final List<String> photos;

  final bool parking;
  final bool petFriendly;

  /// Map coordinates — null for listings posted before geotagging existed,
  /// or where the owner skipped "use current location".
  final double? lat;
  final double? lng;

  bool get hasCoordinates => lat != null && lng != null;

  /// Photos to actually render — never empty, even for old rows.
  List<String> get displayPhotos => photos.isNotEmpty ? photos : [imageUrl];

  /// Distance in km from a search origin — only set on results from
  /// [PropertyRepository.fetchNear], never persisted or read from Supabase.
  final double? distanceKm;

  Property withDistance(double km) => Property(
    id: id,
    imageUrl: imageUrl,
    priceLak: priceLak,
    title: title,
    location: location,
    beds: beds,
    baths: baths,
    areaSqm: areaSqm,
    rating: rating,
    views: views,
    verified: verified,
    landlordAvatarUrl: landlordAvatarUrl,
    landlordName: landlordName,
    description: description,
    status: status,
    featured: featured,
    featuredUntil: featuredUntil,
    ownerId: ownerId,
    distanceKm: km,
    photos: photos,
    parking: parking,
    petFriendly: petFriendly,
    lat: lat,
    lng: lng,
  );

  /// Whether the paid featured-listing boost is still within its window —
  /// checked against [featuredUntil] rather than trusting [featured] alone,
  /// since nothing clears that flag once the period lapses.
  bool get isFeaturedNow =>
      featured &&
      featuredUntil != null &&
      featuredUntil!.isAfter(DateTime.now());

  String get formattedPrice {
    final s = priceLak.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String get formattedViews {
    if (views >= 1000) return '${(views / 1000).toStringAsFixed(1)}k';
    return '$views';
  }
}

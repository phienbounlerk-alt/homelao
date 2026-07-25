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
    this.landlordName = 'ສົມໄຊ ວົງພະຈັນ',
    this.description =
        'ຊັບສິນນີ້ຢູ່ໃນທຳເລດີ ໃກ້ສິ່ງອຳນວຍຄວາມສະດວກ ເໝາະສຳລັບຢູ່ອາໄສ. '
        'ຫ້ອງສະອາດ ພ້ອມເຟີນິເຈີພື້ນຖານ ແລະ ຄວາມປອດໄພຕະຫຼອດ 24 ຊົ່ວໂມງ. '
        'ຕິດຕໍ່ເຈົ້າຂອງເພື່ອນັດເບິ່ງຫ້ອງໄດ້ທັນທີ.',
    this.status = 'approved',
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
          : 'ສົມໄຊ ວົງພະຈັນ',
      description: (map['description'] as String?)?.isNotEmpty == true
          ? map['description'] as String
          : 'ຊັບສິນນີ້ຢູ່ໃນທຳເລດີ ໃກ້ສິ່ງອຳນວຍຄວາມສະດວກ ເໝາະສຳລັບຢູ່ອາໄສ. '
                'ຫ້ອງສະອາດ ພ້ອມເຟີນິເຈີພື້ນຖານ ແລະ ຄວາມປອດໄພຕະຫຼອດ 24 ຊົ່ວໂມງ. '
                'ຕິດຕໍ່ເຈົ້າຂອງເພື່ອນັດເບິ່ງຫ້ອງໄດ້ທັນທີ.',
      status: map['status'] as String? ?? 'approved',
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

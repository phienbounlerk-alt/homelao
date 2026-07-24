class Property {
  const Property({
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
  });

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

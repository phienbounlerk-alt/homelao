import 'package:flutter_test/flutter_test.dart';
import 'package:home_lao/models/property.dart';

Property _property({int priceLak = 1800000, int views = 1234}) {
  return Property(
    id: 'p1',
    imageUrl: 'https://example.com/a.jpg',
    priceLak: priceLak,
    title: 'ອາພາດເມັນ',
    location: 'ຈັນທະບູລີ',
    beds: 2,
    baths: 1,
    areaSqm: 45,
    rating: 4.8,
    views: views,
  );
}

void main() {
  group('Property.formattedPrice', () {
    test('groups digits with commas every 3 places', () {
      expect(_property(priceLak: 1800000).formattedPrice, '1,800,000');
    });

    test('leaves short numbers unchanged', () {
      expect(_property(priceLak: 500).formattedPrice, '500');
    });

    test('handles exact multiples of 3 digits', () {
      expect(_property(priceLak: 1000).formattedPrice, '1,000');
    });
  });

  group('Property.formattedViews', () {
    test('shows raw count under 1000', () {
      expect(_property(views: 999).formattedViews, '999');
    });

    test('shows one decimal "k" at or above 1000', () {
      expect(_property(views: 1200).formattedViews, '1.2k');
    });

    test('rounds to one decimal place', () {
      expect(_property(views: 15650).formattedViews, '15.7k');
    });
  });

  group('Property.fromMap', () {
    test('reads required fields from a Supabase row', () {
      final p = Property.fromMap({
        'id': 'abc',
        'image_url': 'https://example.com/x.jpg',
        'price_lak': 2500000,
        'title': 'ບ້ານດິນ',
        'location': 'ວຽງຈັນ',
        'beds': 3,
        'baths': 2,
        'area_sqm': 80,
        'rating': 4.5,
        'views': 42,
      });
      expect(p.id, 'abc');
      expect(p.priceLak, 2500000);
      expect(p.beds, 3);
      expect(p.rating, 4.5);
      expect(p.verified, isTrue); // default when column is null
    });

    test('falls back to defaults for blank optional fields', () {
      final p = Property.fromMap({
        'id': 'abc',
        'image_url': 'https://example.com/x.jpg',
        'price_lak': 100,
        'title': 'ບ້ານດິນ',
        'location': 'ວຽງຈັນ',
        'beds': 1,
        'baths': 1,
        'area_sqm': 20,
        'rating': 3,
        'views': 0,
        'landlord_name': '',
        'description': '',
        'verified': false,
      });
      expect(p.landlordName, 'ເຈົ້າຂອງຊັບສິນ');
      expect(p.description, isNotEmpty);
      expect(p.verified, isFalse);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_lao/models/property.dart';
import 'package:home_lao/widgets/property_card.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  const property = Property(
    id: 'p1',
    imageUrl: 'https://example.com/a.jpg',
    priceLak: 1800000,
    title: 'ອາພາດເມັນຫ້ອງນອນດຽວ',
    location: 'ຈັນທະບູລີ, ວຽງຈັນ',
    beds: 2,
    baths: 1,
    areaSqm: 45,
    rating: 4.8,
    views: 1200,
  );

  testWidgets('renders the formatted price and title', (tester) async {
    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PropertyCard(property: property)),
        ),
      );

      expect(find.textContaining('1,800,000'), findsOneWidget);
      expect(find.text('ອາພາດເມັນຫ້ອງນອນດຽວ'), findsOneWidget);
    });
  });

  testWidgets('shows a verified badge only when the listing is verified', (
    tester,
  ) async {
    const unverified = Property(
      id: 'p2',
      imageUrl: 'https://example.com/b.jpg',
      priceLak: 900000,
      title: 'ຫ້ອງເຊົ່າ',
      location: 'ໄຊເສດຖາ',
      beds: 1,
      baths: 1,
      areaSqm: 20,
      rating: 4.0,
      views: 10,
      verified: false,
    );

    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PropertyCard(property: unverified)),
        ),
      );

      expect(find.text('ຢືນຢັນແລ້ວ'), findsNothing);
    });
  });
}

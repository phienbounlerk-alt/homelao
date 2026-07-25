import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_lao/widgets/filter_sheet.dart';

void main() {
  group('SearchFilters.isActive', () {
    test('is false for the default (no filters applied)', () {
      expect(const SearchFilters().isActive, isFalse);
    });

    test('is true when the price range is narrowed', () {
      const filters = SearchFilters(
        priceRange: RangeValues(500000, kFilterMaxPrice),
      );
      expect(filters.isActive, isTrue);
    });

    test('is true when a minimum bed count is set', () {
      const filters = SearchFilters(minBeds: 2);
      expect(filters.isActive, isTrue);
    });

    test('is true when a location is set', () {
      const filters = SearchFilters(location: 'ວຽງຈັນ');
      expect(filters.isActive, isTrue);
    });
  });

  group('SearchFilters.activeCount', () {
    test('is 0 for the default', () {
      expect(const SearchFilters().activeCount, 0);
    });

    test('counts each independently-active dimension once', () {
      const filters = SearchFilters(
        priceRange: RangeValues(500000, kFilterMaxPrice),
        minBeds: 3,
        location: 'ວຽງຈັນ',
      );
      expect(filters.activeCount, 3);
    });

    test('a narrowed price range only counts once regardless of side', () {
      const filters = SearchFilters(priceRange: RangeValues(0, 1000000));
      expect(filters.activeCount, 1);
    });
  });
}

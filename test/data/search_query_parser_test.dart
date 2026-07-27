import 'package:flutter_test/flutter_test.dart';
import 'package:home_lao/data/search_query_parser.dart';

void main() {
  group('SearchQueryParser.parse', () {
    test('extracts a price ceiling from "X million kip" phrasing', () {
      final result = SearchQueryParser.parse(
        'I want an apartment under 2 million kip',
      );
      expect(result.maxPrice, 2000000);
      expect(result.matches, isNotEmpty);
    });

    test('extracts a price ceiling from Lao "ລ້ານ ກີບ" phrasing', () {
      final result = SearchQueryParser.parse('ຫ້ອງເຊົ່າຕ່ຳກວ່າ 2 ລ້ານກີບ');
      expect(result.maxPrice, 2000000);
    });

    test(
      'strips the fused Lao "under" qualifier so it does not corrupt the '
      'free-text match, even on the million-kip path',
      () {
        final result = SearchQueryParser.parse('ອາພາດເມັນຕ່ຳກວ່າ 2 ລ້ານກີບ');
        expect(result.maxPrice, 2000000);
        expect(result.cleanedQuery, 'ອາພາດເມັນ');
      },
    );

    test('extracts a plain-number price only when paired with an under cue', () {
      final withCue = SearchQueryParser.parse('under 1500000');
      expect(withCue.maxPrice, 1500000);

      final withoutCue = SearchQueryParser.parse('1500000');
      expect(withoutCue.maxPrice, isNull);
    });

    test('extracts parking', () {
      final result = SearchQueryParser.parse('I need parking');
      expect(result.parking, isTrue);
      expect(result.petFriendly, isFalse);
    });

    test('extracts pet-friendly from English and Lao phrasing', () {
      expect(SearchQueryParser.parse('pet-friendly room').petFriendly, isTrue);
      expect(SearchQueryParser.parse('ຫ້ອງລ້ຽງສັດໄດ້').petFriendly, isTrue);
    });

    test('extracts a bed count', () {
      final result = SearchQueryParser.parse('2 bedroom apartment');
      expect(result.minBeds, 2);
    });

    test('strips filler words, keeping the landmark as the cleaned query', () {
      final result = SearchQueryParser.parse(
        'I need a room near the university',
      );
      expect(result.cleanedQuery.toLowerCase(), 'university');
    });

    test('strips Lao filler words the same way', () {
      final result = SearchQueryParser.parse('ຂ້ອຍຢາກໄດ້ຫ້ອງໃກ້ມະຫາວິທະຍາໄລ');
      expect(result.cleanedQuery, 'ມະຫາວິທະຍາໄລ');
    });

    test('combines multiple signals from one query', () {
      final result = SearchQueryParser.parse(
        'apartment under 2 million kip with parking, pet-friendly, near the hospital',
      );
      expect(result.maxPrice, 2000000);
      expect(result.parking, isTrue);
      expect(result.petFriendly, isTrue);
      expect(result.cleanedQuery.toLowerCase(), contains('hospital'));
    });

    test('an empty or purely conversational query parses to empty', () {
      final result = SearchQueryParser.parse('');
      expect(result.isEmpty, isTrue);
      expect(result.cleanedQuery, isEmpty);
    });
  });
}

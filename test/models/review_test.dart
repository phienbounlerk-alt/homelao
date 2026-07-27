import 'package:flutter_test/flutter_test.dart';
import 'package:home_lao/models/review.dart';
import 'package:home_lao/models/review_summary.dart';

void main() {
  group('Review.fromMap', () {
    test('parses ratings, overall, and the embedded reviewer profile', () {
      final review = Review.fromMap({
        'id': 'r1',
        'property_id': 'p1',
        'user_id': 'u1',
        'cleanliness': 5,
        'location_rating': 4,
        'safety': 5,
        'internet': 3,
        'parking': 4,
        'value': 5,
        'overall': 4.3,
        'comment': 'ຫ້ອງດີ',
        'photos': ['https://example.com/a.jpg'],
        'helpful_count': 2,
        'hidden': false,
        'created_at': '2026-07-27T10:00:00Z',
        'profiles': {'name': 'ສົມສະໄໝ', 'avatar_url': null},
      });

      expect(review.overall, 4.3);
      expect(review.cleanliness, 5);
      expect(review.reviewerName, 'ສົມສະໄໝ');
      expect(review.photos, ['https://example.com/a.jpg']);
      expect(review.helpfulCount, 2);
    });

    test('falls back to a generic name when the profile has none', () {
      final review = Review.fromMap({
        'id': 'r1',
        'property_id': 'p1',
        'user_id': 'u1',
        'cleanliness': 1,
        'location_rating': 1,
        'safety': 1,
        'internet': 1,
        'parking': 1,
        'value': 1,
        'overall': 1.0,
        'comment': '',
        'photos': null,
        'helpful_count': null,
        'hidden': false,
        'created_at': '2026-07-27T10:00:00Z',
        'profiles': {'name': '', 'avatar_url': null},
      });

      expect(review.reviewerName, 'ຜູ້ໃຊ້');
      expect(review.photos, isEmpty);
      expect(review.helpfulCount, 0);
    });
  });

  group('ReviewSummary', () {
    test('fromMap parses averages and the star distribution', () {
      final summary = ReviewSummary.fromMap({
        'review_count': 12,
        'avg_overall': 4.2,
        'avg_cleanliness': 4.5,
        'avg_location': 4.0,
        'avg_safety': 4.8,
        'avg_internet': 3.9,
        'avg_parking': 4.1,
        'avg_value': 4.3,
        'star_1': 0,
        'star_2': 1,
        'star_3': 2,
        'star_4': 5,
        'star_5': 4,
      });

      expect(summary.reviewCount, 12);
      expect(summary.avgOverall, 4.2);
      expect(summary.maxStarBucket, 5);
    });

    test('empty has zeroed-out fields and a max bucket of 0', () {
      expect(ReviewSummary.empty.reviewCount, 0);
      expect(ReviewSummary.empty.maxStarBucket, 0);
    });
  });
}

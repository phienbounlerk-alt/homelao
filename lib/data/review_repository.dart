import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/review.dart';
import '../models/review_summary.dart';

enum ReviewSort { latest, highest, lowest, mostHelpful }

class ReviewRepository {
  ReviewRepository._();

  static SupabaseClient get _client => Supabase.instance.client;

  static const _selectWithReviewer = '*, profiles(name, avatar_url)';

  static Future<List<Review>> fetchForProperty(
    String propertyId, {
    ReviewSort sort = ReviewSort.latest,
  }) async {
    final query = _client
        .from('reviews')
        .select(_selectWithReviewer)
        .eq('property_id', propertyId)
        .eq('hidden', false);
    final rows = await switch (sort) {
      ReviewSort.latest => query.order('created_at', ascending: false),
      ReviewSort.highest => query.order('overall', ascending: false),
      ReviewSort.lowest => query.order('overall', ascending: true),
      ReviewSort.mostHelpful => query.order(
        'helpful_count',
        ascending: false,
      ),
    };
    return (rows as List)
        .map((row) => Review.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  static Future<ReviewSummary> fetchSummary(String propertyId) async {
    final rows =
        await _client.rpc(
              'property_rating_summary',
              params: {'p_property_id': propertyId},
            )
            as List;
    if (rows.isEmpty) return ReviewSummary.empty;
    return ReviewSummary.fromMap(rows.first as Map<String, dynamic>);
  }

  /// The current user's own review for this property, if they've posted
  /// one — used to switch the submission UI into edit mode.
  static Future<Review?> fetchMyReview(String propertyId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    final row = await _client
        .from('reviews')
        .select(_selectWithReviewer)
        .eq('property_id', propertyId)
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return null;
    return Review.fromMap(row);
  }

  /// Whether the current user has ever booked a viewing for this property —
  /// the "real renter" signal a review is gated on, enforced again
  /// server-side by RLS regardless of what this check returns.
  static Future<bool> hasBookedProperty(String propertyId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    final row = await _client
        .from('bookings')
        .select('id')
        .eq('property_id', propertyId)
        .eq('user_id', userId)
        .limit(1)
        .maybeSingle();
    return row != null;
  }

  static Future<void> submit({
    required String propertyId,
    required int cleanliness,
    required int locationRating,
    required int safety,
    required int internet,
    required int parking,
    required int value,
    required String comment,
    List<String> photos = const [],
  }) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('reviews').insert({
      'property_id': propertyId,
      'user_id': userId,
      'cleanliness': cleanliness,
      'location_rating': locationRating,
      'safety': safety,
      'internet': internet,
      'parking': parking,
      'value': value,
      'comment': comment,
      'photos': photos,
    });
  }

  static Future<void> update({
    required String reviewId,
    required int cleanliness,
    required int locationRating,
    required int safety,
    required int internet,
    required int parking,
    required int value,
    required String comment,
    List<String> photos = const [],
  }) async {
    await _client
        .from('reviews')
        .update({
          'cleanliness': cleanliness,
          'location_rating': locationRating,
          'safety': safety,
          'internet': internet,
          'parking': parking,
          'value': value,
          'comment': comment,
          'photos': photos,
        })
        .eq('id', reviewId);
  }

  static Future<bool> hasVotedHelpful(String reviewId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    final row = await _client
        .from('review_helpful_votes')
        .select()
        .eq('review_id', reviewId)
        .eq('user_id', userId)
        .maybeSingle();
    return row != null;
  }

  static Future<void> markHelpful(String reviewId) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('review_helpful_votes').insert({
      'review_id': reviewId,
      'user_id': userId,
    });
  }

  static Future<void> unmarkHelpful(String reviewId) async {
    final userId = _client.auth.currentUser!.id;
    await _client
        .from('review_helpful_votes')
        .delete()
        .eq('review_id', reviewId)
        .eq('user_id', userId);
  }

  static Future<bool> hasReported(String reviewId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    final row = await _client
        .from('review_reports')
        .select()
        .eq('review_id', reviewId)
        .eq('reporter_id', userId)
        .maybeSingle();
    return row != null;
  }

  static Future<void> report(String reviewId, String reason) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('review_reports').insert({
      'review_id': reviewId,
      'reporter_id': userId,
      'reason': reason,
    });
  }

  // --- Admin ---

  static Future<List<Map<String, dynamic>>> fetchReportedReviews() async {
    final rows = await _client.rpc('reported_reviews') as List;
    return rows.cast<Map<String, dynamic>>();
  }

  static Future<void> setHidden(String reviewId, bool hidden) async {
    await _client.rpc(
      'set_review_hidden',
      params: {'p_review_id': reviewId, 'p_hidden': hidden},
    );
  }
}

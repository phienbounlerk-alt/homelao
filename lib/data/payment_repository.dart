import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/featured_request.dart';

/// HomeLao has no payment gateway yet, so featuring a listing is paid by
/// manual bank/mobile-money transfer, confirmed by an admin against the
/// uploaded proof screenshot — see [PaymentInstructions].
class PaymentRepository {
  PaymentRepository._();

  static SupabaseClient get _client => Supabase.instance.client;

  static Future<void> requestFeature({
    required String propertyId,
    required String? proofImageUrl,
  }) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('featured_requests').insert({
      'property_id': propertyId,
      'owner_id': userId,
      'amount_lak': PaymentInstructions.amountLak,
      'duration_days': PaymentInstructions.durationDays,
      'proof_image_url': proofImageUrl,
    });
  }

  static Future<List<FeaturedRequest>> fetchMyRequests() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final rows = await _client
        .from('featured_requests')
        .select('*, properties(title)')
        .eq('owner_id', userId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((row) => FeaturedRequest.fromMap(row as Map<String, dynamic>))
        .toList();
  }
}

class PaymentInstructions {
  PaymentInstructions._();

  static const bankName = 'BCEL';
  static const accountName = 'SOMPHIEN BOUNLERKXAIYASEN';
  static const accountNumber = '2021217855324';
  static const amountLak = 50000;
  static const durationDays = 7;
}

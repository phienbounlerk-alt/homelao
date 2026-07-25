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

/// ⚠️ PLACEHOLDER — not a real account. Replace with HomeLao's actual
/// bank/mobile-money details before this ever reaches a real landlord.
class PaymentInstructions {
  PaymentInstructions._();

  static const bankName = 'ທະນາຄານ BCEL (ຕົວຢ່າງ — ຍັງບໍ່ແມ່ນບັນຊີຈິງ)';
  static const accountName = 'HomeLao (TODO: ໃສ່ຊື່ບັນຊີຈິງ)';
  static const accountNumber = '000-0-00-00000000-0 (TODO)';
  static const amountLak = 50000;
  static const durationDays = 7;
}

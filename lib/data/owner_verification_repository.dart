import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/owner_verification.dart';

class OwnerVerificationRepository {
  OwnerVerificationRepository._();

  static SupabaseClient get _client => Supabase.instance.client;

  /// The current user's own verification submission, regardless of status —
  /// null if they've never submitted one.
  static Future<OwnerVerification?> fetchMine() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    final row = await _client
        .from('owner_verifications')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return null;
    return OwnerVerification.fromMap(row);
  }

  static Future<void> submit({
    String? idDocumentUrl,
    String? selfieUrl,
    String? ownershipDocumentUrl,
    String? phoneNumber,
  }) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('owner_verifications').insert({
      'user_id': userId,
      'id_document_url': idDocumentUrl,
      'selfie_url': selfieUrl,
      'ownership_document_url': ownershipDocumentUrl,
      'phone_number': phoneNumber,
    });
  }

  /// Lets an owner whose submission was rejected or sent back for more
  /// documents edit and resubmit it — updates the same row and flips
  /// status back to 'pending', clearing the previous reviewer's decision.
  static Future<void> resubmit({
    required String id,
    String? idDocumentUrl,
    String? selfieUrl,
    String? ownershipDocumentUrl,
    String? phoneNumber,
  }) async {
    await _client
        .from('owner_verifications')
        .update({
          'id_document_url': idDocumentUrl,
          'selfie_url': selfieUrl,
          'ownership_document_url': ownershipDocumentUrl,
          'phone_number': phoneNumber,
          'status': 'pending',
          'admin_notes': null,
          'reviewed_by': null,
          'reviewed_at': null,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  /// Resends the Supabase Auth email-confirmation link — this app doesn't
  /// build its own email delivery, it just surfaces the confirmation state
  /// Supabase Auth already tracks on the user's own account.
  static Future<void> resendEmailConfirmation() async {
    final email = _client.auth.currentUser?.email;
    if (email == null) return;
    await _client.auth.resend(type: OtpType.signup, email: email);
  }

  // --- Admin review ---

  static Future<List<OwnerVerification>> fetchPending() async {
    final rows = await _client
        .from('owner_verifications')
        .select()
        .eq('status', 'pending')
        .order('created_at');
    return (rows as List)
        .map((row) => OwnerVerification.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  static Future<void> review({
    required OwnerVerification verification,
    required String status,
    String? adminNotes,
  }) async {
    final adminId = _client.auth.currentUser!.id;
    await _client
        .from('owner_verifications')
        .update({
          'status': status,
          'admin_notes': adminNotes,
          'reviewed_by': adminId,
          'reviewed_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', verification.id);
  }
}

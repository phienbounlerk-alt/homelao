import 'package:supabase_flutter/supabase_flutter.dart';

class ConversationRepository {
  ConversationRepository._();

  static SupabaseClient get _client => Supabase.instance.client;

  /// Returns the existing conversation between the current user and the
  /// listing's landlord, or creates one.
  static Future<String> findOrCreate({
    required String propertyId,
    required String landlordName,
    required String? landlordAvatarUrl,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final existing = await _client
        .from('conversations')
        .select('id')
        .eq('user_id', userId)
        .eq('property_id', propertyId)
        .maybeSingle();
    if (existing != null) return existing['id'] as String;

    final inserted = await _client
        .from('conversations')
        .insert({
          'user_id': userId,
          'property_id': propertyId,
          'landlord_name': landlordName,
          'landlord_avatar_url': landlordAvatarUrl,
        })
        .select('id')
        .single();
    return inserted['id'] as String;
  }

  static Future<List<Map<String, dynamic>>> fetchConversations() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final rows = await _client
        .from('conversations')
        .select(
          'id, landlord_name, landlord_avatar_url, created_at, '
          'properties(title, image_url, price_lak), '
          'messages(text, from_me, created_at)',
        )
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> fetchMessages(
    String conversationId,
  ) async {
    final rows = await _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at');
    return (rows as List).cast<Map<String, dynamic>>();
  }

  /// Live-updating list of messages in [conversationId], newest last.
  /// Emits immediately with the current rows, then again on every insert.
  static Stream<List<Map<String, dynamic>>> streamMessages(
    String conversationId,
  ) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
  }

  static Future<void> sendMessage(String conversationId, String text) async {
    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'from_me': true,
      'text': text,
    });
  }
}

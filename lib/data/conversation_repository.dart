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

    try {
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
    } on PostgrestException catch (e) {
      // A concurrent call (double-tap, slow-network retry) already
      // created the row between the select above and this insert —
      // look up what it created instead of failing the whole open-chat
      // flow over a race we can recover from.
      if (e.code != '23505') rethrow;
      final row = await _client
          .from('conversations')
          .select('id')
          .eq('user_id', userId)
          .eq('property_id', propertyId)
          .single();
      return row['id'] as String;
    }
  }

  /// Ordered by most recent activity (latest message, or the
  /// conversation's own creation time if it has none yet) rather than
  /// when the conversation itself was first created, so a reply on an
  /// old thread brings it back to the top.
  ///
  /// Uses a server-side RPC that computes just each conversation's single
  /// latest message, rather than embedding (and pulling to the client)
  /// every message ever sent in every conversation.
  static Future<List<Map<String, dynamic>>> fetchConversations() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final rows = await _client.rpc('conversations_with_latest_message');
    final conversations = (rows as List).cast<Map<String, dynamic>>();
    conversations.sort(
      (a, b) => _latestActivity(b).compareTo(_latestActivity(a)),
    );
    return conversations;
  }

  static DateTime _latestActivity(Map<String, dynamic> conversation) {
    final createdAt = DateTime.parse(conversation['created_at'] as String);
    final latestMessageAt = conversation['latest_message_created_at'] as String?;
    if (latestMessageAt == null) return createdAt;
    final messageAt = DateTime.parse(latestMessageAt);
    return messageAt.isAfter(createdAt) ? messageAt : createdAt;
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

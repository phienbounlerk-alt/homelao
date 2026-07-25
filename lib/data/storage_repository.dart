import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class StorageRepository {
  StorageRepository._();

  static SupabaseClient get _client => Supabase.instance.client;

  /// Uploads image bytes to the current user's folder in the `photos`
  /// bucket and returns its public URL. [folder] scopes the object path
  /// further, e.g. `properties` or `avatars`.
  static Future<String> uploadImage({
    required Uint8List bytes,
    required String folder,
    required String extension,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final fileName = '${DateTime.now().microsecondsSinceEpoch}.$extension';
    final path = '$userId/$folder/$fileName';
    await _client.storage
        .from('photos')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: 'image/$extension',
            upsert: true,
          ),
        );
    return _client.storage.from('photos').getPublicUrl(path);
  }
}

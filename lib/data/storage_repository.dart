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

  /// Uploads image bytes to the current user's folder in the private
  /// `verification-docs` bucket and returns the storage path — not a
  /// public URL, since this bucket has no public access. Callers must
  /// mint a [signedVerificationDocUrl] to actually display it.
  static Future<String> uploadVerificationDocument({
    required Uint8List bytes,
    required String folder,
    required String extension,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final fileName = '${DateTime.now().microsecondsSinceEpoch}.$extension';
    final path = '$userId/$folder/$fileName';
    await _client.storage
        .from('verification-docs')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: 'image/$extension',
            upsert: true,
          ),
        );
    return path;
  }

  /// A short-lived signed URL for a private verification document — the
  /// bucket's RLS still gates who's allowed to mint one (the owning user
  /// or an admin), this just turns a stored path into something
  /// displayable for those five minutes.
  static Future<String> signedVerificationDocUrl(String path) {
    return _client.storage.from('verification-docs').createSignedUrl(path, 300);
  }
}

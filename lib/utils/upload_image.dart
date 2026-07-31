// lib/utils/upload_image.dart

import 'dart:typed_data';
import '../supabase_config.dart';

/// Uploads image bytes to the post_images bucket under the user's folder
/// and returns the public URL.
Future<String> uploadPostImage(String userId, Uint8List bytes, int index) async {
  final fileName = '${DateTime.now().millisecondsSinceEpoch}_$index.jpg';
  final path = '$userId/$fileName';

  await supabase.storage.from('post_images').uploadBinary(path, bytes);
  return supabase.storage.from('post_images').getPublicUrl(path);
}
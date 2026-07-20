import 'package:flutter/foundation.dart';
import '../supabase_config.dart';

class PostsProvider extends ChangeNotifier {
  List<Map<String, dynamic>> posts = [];
  bool isLoading = false;
  bool hasMore = true;
  int page = 0;
  static const pageSize = 10;

  Future<void> fetchPosts({bool refresh = false}) async {
    if (isLoading) return;
    if (refresh) {
      page = 0;
      posts = [];
      hasMore = true;
    }
    if (!hasMore) return;

    isLoading = true;
    notifyListeners();

    final from = page * pageSize;
    final to = from + pageSize - 1;

    final response = await supabase
        .from('posts')
        .select('*, post_images(*)')
        .order('created_at', ascending: false)
        .range(from, to);

    final newPosts = List<Map<String, dynamic>>.from(response);

    if (newPosts.length < pageSize) hasMore = false;
    posts.addAll(newPosts);
    page++;
    isLoading = false;
    notifyListeners();
  }

  // User creates post with title, body and images.
  Future<void> createPost({
    required String title,
    required String body,
    required List<Uint8List> imageBytes,
  }) async {
    final userId = supabase.auth.currentUser!.id;

    final postResponse = await supabase
        .from('posts')
        .insert({'title': title, 'body': body, 'user_id': userId})
        .select()
        .single();

    final postId = postResponse['id'];

    for (var i = 0; i < imageBytes.length; i++) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      final path = '$userId/$fileName';

      await supabase.storage
          .from('post_images')
          .uploadBinary(path, imageBytes[i]);
      final url = supabase.storage.from('post_images').getPublicUrl(path);

      await supabase.from('post_images').insert({
        'post_id': postId,
        'url': url,
      });
    }

    await fetchPosts(refresh: true);
  }

  // User can update their OWN post.
  Future<void> updatePost({
    required String postId,
    required String title,
    required String body,
    required List<Uint8List> newImageBytes,
    required List<String> imageIdsToDelete,
  }) async {
    final userId = supabase.auth.currentUser!.id;

    await supabase
        .from('posts')
        .update({'title': title, 'body': body})
        .eq('id', postId);

    for (final imageId in imageIdsToDelete) {
      await supabase.from('post_images').delete().eq('id', imageId);
    }

    for (var i = 0; i < newImageBytes.length; i++) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      final path = '$userId/$fileName';

      await supabase.storage
          .from('post_images')
          .uploadBinary(path, newImageBytes[i]);
      final url = supabase.storage.from('post_images').getPublicUrl(path);

      await supabase.from('post_images').insert({
        'post_id': postId,
        'url': url,
      });
    }

    await fetchPosts(refresh: true);
  }

  Future<void> deletePost(String postId) async {
    await supabase.from('posts').delete().eq('id', postId);
    posts.removeWhere((p) => p['id'] == postId);
    notifyListeners();
  }
}

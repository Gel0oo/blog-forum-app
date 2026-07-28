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
        .select('*, post_images(*), comments(count), post_likes(user_id)')
        .order('created_at', ascending: false)
        .range(from, to);

    final newPosts = List<Map<String, dynamic>>.from(response);

    final userIds = newPosts
        .map((p) => p['user_id'] as String)
        .toSet()
        .toList();
    if (userIds.isNotEmpty) {
      final profilesResponse = await supabase
          .from('profiles')
          .select('id, name, avatar_url')
          .inFilter('id', userIds);

      final profilesById = {for (final p in profilesResponse) p['id']: p};

      for (final post in newPosts) {
        post['author'] = profilesById[post['user_id']];
      }
    }

    if (newPosts.length < pageSize) hasMore = false;
    posts.addAll(newPosts);
    page++;
    isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> fetchPostById(String id) async {
    final existingIndex = posts.indexWhere((p) => p['id'] == id);
    if (existingIndex != -1) return posts[existingIndex];

    final response = await supabase
        .from('posts')
        .select('*, post_images(*), comments(count), post_likes(user_id)')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;

    final post = Map<String, dynamic>.from(response);
    final userId = post['user_id'] as String;
    final profileResponse = await supabase
        .from('profiles')
        .select('id, name, avatar_url')
        .eq('id', userId)
        .maybeSingle();

    if (profileResponse != null) {
      post['author'] = profileResponse;
    }

    posts.add(post);
    notifyListeners();
    return post;
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

  Future<void> toggleLike(String postId) async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return;
    final userId = currentUser.id;

    final postIndex = posts.indexWhere((p) => p['id'] == postId);
    if (postIndex == -1) return;

    final post = posts[postIndex];
    final likes = post['post_likes'] as List;
    final alreadyLiked = likes.any((l) => l['user_id'] == userId);

    // 1. Optimistic Instant UI Update (0ms delay)
    if (alreadyLiked) {
      likes.removeWhere((l) => l['user_id'] == userId);
    } else {
      likes.add({'user_id': userId});
    }
    notifyListeners();

    // 2. Silent Background Server Sync
    try {
      if (alreadyLiked) {
        await supabase
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);
      } else {
        await supabase.from('post_likes').insert({
          'post_id': postId,
          'user_id': userId,
        });
      }
    } catch (e) {
      // Revert local UI state if network fails
      if (alreadyLiked) {
        likes.add({'user_id': userId});
      } else {
        likes.removeWhere((l) => l['user_id'] == userId);
      }
      notifyListeners();
      rethrow;
    }
  }

  Future<void> searchPosts(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      await fetchPosts(refresh: true); // Resets feed if query is cleared
      return;
    }

    isLoading = true;
    notifyListeners();

    // Searches entire Supabase database for matching titles or bodies
    final response = await supabase
        .from('posts')
        .select('*, post_images(*), comments(count), post_likes(user_id)')
        .or('title.ilike.%$q%,body.ilike.%$q%')
        .order('created_at', ascending: false);

    posts = List<Map<String, dynamic>>.from(response);

    final userIds = posts.map((p) => p['user_id'] as String).toSet().toList();
    if (userIds.isNotEmpty) {
      final profilesResponse = await supabase
          .from('profiles')
          .select('id, name, avatar_url')
          .inFilter('id', userIds);

      final profilesById = {for (final p in profilesResponse) p['id']: p};
      for (final post in posts) {
        post['author'] = profilesById[post['user_id']];
      }
    }

    isLoading = false;
    notifyListeners();
  }
}

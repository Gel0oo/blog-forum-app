// lib/providers/comments_provider.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/upload_image.dart';
import '../supabase_config.dart';

class CommentsProvider extends ChangeNotifier {
  List<Map<String, dynamic>> comments = [];
  bool isLoading = false;
  bool hasMore = true;
  int page = 0;
  int totalCount = 0;
  static const pageSize = 10;

  Future<void> fetchComments(String postId, {bool refresh = false}) async {
    if (isLoading) return;
    if (refresh) {
      page = 0;
      comments = [];
      hasMore = true;
    }
    if (!hasMore) return;

    isLoading = true;
    notifyListeners();

    try {
      final from = page * pageSize;
      final to = from + pageSize - 1;

      // Fetch comments/attached comment images
      final response = await supabase
          .from('comments')
          .select('*, comment_images(*)')
          .eq('post_id', postId)
          .order('created_at', ascending: true)
          .range(from, to)
          .count(CountOption.exact);

      final newComments = List<Map<String, dynamic>>.from(response.data);
      totalCount = response.count;

      // Fetch author profiles
      final userIds = newComments
          .map((c) => c['user_id'] as String)
          .toSet()
          .toList();

      if (userIds.isNotEmpty) {
        final profilesResponse = await supabase
            .from('profiles')
            .select('id, name, avatar_url')
            .inFilter('id', userIds);

        final profilesById = {for (final p in profilesResponse) p['id']: p};

        for (final comment in newComments) {
          comment['author'] = profilesById[comment['user_id']];
        }
      }

      if (comments.length + newComments.length >= totalCount) hasMore = false;
      comments.addAll(newComments);
      page++;
    } catch (e) {
      debugPrint('Error fetching comments: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  int get remainingCount => (totalCount - comments.length).clamp(0, totalCount);

  Future<void> createComment({
    required String postId,
    required String body,
    required List<Uint8List> imageBytes,
  }) async {
    final userId = supabase.auth.currentUser!.id;

    final commentResponse = await supabase
        .from('comments')
        .insert({'post_id': postId, 'user_id': userId, 'body': body})
        .select('*, comment_images(*)')
        .single();

    final commentId = commentResponse['id'];
    final uploadedImages = <Map<String, dynamic>>[];

    for (var i = 0; i < imageBytes.length; i++) {
      final url = await uploadPostImage(userId, imageBytes[i], i);

      final imageRow = await supabase
          .from('comment_images')
          .insert({'comment_id': commentId, 'url': url})
          .select()
          .single();

      uploadedImages.add(imageRow);
    }

    await fetchComments(postId, refresh: true);
  }

  Future<void> updateComment({
    required String commentId,
    required String postId,
    required String body,
    required List<Uint8List> newImageBytes,
    required List<String> imageIdsToDelete,
  }) async {
    final userId = supabase.auth.currentUser!.id;

    await supabase.from('comments').update({'body': body}).eq('id', commentId);

    for (final imageId in imageIdsToDelete) {
      await supabase.from('comment_images').delete().eq('id', imageId);
    }

    for (var i = 0; i < newImageBytes.length; i++) {
      final url = await uploadPostImage(userId, newImageBytes[i], i);

      await supabase.from('comment_images').insert({
        'comment_id': commentId,
        'url': url,
      });
    }

    await fetchComments(postId, refresh: true);
  }

  Future<void> deleteComment(String commentId, String postId) async {
    await supabase.from('comments').delete().eq('id', commentId);
    comments.removeWhere((c) => c['id'] == commentId);
    totalCount--;
    notifyListeners();
  }
}

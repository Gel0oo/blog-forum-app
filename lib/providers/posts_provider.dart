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
}
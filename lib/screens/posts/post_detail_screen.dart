// This screen displays the details of someones post, if the post is owned by the current user viewing. He/she can delete or edit the post.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/posts_provider.dart';
import '../../supabase_config.dart';
import 'post_form_screen.dart';

class PostDetailScreen extends StatelessWidget {
  final Map<String, dynamic> post;

  const PostDetailScreen({super.key, required this.post});

  Future<void> handleDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<PostsProvider>().deletePost(post['id']);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final postsProvider = context.watch<PostsProvider>();
    final currentPost = postsProvider.posts.firstWhere(
      (p) => p['id'] == post['id'],
      orElse: () => post,
    );
    final isOwner = supabase.auth.currentUser?.id == currentPost['user_id'];
    final images = currentPost['post_images'] as List;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        actions: isOwner
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            PostFormScreen(existingPost: currentPost),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => handleDelete(context),
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (images.isNotEmpty)
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Image.network(
                      images[i]['url'],
                      width: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              currentPost['title'],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(currentPost['body']),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/posts_provider.dart';
import '../../providers/comments_provider.dart';
import '../../supabase_config.dart';
import 'post_form_screen.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class PostDetailScreen extends StatelessWidget {
  final Map<String, dynamic> post;
  const PostDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CommentsProvider(),
      child: _PostDetailBody(post: post),
    );
  }
}

class _PostDetailBody extends StatefulWidget {
  final Map<String, dynamic> post;
  const _PostDetailBody({required this.post});

  @override
  State<_PostDetailBody> createState() => _PostDetailBodyState();
}

class _PostDetailBodyState extends State<_PostDetailBody> {
  final commentController = TextEditingController();
  final List<Uint8List> commentImages = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CommentsProvider>().fetchComments(
          widget.post['id'],
          refresh: true,
        );
      }
    });
  }

  Future<void> pickCommentImages() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage();
    for (final file in files) {
      final bytes = await file.readAsBytes();
      setState(() => commentImages.add(bytes));
    }
  }

  Future<void> handleAddComment() async {
    if (commentController.text.trim().isEmpty) return;
    await context.read<CommentsProvider>().createComment(
      postId: widget.post['id'],
      body: commentController.text,
      imageBytes: commentImages,
    );
    commentController.clear();
    setState(() => commentImages.clear());
  }

  Future<void> showEditCommentDialog(Map<String, dynamic> comment) async {
    final editController = TextEditingController(text: comment['body']);

    final newBody = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit comment'),
        content: TextField(controller: editController),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, editController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newBody != null && newBody.trim().isNotEmpty && mounted) {
      await context.read<CommentsProvider>().updateComment(
        commentId: comment['id'],
        postId: widget.post['id'],
        body: newBody,
        newImageBytes: [],
        imageIdsToDelete: [],
      );
    }
  }

  Future<void> handleDeletePost(BuildContext context) async {
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
      await context.read<PostsProvider>().deletePost(widget.post['id']);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final postsProvider = context.watch<PostsProvider>();
    final currentPost = postsProvider.posts.firstWhere(
      (p) => p['id'] == widget.post['id'],
      orElse: () => widget.post,
    );
    final isOwner = supabase.auth.currentUser?.id == currentPost['user_id'];
    final images = currentPost['post_images'] as List;
    final commentsProvider = context.watch<CommentsProvider>();

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
                  onPressed: () => handleDeletePost(context),
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
            const Divider(height: 32),
            const Text(
              'Comments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (supabase.auth.currentUser != null) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      decoration: const InputDecoration(
                        hintText: 'Write a comment...',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.image),
                    onPressed: pickCommentImages,
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: handleAddComment,
                  ),
                ],
              ),
              if (commentImages.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: commentImages
                      .map(
                        (bytes) => Image.memory(
                          bytes,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      )
                      .toList(),
                ),
            ],
            const SizedBox(height: 8),
            if (commentsProvider.isLoading && commentsProvider.comments.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              ...commentsProvider.comments.map((comment) {
                final isCommentOwner =
                    supabase.auth.currentUser?.id == comment['user_id'];
                final commentImgs = comment['comment_images'] as List;
                return ListTile(
                  title: Text(comment['body']),
                  subtitle: commentImgs.isNotEmpty
                      ? SizedBox(
                          height: 60,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: commentImgs.length,
                            itemBuilder: (context, i) => Padding(
                              padding: const EdgeInsets.only(right: 4, top: 4),
                              child: Image.network(
                                commentImgs[i]['url'],
                                width: 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        )
                      : null,
                  trailing: isCommentOwner
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: () => showEditCommentDialog(comment),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18),
                              onPressed: () => context
                                  .read<CommentsProvider>()
                                  .deleteComment(
                                    comment['id'],
                                    widget.post['id'],
                                  ),
                            ),
                          ],
                        )
                      : null,
                );
              }),
              if (commentsProvider.hasMore &&
                  commentsProvider.remainingCount > 0)
                TextButton(
                  onPressed: () => context
                      .read<CommentsProvider>()
                      .fetchComments(widget.post['id']),
                  child: Text(
                    'Show ${commentsProvider.remainingCount} more comments',
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

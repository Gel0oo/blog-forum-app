// lib/widgets/post_detail/detail_comment.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import '../image_viewer.dart';
import '../post_list/list_cardskeleton.dart';
import '../user_avatar.dart';
import '../../providers/comments_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/time_ago.dart';
import '../../supabase_config.dart';

class DetailComment extends StatefulWidget {
  final String postId;
  const DetailComment({super.key, required this.postId});

  @override
  State<DetailComment> createState() => _DetailCommentState();
}

class _DetailCommentState extends State<DetailComment> {
  final commentController = TextEditingController();
  final List<Uint8List> commentImages = [];
  bool isPosting = false;

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
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

    setState(() => isPosting = true);
    try {
      await context.read<CommentsProvider>().createComment(
        postId: widget.postId,
        body: commentController.text.trim(),
        imageBytes: commentImages,
      );
      commentController.clear();
      setState(() => commentImages.clear());
    } finally {
      if (mounted) setState(() => isPosting = false);
    }
  }

  Future<void> showEditCommentDialog(Map<String, dynamic> comment) async {
    final editController = TextEditingController(text: comment['body']);

    final newBody = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Comment'),
        content: TextField(controller: editController, maxLines: 3),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, editController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newBody != null && newBody.trim().isNotEmpty && mounted) {
      await context.read<CommentsProvider>().updateComment(
        commentId: comment['id'],
        postId: widget.postId,
        body: newBody.trim(),
        newImageBytes: [],
        imageIdsToDelete: [],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsProvider = context.watch<CommentsProvider>();
    final isLoggedIn = supabase.auth.currentUser != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comments (${commentsProvider.totalCount})',
          style: AppTextStyles.heading(context, size: 18),
        ),
        const SizedBox(height: 16),

        // Comment Input Box
        if (isLoggedIn) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: shadcn.TextField(
                  controller: commentController,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.border(context)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  placeholder: Text(
                    'Write a comment...',
                    style: AppTextStyles.body(context, size: 13),
                  ),
                  features: const [shadcn.InputFeature.clear()],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Attach Image',
                icon: const Icon(
                  LucideIcons.imagePlus,
                  size: 20,
                  color: AppColors.primary,
                ),
                onPressed: pickCommentImages,
              ),
              const SizedBox(width: 4),
              shadcn.PrimaryButton(
                density: shadcn.ButtonDensity.dense,
                onPressed: isPosting ? null : handleAddComment,
                child: Text(isPosting ? 'Sending...' : 'Comment'),
              ),
            ],
          ),

          if (commentImages.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: commentImages
                  .asMap()
                  .entries
                  .map(
                    (entry) => Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.memory(
                            entry.value,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: -4,
                          right: -4,
                          child: GestureDetector(
                            onTap: () => setState(
                              () => commentImages.removeAt(entry.key),
                            ),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(2),
                              child: const Icon(
                                LucideIcons.x,
                                size: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 20),
        ],

        // Comments List (Reddit Layout)
        if (commentsProvider.isLoading && commentsProvider.comments.isEmpty)
          Column(
            children: List.generate(
              3,
              (_) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SkeletonBox(
                  height: 48,
                  width: double.infinity,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          )
        else if (commentsProvider.comments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No comments yet. Be the first to join the discussion!',
                style: AppTextStyles.body(context),
              ),
            ),
          )
        else ...[
          ...commentsProvider.comments.map((comment) {
            final isCommentOwner =
                supabase.auth.currentUser?.id == comment['user_id'];
            final commentImgs = (comment['comment_images'] as List?) ?? [];
            final authorName = comment['author']?['name'] ?? 'User';
            final authorAvatar = comment['author']?['avatar_url'];

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Author Header: Avatar + Display Name + Bullet + Timestamp
                  Row(
                    children: [
                      UserAvatar(avatarUrl: authorAvatar, radius: 14),
                      const SizedBox(width: 8),
                      Text(
                        authorName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '•  ${timeAgo(comment['created_at'] ?? DateTime.now().toIso8601String())}',
                        style: AppTextStyles.body(context, size: 12),
                      ),
                      const Spacer(),
                      if (isCommentOwner) ...[
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          icon: Icon(
                            LucideIcons.pencil,
                            size: 14,
                            color: AppColors.textSecondary(context),
                          ),
                          onPressed: () => showEditCommentDialog(comment),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          icon: const Icon(
                            LucideIcons.trash2,
                            size: 14,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => context
                              .read<CommentsProvider>()
                              .deleteComment(comment['id'], widget.postId),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),

                  // 2. Comment Body Text
                  Padding(
                    padding: const EdgeInsets.only(left: 36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comment['body'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        if (commentImgs.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 80,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: commentImgs.length,
                              itemBuilder: (context, i) {
                                final url = commentImgs[i]['url'] as String;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () {
                                      showGeneralDialog(
                                        context: context,
                                        barrierDismissible: true,
                                        barrierLabel: 'Close',
                                        barrierColor: Colors.transparent,
                                        pageBuilder: (_, _, _) =>
                                            ImageViewerScreen(url: url),
                                      );
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(
                                        url,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          if (commentsProvider.hasMore && commentsProvider.remainingCount > 0)
            Center(
              child: TextButton(
                onPressed: () => context.read<CommentsProvider>().fetchComments(
                  widget.postId,
                ),
                child: Text(
                  'Show ${commentsProvider.remainingCount} more comments',
                  style: const TextStyle(color: AppColors.primary),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

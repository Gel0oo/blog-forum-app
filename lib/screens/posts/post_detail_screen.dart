// lib/screens/posts/post_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/posts_provider.dart';
import '../../providers/comments_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/top_app_bar.dart';
import '../../widgets/post_detail/detail_content.dart';
import '../../widgets/post_detail/detail_comment.dart';

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

  @override
  Widget build(BuildContext context) {
    final postsProvider = context.watch<PostsProvider>();
    final currentPost = postsProvider.posts.firstWhere(
      (p) => p['id'] == widget.post['id'],
      orElse: () => widget.post,
    );

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: const TopAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 720,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        LucideIcons.arrowLeft,
                        size: 20,
                        color: AppColors.textPrimary(context),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Post View',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                DetailContent(post: currentPost),
                const SizedBox(height: 20),

                DetailComment(postId: widget.post['id']),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
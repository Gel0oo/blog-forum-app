// lib/screens/posts/post_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../main.dart';
import '../../providers/posts_provider.dart';
import '../../providers/comments_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/top_app_bar.dart';
import '../../widgets/post_detail/detail_content.dart';
import '../../widgets/post_detail/detail_comment.dart';

class PostDetailScreen extends StatelessWidget {
  final Map<String, dynamic>? post;
  final String? postId;
  const PostDetailScreen({super.key, this.post, this.postId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CommentsProvider(),
      child: _PostDetailBody(post: post, postId: postId),
    );
  }
}

class _PostDetailBody extends StatefulWidget {
  final Map<String, dynamic>? post;
  final String? postId;
  const _PostDetailBody({this.post, this.postId});

  @override
  State<_PostDetailBody> createState() => _PostDetailBodyState();
}

class _PostDetailBodyState extends State<_PostDetailBody> {
  final scrollController = SmoothScrollController();
  bool notFound = false;

  @override
  void initState() {
    super.initState();
    final targetId = widget.post?['id'] ?? widget.postId;
    if (targetId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final loadedPost =
            await context.read<PostsProvider>().fetchPostById(targetId);
        if (!mounted) return;
        if (loadedPost == null) {
          setState(() => notFound = true);
          return;
        }
        context.read<CommentsProvider>().fetchComments(
              targetId,
              refresh: true,
            );
      });
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postsProvider = context.watch<PostsProvider>();
    final targetId = widget.post?['id'] ?? widget.postId;
    final currentPost = postsProvider.posts.firstWhere(
      (p) => p['id'] == targetId,
      orElse: () => widget.post ?? {},
    );

    if (notFound) {
      return Scaffold(
        backgroundColor: AppColors.background(context),
        appBar: const TopAppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Post not found.',
                style: AppTextStyles.heading(context, size: 20),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      );
    }

    if (currentPost.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background(context),
        appBar: const TopAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: const TopAppBar(),
      body: SingleChildScrollView(
        controller: scrollController, // <-- Explicit SmoothScrollController
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Center(
          child: SizedBox(
            width: 1100,
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
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          context.go('/');
                        }
                      },
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

                DetailComment(postId: targetId!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
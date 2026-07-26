// lib/screens/posts/post_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/posts_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/top_app_bar.dart';
import '../../widgets/post_list/post_card.dart';
import '../../widgets/post_list/post_card_skeleton.dart';
import '../../widgets/post_list/side_content.dart';

class PostListScreen extends StatefulWidget {
  const PostListScreen({super.key});

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen>
    with SingleTickerProviderStateMixin {
  final scrollController = ScrollController();
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PostsProvider>().fetchPosts(refresh: true);
        if (context.read<AuthProvider>().isLoggedIn) {
          context.read<ProfileProvider>().fetchProfile();
        }
      }
    });

    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        context.read<PostsProvider>().fetchPosts();
      }
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postsProvider = context.watch<PostsProvider>();

    final displayedPosts = List<Map<String, dynamic>>.from(postsProvider.posts);
    if (tabController.index == 1) {
      displayedPosts.sort((a, b) {
        final aLikes = (a['post_likes'] as List).length;
        final bLikes = (b['post_likes'] as List).length;
        return bLikes.compareTo(aLikes);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: const TopAppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 280),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.only(
                  top: AppSpacing.md,
                  bottom: AppSpacing.lg,
                ),
                itemCount: displayedPosts.length + 2,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: TabBar(
                        controller: tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        padding: EdgeInsets.zero,
                        dividerColor: Colors.transparent,
                        indicatorSize: TabBarIndicatorSize.label,
                        indicatorColor: AppColors.primary,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.textPrimary(context),
                        splashBorderRadius: BorderRadius.circular(
                          AppRadius.value,
                        ),
                        overlayColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.hovered)
                              ? AppColors.textPrimary(
                                  context,
                                ).withValues(alpha: 0.08)
                              : null,
                        ),
                        labelStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        tabs: const [
                          Tab(text: 'Most Recent'),
                          Tab(text: 'Trending'),
                        ],
                      ),
                    );
                  }

                  if (postsProvider.isLoading && postsProvider.posts.isEmpty) {
                    return const Column(
                      children: [
                        PostCardSkeleton(),
                        PostCardSkeleton(),
                        PostCardSkeleton(),
                      ],
                    );
                  }

                  if (index == displayedPosts.length + 1) {
                    return postsProvider.hasMore
                        ? const Padding(
                            padding: EdgeInsets.only(bottom: AppSpacing.md),
                            child: PostCardSkeleton(),
                          )
                        : const SizedBox.shrink();
                  }

                  final post = displayedPosts[index - 1];
                  return PostCard(
                    post: post,
                    scrollController: scrollController,
                  );
                },
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            const Expanded(
              flex: 2,
              child: SideContent(),
            ),
          ],
        ),
      ),
    );
  }
}
// lib/screens/posts/post_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/posts_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/time_ago.dart';
import '../../supabase_config.dart';
import '../../screens/posts/post_detail_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../widgets/top_app_bar.dart';
import '../../widgets/post_list/list_card.dart';
import '../../widgets/post_list/list_cardskeleton.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/menu_dropdown.dart';

class PostListScreen extends StatefulWidget {
  const PostListScreen({super.key});

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
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
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postsProvider = context.watch<PostsProvider>();
    final displayedPosts = List<Map<String, dynamic>>.from(postsProvider.posts);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: const TopAppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 750;
          final isTablet = constraints.maxWidth >= 750 && constraints.maxWidth < 1100;

          final List<Widget> feedItems = [];

          // 1. Loading State
          if (postsProvider.isLoading && postsProvider.posts.isEmpty) {
            feedItems.add(
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.xl),
                child: ListCardSkeleton(isHero: true),
              ),
            );
            if (isMobile) {
              feedItems.add(
                const Column(
                  children: [
                    ListCardSkeleton(),
                    SizedBox(height: AppSpacing.lg),
                    ListCardSkeleton(),
                  ],
                ),
              );
            } else {
              feedItems.add(
                const Row(
                  children: [
                    Expanded(child: ListCardSkeleton()),
                    SizedBox(width: AppSpacing.lg),
                    Expanded(child: ListCardSkeleton()),
                    SizedBox(width: AppSpacing.lg),
                    Expanded(child: ListCardSkeleton()),
                  ],
                ),
              );
            }
          }
          // 2. Empty State
          else if (!postsProvider.isLoading && displayedPosts.isEmpty) {
            feedItems.add(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text(
                    'No posts found.',
                    style: AppTextStyles.body(context, size: 15),
                  ),
                ),
              ),
            );
          }
          // 3. Single Unified Publication Feed
          else {
            // A. Top Big Featured Hero Banner (Most Recent Post)
            final heroPost = displayedPosts.first;
            feedItems.add(
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                child: ListCard(
                  post: heroPost,
                  scrollController: scrollController,
                  isHero: true,
                ),
              ),
            );

            // B. Middle Trending Container (Top 4 Trending Posts by Likes)
            final sortedByLikes = List<Map<String, dynamic>>.from(displayedPosts)
              ..sort((a, b) {
                final aLikes = ((a['post_likes'] as List?) ?? []).length;
                final bLikes = ((b['post_likes'] as List?) ?? []).length;
                return bLikes.compareTo(aLikes);
              });

            final top4Trending = sortedByLikes.take(4).toList();
            if (top4Trending.isNotEmpty) {
              feedItems.add(
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                  child: _buildHashnodeTrendingSection(
                    context,
                    top4Trending,
                    isMobile,
                  ),
                ),
              );
            }

            // C. Bottom Remaining Posts in 3-Column Masonry Grid
            final remainingPosts = displayedPosts.length > 1
                ? displayedPosts.sublist(1)
                : <Map<String, dynamic>>[];

            if (remainingPosts.isNotEmpty) {
              if (isMobile) {
                for (final post in remainingPosts) {
                  feedItems.add(
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: ListCard(
                        post: post,
                        scrollController: scrollController,
                      ),
                    ),
                  );
                }
              } else {
                final int numColumns = isTablet ? 2 : 3;
                final List<List<Map<String, dynamic>>> columnPosts =
                    List.generate(numColumns, (_) => []);

                for (int i = 0; i < remainingPosts.length; i++) {
                  columnPosts[i % numColumns].add(remainingPosts[i]);
                }

                feedItems.add(
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int col = 0; col < numColumns; col++) ...[
                        if (col > 0) const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            children: [
                              for (final post in columnPosts[col])
                                Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: AppSpacing.lg),
                                  child: ListCard(
                                    post: post,
                                    scrollController: scrollController,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }
            }

            // D. Pagination Skeleton
            if (postsProvider.hasMore) {
              feedItems.add(
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: isMobile
                      ? const ListCardSkeleton()
                      : const Row(
                          children: [
                            Expanded(child: ListCardSkeleton()),
                            SizedBox(width: AppSpacing.lg),
                            Expanded(child: ListCardSkeleton()),
                            SizedBox(width: AppSpacing.lg),
                            Expanded(child: ListCardSkeleton()),
                          ],
                        ),
                ),
              );
            }
          }

          const double maxGridWidth = 1200;

          return ListView.builder(
            controller: scrollController,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: AppSpacing.md,
            ),
            itemCount: feedItems.length,
            itemBuilder: (context, index) {
              return Center(
                child: SizedBox(
                  width: maxGridWidth,
                  child: feedItems[index],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Hashnode Trending Container (Top 4 Posts)
  Widget _buildHashnodeTrendingSection(
    BuildContext context,
    List<Map<String, dynamic>> posts,
    bool isMobile,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'TRENDING DISCUSSIONS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (isMobile)
            Column(
              children: [
                for (int i = 0; i < posts.length; i++) ...[
                  if (i > 0)
                    Divider(
                      color: AppColors.border(context).withValues(alpha: 0.5),
                      height: 24,
                    ),
                  _TrendingCompactRow(
                    post: posts[i],
                    scrollController: scrollController,
                  ),
                ],
              ],
            )
          else
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        for (int i = 0; i < posts.length; i += 2) ...[
                          if (i > 0)
                            Divider(
                              color: AppColors.border(context)
                                  .withValues(alpha: 0.5),
                              height: 24,
                            ),
                          _TrendingCompactRow(
                            post: posts[i],
                            scrollController: scrollController,
                          ),
                        ],
                      ],
                    ),
                  ),
                  VerticalDivider(
                    color: AppColors.border(context).withValues(alpha: 0.5),
                    width: 32,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        for (int i = 1; i < posts.length; i += 2) ...[
                          if (i > 1)
                            Divider(
                              color: AppColors.border(context)
                                  .withValues(alpha: 0.5),
                              height: 24,
                            ),
                          _TrendingCompactRow(
                            post: posts[i],
                            scrollController: scrollController,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TrendingCompactRow extends StatefulWidget {
  final Map<String, dynamic> post;
  final ScrollController scrollController;

  const _TrendingCompactRow({
    required this.post,
    required this.scrollController,
  });

  @override
  State<_TrendingCompactRow> createState() => _TrendingCompactRowState();
}

class _TrendingCompactRowState extends State<_TrendingCompactRow> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;
    final images = (widget.post['post_images'] as List?) ?? [];
    final authorName = widget.post['author']?['name'] ?? 'Author';
    final authorAvatar = widget.post['author']?['avatar_url'];
    final imageUrl = images.isNotEmpty ? images[0]['url'] as String? : null;
    final likes = (widget.post['post_likes'] as List?) ?? [];
    final likeCount = likes.length;
    final isLiked = likes.any(
      (l) => l['user_id'] == supabase.auth.currentUser?.id,
    );
    final commentCount = (widget.post['comments'] as List?)?.isNotEmpty == true
        ? widget.post['comments'][0]['count']
        : 0;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(post: widget.post),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundImage: authorAvatar != null
                              ? NetworkImage(authorAvatar)
                              : null,
                          child: authorAvatar == null
                              ? const Icon(LucideIcons.user, size: 12)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'by $authorName • ${timeAgo(widget.post['created_at'])}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body(context, size: 13),
                          ),
                        ),
                        MenuDropdown(
                          post: widget.post,
                          scrollController: widget.scrollController,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.post['title'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.heading(context, size: 18),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        PillButton(
                          icon: LucideIcons.heart,
                          filled: isLiked,
                          label: '$likeCount',
                          onTap: () {
                            if (!isLoggedIn) {
                              showDialog(
                                context: context,
                                barrierColor: Colors.transparent,
                                builder: (_) => const LoginScreen(),
                              );
                            } else {
                              context
                                  .read<PostsProvider>()
                                  .toggleLike(widget.post['id']);
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        PillButton(
                          icon: LucideIcons.messageCircle,
                          label: '$commentCount',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    PostDetailScreen(post: widget.post),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (imageUrl != null) ...[
                const SizedBox(width: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 130,
                    height: 86,
                    child: AnimatedScale(
                      scale: isHovered ? 1.08 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
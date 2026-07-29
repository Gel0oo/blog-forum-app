// lib/screens/posts/post_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/posts_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/top_app_bar.dart';
import '../../widgets/post_list/list_card.dart';
import '../../widgets/post_list/list_cardskeleton.dart';

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
    tabController = TabController(length: 3, vsync: this);
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
        final aLikes = ((a['post_likes'] as List?) ?? []).length;
        final bLikes = ((b['post_likes'] as List?) ?? []).length;
        return bLikes.compareTo(aLikes);
      });
    } else if (tabController.index == 2) {
      displayedPosts.sort((a, b) {
        final aCount = (a['comments'] as List?)?.isNotEmpty == true
            ? a['comments'][0]['count']
            : 0;
        final bCount = (b['comments'] as List?)?.isNotEmpty == true
            ? b['comments'][0]['count']
            : 0;
        return bCount.compareTo(aCount);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: const TopAppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 750;
          final isTablet = constraints.maxWidth >= 750 && constraints.maxWidth < 1100;

          final List<Widget> feedItems = [];

          // 1. Navigation Header Tabs
          feedItems.add(
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
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
                splashBorderRadius: BorderRadius.circular(AppRadius.value),
                overlayColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.hovered)
                      ? AppColors.textPrimary(context).withValues(alpha: 0.08)
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
                  Tab(text: 'Top Discussions'),
                ],
              ),
            ),
          );

          // 2. Loading or Empty State
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
          } else if (!postsProvider.isLoading && displayedPosts.isEmpty) {
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
          } else {
            // 3. Featured Split Hero Banner (First Post)
            if (displayedPosts.isNotEmpty) {
              feedItems.add(
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                  child: ListCard(
                    post: displayedPosts.first,
                    scrollController: scrollController,
                    isHero: true,
                  ),
                ),
              );
            }

            // 4. Remaining Posts in Standard 3-Column Grid
            final gridPosts = displayedPosts.length > 1
                ? displayedPosts.sublist(1)
                : <Map<String, dynamic>>[];

            final int columns = isMobile ? 1 : (isTablet ? 2 : 3);

            for (int i = 0; i < gridPosts.length; i += columns) {
              final rowPosts = gridPosts.sublist(
                i,
                (i + columns < gridPosts.length) ? i + columns : gridPosts.length,
              );

              feedItems.add(
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int col = 0; col < columns; col++) ...[
                        if (col > 0) const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: col < rowPosts.length
                              ? ListCard(
                                  post: rowPosts[col],
                                  scrollController: scrollController,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }

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
}
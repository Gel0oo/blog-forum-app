// lib/screens/posts/mobile_post_list.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/posts_provider.dart';
import '../../theme/app_theme.dart';
import '../../main.dart';
import '../../widgets/mobile/mobile_list_card.dart';
import '../../widgets/post_list/list_cardskeleton.dart';

class MobilePostList extends StatefulWidget {
  const MobilePostList({super.key});

  @override
  State<MobilePostList> createState() => _MobilePostListState();
}

class _MobilePostListState extends State<MobilePostList> {
  final scrollController = SmoothScrollController();

  @override
  void initState() {
    super.initState();
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

  Widget _buildHashnodeSectionHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'NEW & POPULAR',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Divider(
              color: AppColors.border(context).withValues(alpha: 0.5),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postsProvider = context.watch<PostsProvider>();
    final displayedPosts = List<Map<String, dynamic>>.from(postsProvider.posts);

    if (postsProvider.isLoading && postsProvider.posts.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildHashnodeSectionHeader(context),
          const ListCardSkeleton(isHero: true),
          const SizedBox(height: 16),
          const ListCardSkeleton(),
          const SizedBox(height: 16),
          const ListCardSkeleton(),
        ],
      );
    }

    if (displayedPosts.isEmpty) {
      return Center(
        child: Text(
          'No posts found.',
          style: AppTextStyles.body(context, size: 14),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      itemCount: displayedPosts.length + 1 + (postsProvider.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // 1. Hashnode Header Line
        if (index == 0) {
          return _buildHashnodeSectionHeader(context);
        }

        final postIndex = index - 1;

        // 2. Pagination Skeleton
        if (postIndex == displayedPosts.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: ListCardSkeleton(),
          );
        }

        // 3. Post Card
        final post = displayedPosts[postIndex];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: MobileListCard(
            post: post,
            scrollController: scrollController,
            isHero: postIndex == 0,
          ),
        );
      },
    );
  }
}
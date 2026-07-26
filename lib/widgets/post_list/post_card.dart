// lib/widgets/post_list/post_card.dart

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/posts_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/time_ago.dart';
import '../../supabase_config.dart';
import '../../screens/posts/post_detail_screen.dart';
import 'post_image.dart';
import 'pill_button.dart';
import 'post_menu_dropdown.dart';

class PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final ScrollController scrollController;

  const PostCard({
    super.key,
    required this.post,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;
    final images = post['post_images'] as List;
    final commentCount = (post['comments'] as List).isNotEmpty
        ? post['comments'][0]['count']
        : 0;
    final likes = post['post_likes'] as List;
    final likeCount = likes.length;
    final isLiked = likes.any(
      (l) => l['user_id'] == supabase.auth.currentUser?.id,
    );
    final authorName = post['author']?['name'] ?? 'Unknown';
    final authorAvatar = post['author']?['avatar_url'];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(AppRadius.value),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.value),
          mouseCursor: SystemMouseCursors.click,
          hoverColor: AppColors.hover(context),
          splashColor: Colors.transparent,
          highlightColor: Colors.black.withValues(alpha: 0.02),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PostDetailScreen(post: post),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.value),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: authorAvatar != null
                          ? NetworkImage(authorAvatar)
                          : null,
                      child: authorAvatar == null
                          ? const Icon(LucideIcons.user, size: 16)
                          : null,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authorName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                          Text(
                            '${formatDate(post['created_at'])} • ${timeAgo(post['created_at'])}',
                            style: AppTextStyles.body(context, size: 12),
                          ),
                        ],
                      ),
                    ),
                    PostMenuDropdown(
                      postBody: post['body'],
                      scrollController: scrollController,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  post['title'],
                  style: AppTextStyles.heading(context, size: 20),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  post['body'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body(context),
                ),
                if (images.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  PostImage(url: images[0]['url']),
                ],
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    PillButton(
                      icon: LucideIcons.heart,
                      filled: isLiked,
                      label: '$likeCount',
                      onTap: isLoggedIn
                          ? () => context
                                .read<PostsProvider>()
                                .toggleLike(post['id'])
                          : null,
                    ),
                    const SizedBox(width: 8),
                    PillButton(
                      icon: LucideIcons.messageCircle,
                      label: '$commentCount',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PostDetailScreen(post: post),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    PillButton(
                      icon: LucideIcons.cornerUpRight,
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
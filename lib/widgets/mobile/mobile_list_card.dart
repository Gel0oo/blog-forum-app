// lib/widgets/mobile/mobile_list_card.dart

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../utils/inline_markdown.dart';
import '../../providers/auth_provider.dart';
import '../../providers/posts_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/time_ago.dart';
import '../../supabase_config.dart';
import '../../screens/posts/post_detail_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../pill_button.dart';
import '../menu_dropdown.dart';
import '../user_avatar.dart';
import '../post_list/list_cardskeleton.dart';

class MobileListCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final ScrollController scrollController;
  final bool isHero;

  const MobileListCard({
    super.key,
    required this.post,
    required this.scrollController,
    this.isHero = false,
  });

  @override
  State<MobileListCard> createState() => _MobileListCardState();
}

class _MobileListCardState extends State<MobileListCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;
    final images = (widget.post['post_images'] as List?) ?? [];
    final commentCount = (widget.post['comments'] as List?)?.isNotEmpty == true
        ? widget.post['comments'][0]['count']
        : 0;
    final likes = (widget.post['post_likes'] as List?) ?? [];
    final likeCount = likes.length;
    final isLiked = likes.any(
      (l) => l['user_id'] == supabase.auth.currentUser?.id,
    );
    final authorName = widget.post['author']?['name'] ?? 'Author';
    final authorAvatar = widget.post['author']?['avatar_url'];
    final imageUrl = images.isNotEmpty ? images[0]['url'] as String? : null;

    final isHero = widget.isHero;

    return FadeSlideUp(
      delay: isHero ? const Duration(milliseconds: 300) : Duration.zero,
      child: MouseRegion(
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: AppColors.cardBackground(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isHovered
                    ? AppColors.primary.withValues(alpha: 0.6)
                    : AppColors.border(context),
                width: 1.0,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Most Recent Badge for Hero Card
                if (isHero) ...[
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
                        'MOST RECENT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // 2. Author Meta Line
                Row(
                  children: [
                    UserAvatar(avatarUrl: authorAvatar, radius: 12),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'by $authorName • ${timeAgo(widget.post['created_at'])}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body(context, size: 12),
                      ),
                    ),
                    MenuDropdown(
                      post: widget.post,
                      scrollController: widget.scrollController,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 3. Cover Image Stacked Top on Hero
                if (isHero && imageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: double.infinity,
                      height: 170,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                          if (wasSynchronouslyLoaded || frame != null) {
                            return child;
                          }
                          return const SkeletonBox(
                            width: double.infinity,
                            height: double.infinity,
                            borderRadius: BorderRadius.zero,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // 4. Title & Subtitle Row (Thumbnail 90x65 on Right for non-Hero)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.post['title'] ?? '',
                            maxLines: isHero ? 2 : 3,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.heading(
                              context,
                              size: isHero ? 20 : 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text.rich(
                            TextSpan(
                              children: parseInlineMarkdown(
                                widget.post['body'] ?? '',
                                AppTextStyles.body(
                                  context,
                                  size: isHero ? 14 : 12,
                                ),
                              ),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (imageUrl != null && !isHero) ...[
                      const SizedBox(width: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 90,
                          height: 65,
                          child: AnimatedScale(
                            scale: isHovered ? 1.05 : 1.0,
                            duration: const Duration(milliseconds: 250),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              frameBuilder: (
                                context,
                                child,
                                frame,
                                wasSynchronouslyLoaded,
                              ) {
                                if (wasSynchronouslyLoaded || frame != null) {
                                  return child;
                                }
                                return const SkeletonBox(
                                  width: double.infinity,
                                  height: double.infinity,
                                  borderRadius: BorderRadius.zero,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                Divider(
                  color: AppColors.border(context).withValues(alpha: 0.5),
                  height: 1,
                ),
                const SizedBox(height: 10),

                // 5. Action Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                              context.read<PostsProvider>().toggleLike(
                                widget.post['id'],
                              );
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
                    Row(
                      children: [
                        Text(
                          'Read more',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isHovered
                                ? AppColors.primary
                                : AppColors.textPrimary(context),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          LucideIcons.arrowRight,
                          size: 13,
                          color: isHovered
                              ? AppColors.primary
                              : AppColors.textPrimary(context),
                        ),
                      ],
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
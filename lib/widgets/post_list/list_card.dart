// lib/widgets/post_list/list_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/posts_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/time_ago.dart';
import '../../supabase_config.dart';
import '../../screens/posts/post_detail_screen.dart';
import 'list_image.dart';
import '../pill_button.dart';
import '../menu_dropdown.dart';
import '../image_viewer.dart';
import '../../screens/auth/login_screen.dart';

class ListCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final ScrollController scrollController;

  const ListCard({
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                    MenuDropdown(
                      post: post,
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

                Text.rich(
                  TextSpan(
                    children: _parseInlineMarkdown(
                      post['body'] ?? '',
                      AppTextStyles.body(context),
                    ),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                if (images.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      showGeneralDialog(
                        context: context,
                        barrierDismissible: true,
                        barrierLabel: 'Close image',
                        barrierColor: Colors.transparent,
                        pageBuilder: (context, animation, secondaryAnimation) {
                          return ImageViewerScreen(url: images[0]['url']);
                        },
                      );
                    },
                    child: ListImage(url: images[0]['url']),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
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
                          context.read<PostsProvider>().toggleLike(post['id']);
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
                            builder: (context) => PostDetailScreen(post: post),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    PillButton(
                      icon: LucideIcons.cornerUpRight,
                      onTap: () {
                        final shareUrl =
                            '${Uri.base.origin}/#/post/${post['id']}';
                        Clipboard.setData(ClipboardData(text: shareUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Post link copied to clipboard!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
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

List<InlineSpan> _parseInlineMarkdown(String text, TextStyle baseStyle) {
  text = text.replaceAllMapped(RegExp(r'^-\s+', multiLine: true), (_) => '•  ');

  final pattern = RegExp(
    r'(\*\*\*(.+?)\*\*\*)|(\*\*(.+?)\*\*)|(\*(.+?)\*)|(\[(.+?)\]\((.+?)\))',
  );

  final spans = <InlineSpan>[];
  int lastEnd = 0;

  for (final match in pattern.allMatches(text)) {
    if (match.start > lastEnd) {
      spans.add(
        TextSpan(text: text.substring(lastEnd, match.start), style: baseStyle),
      );
    }

    if (match.group(1) != null) {
      spans.add(
        TextSpan(
          text: match.group(2),
          style: baseStyle.copyWith(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    } else if (match.group(3) != null) {
      spans.add(
        TextSpan(
          text: match.group(4),
          style: baseStyle.copyWith(fontWeight: FontWeight.bold),
        ),
      );
    } else if (match.group(5) != null) {
      spans.add(
        TextSpan(
          text: match.group(6),
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        ),
      );
    } else if (match.group(7) != null) {
      spans.add(
        TextSpan(
          text: match.group(8),
          style: baseStyle.copyWith(
            decoration: TextDecoration.underline,
            color: AppColors.primary,
          ),
        ),
      );
    }
    lastEnd = match.end;
  }

  if (lastEnd < text.length) {
    spans.add(TextSpan(text: text.substring(lastEnd), style: baseStyle));
  }

  return spans;
}

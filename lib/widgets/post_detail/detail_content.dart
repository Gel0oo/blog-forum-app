// lib/widgets/post_detail/detail_content.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/posts_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/time_ago.dart';
import '../../supabase_config.dart';
import '../pill_button.dart';
import '../menu_dropdown.dart';
import '../post_list/list_image.dart';
import '../image_viewer.dart';
import '../../screens/auth/login_screen.dart';

class DetailContent extends StatelessWidget {
  final Map<String, dynamic> post;
  const DetailContent({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;
    final images = (post['post_images'] as List?) ?? [];
    final commentCount = (post['comments'] as List?)?.isNotEmpty == true
        ? post['comments'][0]['count']
        : 0;
    final likes = (post['post_likes'] as List?) ?? [];
    final likeCount = likes.length;
    final isLiked = likes.any(
      (l) => l['user_id'] == supabase.auth.currentUser?.id,
    );
    final authorName = post['author']?['name'] ?? 'Unknown';
    final authorAvatar = post['author']?['avatar_url'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(AppRadius.value),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: authorAvatar != null
                    ? NetworkImage(authorAvatar)
                    : null,
                child: authorAvatar == null
                    ? const Icon(LucideIcons.user, size: 18)
                    : null,
              ),
              const SizedBox(width: 10),
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
              MenuDropdown(post: post, postBody: post['body'] ?? ''),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            post['title'] ?? '',
            style: AppTextStyles.heading(context, size: 22),
          ),
          const SizedBox(height: 12),

          MarkdownBody(
            data: post['body'] ?? '',
            onTapLink: (text, href, title) {
              if (href != null && href.isNotEmpty) {
                launchUrl(Uri.parse(href));
              }
            },
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(fontSize: 15, color: AppColors.textPrimary(context)),
              listBullet: TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary(context),
              ),
              strong: TextStyle(
                color: AppColors.textPrimary(context),
                fontWeight: FontWeight.bold,
              ),
              em: TextStyle(
                color: AppColors.textPrimary(context),
                fontStyle: FontStyle.italic,
              ),
              a: const TextStyle(
                color: AppColors.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (images.isNotEmpty) ...[
            ...images.map((img) {
              final url = img['url'] as String;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    showGeneralDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierLabel: 'Close image',
                      barrierColor: Colors.transparent,
                      pageBuilder: (context, animation, secondaryAnimation) {
                        return ImageViewerScreen(url: url);
                      },
                    );
                  },
                  child: ListImage(url: url),
                ),
              );
            }),
          ],

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
                onTap: () {},
              ),
              const SizedBox(width: 8),
              PillButton(
                icon: LucideIcons.cornerUpRight,
                onTap: () {
                  final shareUrl = '${Uri.base.origin}/#/post/${post['id']}';
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
    );
  }
}

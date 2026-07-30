// lib/widgets/post_detail/detail_content.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final authorName = post['author']?['name'] ?? 'Unknown Author';
    final authorAvatar = post['author']?['avatar_url'];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Edge-to-Edge Cover Image
            if (images.isNotEmpty) ...[
              ...images.map((img) {
                final url = img['url'] as String;
                return GestureDetector(
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
                );
              }),
            ],

            // 2. Article Content Body
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          post['title'] ?? '',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                            height: 1.25,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ),
                      MenuDropdown(post: post),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Text(
                    '${formatDate(post['created_at'])} • ${timeAgo(post['created_at'])}',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(context, size: 13),
                  ),
                  const SizedBox(height: 28),

                  // 3. Borderless Author Bio Box
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundImage: authorAvatar != null
                            ? NetworkImage(authorAvatar)
                            : null,
                        child: authorAvatar == null
                            ? const Icon(LucideIcons.user, size: 22)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authorName,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Author on Postly',
                              style: AppTextStyles.body(context, size: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  Divider(
                    color: AppColors.border(context).withValues(alpha: 0.5),
                    height: 1,
                  ),
                  const SizedBox(height: 28),

                  // 4. Longform Article Markdown
                  MarkdownBody(
                    data: post['body'] ?? '',
                    onTapLink: (text, href, title) {
                      if (href != null && href.isNotEmpty) {
                        launchUrl(Uri.parse(href));
                      }
                    },
                    styleSheet: MarkdownStyleSheet(
                      p: GoogleFonts.inter(
                        fontSize: 17,
                        height: 1.7,
                        color: AppColors.textPrimary(context),
                      ),
                      h1: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary(context),
                      ),
                      h2: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(context),
                      ),
                      h3: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(context),
                      ),
                      listBullet: GoogleFonts.inter(
                        fontSize: 17,
                        height: 1.7,
                        color: AppColors.textPrimary(context),
                      ),
                      code: GoogleFonts.firaCode(
                        fontSize: 14,
                        backgroundColor: AppColors.border(context)
                            .withValues(alpha: 0.4),
                        color: AppColors.textPrimary(context),
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: AppColors.background(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      strong: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary(context),
                      ),
                      em: GoogleFonts.inter(
                        fontSize: 17,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textPrimary(context),
                      ),
                      a: GoogleFonts.inter(
                        fontSize: 17,
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  Divider(
                    color: AppColors.border(context).withValues(alpha: 0.5),
                    height: 1,
                  ),
                  const SizedBox(height: 20),

                  // 5. Action Bar
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
                      const SizedBox(width: 10),
                      PillButton(
                        icon: LucideIcons.messageCircle,
                        label: '$commentCount',
                        onTap: () {},
                      ),
                      const SizedBox(width: 10),
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
          ],
        ),
      ),
    );
  }
}
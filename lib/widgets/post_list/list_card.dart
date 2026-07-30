// lib/widgets/post_list/list_card.dart

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/posts_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/time_ago.dart';
import '../../supabase_config.dart';
import '../../screens/posts/post_detail_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../pill_button.dart';
import '../menu_dropdown.dart';

class ListCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final ScrollController scrollController;
  final bool isHero;

  const ListCard({
    super.key,
    required this.post,
    required this.scrollController,
    this.isHero = false,
  });

  @override
  State<ListCard> createState() => _ListCardState();
}

class _ListCardState extends State<ListCard> {
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
            boxShadow:
                const [], // <--- Changed from [BoxShadow(...)] to empty list
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Author Meta Line
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
                      style: AppTextStyles.body(context, size: 12),
                    ),
                  ),
                  MenuDropdown(
                    post: widget.post,
                    scrollController: widget.scrollController,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 2. Middle Hashnode Section (Content Left, Thumbnail Right if Image Exists)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.post['title'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.heading(context, size: 18),
                        ),
                        const SizedBox(height: 8),
                        Text.rich(
                          TextSpan(
                            children: _parseInlineMarkdown(
                              widget.post['body'] ?? '',
                              AppTextStyles.body(context, size: 13),
                            ),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (imageUrl != null) ...[
                    const SizedBox(width: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 140,
                        height: 90,
                        child: AnimatedScale(
                          scale: isHovered ? 1.05 : 1.0,
                          duration: const Duration(milliseconds: 250),
                          child: Image.network(imageUrl, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              Divider(
                color: AppColors.border(context).withValues(alpha: 0.5),
                height: 1,
              ),
              const SizedBox(height: 12),

              // 3. Bottom Action Bar (Likes + Comments + Read More)
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
      final rawLinkText = match.group(8) ?? '';
      final cleanText = rawLinkText.replaceAll('*', '');

      spans.add(
        TextSpan(
          text: cleanText,
          style: baseStyle.copyWith(
            decoration: TextDecoration.underline,
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontStyle: rawLinkText.contains('*')
                ? FontStyle.italic
                : FontStyle.normal,
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

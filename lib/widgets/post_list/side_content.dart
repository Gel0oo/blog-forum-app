// lib/widgets/post_list/side_content.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/auth_provider.dart';
import '../../providers/posts_provider.dart';
import '../../providers/profile_provider.dart';
import '../../theme/app_theme.dart';
import '../../screens/posts/post_form_screen.dart';
import '../../screens/posts/post_detail_screen.dart';

class SideContent extends StatelessWidget {
  const SideContent({super.key});

  @override
  Widget build(BuildContext context) {
    final postsProvider = context.watch<PostsProvider>();
    final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;
    final profileProvider = context.watch<ProfileProvider>();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg + 56.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isLoggedIn) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 14,
              ),
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
                      const Icon(LucideIcons.handMetal, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Hello, ${profileProvider.profile?['name'] ?? 'there'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Ready to create a new post?',
                    style: AppTextStyles.body(context, size: 13),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PostFormScreen(),
                        ),
                      ),
                      icon: const Icon(
                        LucideIcons.plus,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Create Post',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text(
            'Top Discussions',
            style: AppTextStyles.heading(context, size: 20),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...(() {
            final sorted = List<Map<String, dynamic>>.from(postsProvider.posts)
              ..sort((a, b) {
                final aCount = (a['comments'] as List).isNotEmpty
                    ? a['comments'][0]['count']
                    : 0;
                final bCount = (b['comments'] as List).isNotEmpty
                    ? b['comments'][0]['count']
                    : 0;
                return bCount.compareTo(aCount);
              });
            return sorted.take(3).map((p) {
              final count = (p['comments'] as List).isNotEmpty
                  ? p['comments'][0]['count']
                  : 0;
              return Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.value),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.value),
                  hoverColor: AppColors.hover(context),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PostDetailScreen(post: p),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '•  ',
                            style: AppTextStyles.body(
                              context,
                              size: 14,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p['title'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.body(
                                  context,
                                  size: 14,
                                  color: AppColors.textPrimary(context),
                                ).copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '$count comments',
                                style: AppTextStyles.body(context, size: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            });
          })(),
        ],
      ),
    );
  }
}
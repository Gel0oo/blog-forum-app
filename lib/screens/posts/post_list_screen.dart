// lib/screens/posts/post_list_screen.dart

import 'dart:ui';
import '../../widgets/top_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/posts_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/time_ago.dart';
import '../../supabase_config.dart';
import 'post_form_screen.dart';
import 'post_detail_screen.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

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
    tabController = TabController(length: 2, vsync: this);
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
      shadcn.closeOverlay(context);
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
    final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;
    final profileProvider = context.watch<ProfileProvider>();

    final displayedPosts = List<Map<String, dynamic>>.from(postsProvider.posts);
    if (tabController.index == 1) {
      displayedPosts.sort((a, b) {
        final aLikes = (a['post_likes'] as List).length;
        final bLikes = (b['post_likes'] as List).length;
        return bLikes.compareTo(aLikes);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: const TopAppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal:
              280, // No vertical padding on outer wrapper so scrollview touches AppBar
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LEFT COLUMN: Single Scrollable Feed (TabBar + Cards)
            Expanded(
              flex: 5,
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.only(
                  top: AppSpacing
                      .md, // <--- 24px top gap that scrolls smoothly under AppBar
                  bottom: AppSpacing.lg,
                ),
                itemCount: displayedPosts.length + 2,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
                        splashBorderRadius: BorderRadius.circular(
                          AppRadius.value,
                        ),
                        overlayColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.hovered)
                              ? AppColors.textPrimary(
                                  context,
                                ).withValues(alpha: 0.08)
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
                        ],
                      ),
                    );
                  }

                  if (index == displayedPosts.length + 1) {
                    return postsProvider.hasMore
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : const SizedBox.shrink();
                  }

                  final post = displayedPosts[index - 1];
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
                              builder: (context) =>
                                  PostDetailScreen(post: post),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppRadius.value,
                            ),
                            border: Border.all(
                              color: AppColors.border(context),
                            ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          authorName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: AppColors.textPrimary(
                                              context,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${formatDate(post['created_at'])} • ${timeAgo(post['created_at'])}',
                                          style: AppTextStyles.body(
                                            context,
                                            size: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _PostMenuPopover(
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
                                _PostImage(url: images[0]['url']),
                              ],
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  _PillButton(
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
                                  _PillButton(
                                    icon: LucideIcons.messageCircle,
                                    label: '$commentCount',
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              PostDetailScreen(post: post),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _PillButton(
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
                },
              ),
            ),
            const SizedBox(width: AppSpacing.lg),

            // RIGHT COLUMN: Sidebar (Top aligned flush with first post card)
            Expanded(
              flex: 2,
              child: Padding(
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
                                Text(
                                  'Hello, ${profileProvider.profile?['name'] ?? 'there'}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: AppColors.textPrimary(context),
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
                                    builder: (context) =>
                                        const PostFormScreen(),
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
                      final sorted =
                          List<Map<String, dynamic>>.from(postsProvider.posts)
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
                            borderRadius: BorderRadius.circular(
                              AppRadius.value,
                            ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p['title'],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style:
                                              AppTextStyles.body(
                                                context,
                                                size: 14,
                                                color: AppColors.textPrimary(
                                                  context,
                                                ),
                                              ).copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        Text(
                                          '$count comments',
                                          style: AppTextStyles.body(
                                            context,
                                            size: 12,
                                          ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// lib/screens/posts/post_list_screen.dart (Replace _PillButton)

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final bool filled;
  final VoidCallback? onTap;

  const _PillButton({
    required this.icon,
    this.label,
    this.filled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = filled ? Colors.white : null;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: iconColor),
        if (label != null) ...[
          const SizedBox(width: 6),
          Text(
            label!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: filled ? Colors.white : null,
              height:
                  1.0, // prevents the font's own line-height from pushing text off-center
            ),
          ),
        ],
      ],
    );

    final button = filled
        ? shadcn.PrimaryButton(
            density: shadcn.ButtonDensity.dense,
            onPressed: onTap,
            child: content,
          )
        : shadcn.OutlineButton(
            density: shadcn.ButtonDensity.dense,
            onPressed: onTap,
            child: content,
          );

    return SizedBox(height: 32, child: button);
  }
}

class _PostImage extends StatefulWidget {
  final String url;
  const _PostImage({required this.url});

  @override
  State<_PostImage> createState() => _PostImageState();
}

class _PostImageState extends State<_PostImage> {
  double? aspectRatio;

  @override
  void initState() {
    super.initState();
    Image.network(widget.url).image
        .resolve(const ImageConfiguration())
        .addListener(
          ImageStreamListener((info, _) {
            if (mounted) {
              setState(
                () => aspectRatio = info.image.width / info.image.height,
              );
            }
          }),
        );
  }

  @override
  Widget build(BuildContext context) {
    if (aspectRatio == null) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (aspectRatio! >= 0.75) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AspectRatio(
          aspectRatio: aspectRatio!.clamp(0.5, 2.2),
          child: Image.network(widget.url, fit: BoxFit.cover),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 400,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Transform.scale(
              scale: 1.2,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: 25,
                  sigmaY: 25,
                  tileMode: TileMode.clamp,
                ),
                child: Image.network(widget.url, fit: BoxFit.cover),
              ),
            ),
            Container(color: Colors.black.withValues(alpha: 0.15)),
            Center(child: Image.network(widget.url, fit: BoxFit.contain)),
          ],
        ),
      ),
    );
  }
}

// lib/screens/posts/post_list_screen.dart (Replace _PostMenuPopover)

class _PostMenuPopover extends StatefulWidget {
  final String postBody;
  final ScrollController? scrollController;
  const _PostMenuPopover({
    required this.postBody,
    this.scrollController,
  });

  @override
  State<_PostMenuPopover> createState() => _PostMenuPopoverState();
}

class _PostMenuPopoverState extends State<_PostMenuPopover> {
  shadcn.OverlayCompleter? _overlayCompleter; // <--- Type is OverlayCompleter

  @override
  void initState() {
    super.initState();
    widget.scrollController?.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    _overlayCompleter?.close();
    super.dispose();
  }

  void _onScroll() {
    if (_overlayCompleter != null) {
      _overlayCompleter?.close(); // Closes popover on scroll
      _overlayCompleter = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (btnContext) {
        return IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          style: IconButton.styleFrom(hoverColor: AppColors.hover(context)),
          icon: Icon(
            LucideIcons.moreHorizontal,
            size: 20,
            color: AppColors.textSecondary(context),
          ),
          onPressed: () {
            _overlayCompleter = shadcn.showDropdown(
              context: btnContext,
              anchorAlignment: Alignment.bottomRight,
              alignment: Alignment.topRight,
              builder: (context) {
                return TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 5000),
                  curve: Curves.easeInOut,
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.92 + (0.08 * value),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: shadcn.DropdownMenu(
                    children: [
                      shadcn.MenuButton(
                        leading: const Icon(LucideIcons.copy, size: 18),
                        onPressed: (context) {
                          Clipboard.setData(ClipboardData(text: widget.postBody));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Copied to clipboard'),
                            ),
                          );
                          _overlayCompleter?.close();
                          _overlayCompleter = null;
                        },
                        child: const Text('Copy text'),
                      ),
                      shadcn.MenuButton(
                        leading: const Icon(LucideIcons.flag, size: 18),
                        onPressed: (context) {
                          _overlayCompleter?.close();
                          _overlayCompleter = null;
                        },
                        child: const Text('Report'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
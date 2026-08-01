// lib/widgets/menu_dropdown.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import '../providers/posts_provider.dart';
import '../supabase_config.dart';
import '../theme/app_theme.dart';
import '../screens/posts/post_form_screen.dart';

class MenuDropdown extends StatefulWidget {
  final Map<String, dynamic>? post;
  final ScrollController? scrollController;

  const MenuDropdown({super.key, this.post, this.scrollController});

  @override
  State<MenuDropdown> createState() => _MenuDropdownState();
}

class _MenuDropdownState extends State<MenuDropdown> {
  shadcn.OverlayCompleter? _overlayCompleter;

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
      _overlayCompleter?.close();
      _overlayCompleter = null;
    }
  }

  Future<void> _confirmDelete() async {
    _overlayCompleter?.close();
    _overlayCompleter = null;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground(dialogContext),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.border(dialogContext)),
        ),
        title: Text(
          'Delete Post',
          style: AppTextStyles.heading(dialogContext, size: 18),
        ),
        content: Text(
          'Are you sure you want to delete this post?',
          style: AppTextStyles.body(dialogContext, size: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary(dialogContext)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.post != null && mounted) {
      await context.read<PostsProvider>().deletePost(widget.post!['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = supabase.auth.currentUser?.id;
    final isOwner =
        widget.post != null && widget.post!['user_id'] == currentUserId;

    if (!isOwner) {
      return const SizedBox.shrink();
    }

    final isMobile = MediaQuery.of(context).size.width < 600;

    // Mobile Route
    if (isMobile) {
      return PopupMenuButton<String>(
        tooltip: 'Post Options',
        padding: EdgeInsets.zero,
        position: PopupMenuPosition.under,
        offset: const Offset(0, 4),
        color: AppColors.cardBackground(context),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.border(context)),
        ),
        onSelected: (value) {
          if (value == 'edit') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PostFormScreen(existingPost: widget.post),
              ),
            );
          } else if (value == 'delete') {
            _confirmDelete();
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(
                  LucideIcons.pencil,
                  size: 16,
                  color: AppColors.textPrimary(context),
                ),
                const SizedBox(width: 10),
                Text(
                  'Edit post',
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(LucideIcons.trash2, size: 16, color: Colors.redAccent),
                SizedBox(width: 10),
                Text(
                  'Delete post',
                  style: TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Icon(
            LucideIcons.moreHorizontal,
            size: 20,
            color: AppColors.textSecondary(context),
          ),
        ),
      );
    }

    // Desktop Route
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
                return MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(disableAnimations: false),
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeInOutCubic,
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.92 + (0.08 * value),
                        child: Opacity(opacity: value, child: child),
                      );
                    },
                    child: shadcn.DropdownMenu(
                      children: [
                        shadcn.MenuButton(
                          leading: const Icon(LucideIcons.pencil, size: 18),
                          onPressed: (context) {
                            _overlayCompleter?.close();
                            _overlayCompleter = null;
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    PostFormScreen(existingPost: widget.post),
                              ),
                            );
                          },
                          child: const Text('Edit post'),
                        ),
                        shadcn.MenuButton(
                          leading: const Icon(
                            LucideIcons.trash2,
                            size: 18,
                            color: Colors.redAccent,
                          ),
                          onPressed: (_) => _confirmDelete(),
                          child: const Text(
                            'Delete post',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
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

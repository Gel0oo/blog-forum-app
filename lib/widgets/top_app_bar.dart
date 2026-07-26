// lib/widgets/top_app_bar.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/posts_provider.dart';
import '../theme/app_theme.dart';
import '../screens/profile/profile_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TopAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TopAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;
    final profileProvider = context.watch<ProfileProvider>();

    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: preferredSize.height,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      title: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset('assets/logo.svg', width: 64, height: 64),
              const SizedBox(width: 8),
              Text(
                'Postly',
                style: GoogleFonts.getFont(
                  'Fira Sans',
                  fontSize: 26,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(width: 500, height: 50, child: const _SearchField()),
          const Spacer(),
        ],
      ),
      backgroundColor: AppColors.background(context),
      elevation: 0,
      shape: Border(
        bottom: BorderSide(color: AppColors.border(context), width: 1),
      ),
      actions: [
        if (isLoggedIn)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: _ProfileMenu(
              avatarUrl: profileProvider.profile?['avatar_url'],
            ),
          )
        else ...[
          // Login Pill
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: shadcn.PrimaryButton(
              density: shadcn
                  .ButtonDensity
                  .normal, // <--- Manages compact button height without clipping text
              onPressed: () => context.go('/login'),
              child: const Text(
                'Login',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          // Register Pill (Secondary Button)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: shadcn.SecondaryButton(
              density: shadcn
                  .ButtonDensity
                  .normal, // <--- Manages compact button height without clipping text
              onPressed: () => context.go('/register'),
              child: const Text(
                'Register',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField();

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<String> _currentSuggestions = [];

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Map<String, Map<String, dynamic>> _titleToPost(BuildContext context) {
    final posts = context.read<PostsProvider>().posts;
    return {for (final p in posts) p['title'] as String: p};
  }

  void _updateSuggestions(String value) {
    if (value.trim().isEmpty) {
      context.read<PostsProvider>().searchPosts('');
      setState(() => _currentSuggestions = []);
      return;
    }
    final titles = _titleToPost(context).keys.toList();
    final matches = titles
        .where((t) => t.toLowerCase().contains(value.toLowerCase()))
        .toList();
    setState(() => _currentSuggestions = matches);
  }

  void _handleSubmit(String value) {
    context.read<PostsProvider>().searchPosts(value);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: shadcn.AutoComplete(
        suggestions: _currentSuggestions,
        child: shadcn.TextField(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _updateSuggestions,
          onSubmitted: _handleSubmit,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border(context)),
          placeholder: Text(
            'Search posts...',
            style: AppTextStyles.body(context, size: 13),
          ),
          features: [
            shadcn.InputFeature.leading(
              Row(
                children: [
                  Icon(
                    LucideIcons.search,
                    size: 16,
                    color: AppColors.textSecondary(context),
                  ),
                ],
              ),
            ),
            const shadcn.InputFeature.clear(),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  final String? avatarUrl;
  const _ProfileMenu({super.key, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (avatarContext) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              shadcn.showDropdown(
                context: avatarContext,
                anchorAlignment: Alignment.bottomRight,
                alignment: Alignment.topRight,
                builder: (context) {
                  return TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeInOutCubic,
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.9 + (0.08 * value),
                        child: Opacity(opacity: value, child: child),
                      );
                    },
                    child: shadcn.DropdownMenu(
                      children: [
                        shadcn.MenuButton(
                          leading: const Icon(LucideIcons.user, size: 18),
                          onPressed: (context) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const ProfileScreen(),
                              ),
                            );
                          },
                          child: const Text('Profile'),
                        ),
                        shadcn.MenuButton(
                          leading: const Icon(LucideIcons.logOut, size: 18),
                          onPressed: (context) {
                            context.read<AuthProvider>().signOut();
                          },
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            child: CircleAvatar(
              radius: 16,
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl!)
                  : null,
              child: avatarUrl == null
                  ? const Icon(LucideIcons.user, size: 16)
                  : null,
            ),
          ),
        );
      },
    );
  }
}

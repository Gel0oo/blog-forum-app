// lib/widgets/top_app_bar.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import 'package:flutter_svg/flutter_svg.dart';
import 'user_avatar.dart';
import '../supabase_config.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/posts_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/posts/post_form_screen.dart';
import 'mobile/mobile_top_app_bar.dart';

class TopAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TopAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).size.width < 650) {
      return const MobileTopAppBar();
    }
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
          GestureDetector(
            onTap: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
              context.go('/');
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Row(
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
            ),
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
        if (isLoggedIn) ...[
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: shadcn.PrimaryButton(
              density: shadcn.ButtonDensity.normal,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const PostFormScreen()),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.plus, size: 16, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'Create Post',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: _ProfileMenu(
              avatarUrl: profileProvider.profile?['avatar_url'],
            ),
          ),
        ] else ...[
          // Login Pill
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: shadcn.PrimaryButton(
              density: shadcn.ButtonDensity.normal,
              onPressed: () => showDialog(
                context: context,
                barrierColor: Colors.transparent,
                builder: (_) => const LoginScreen(),
              ),
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
          // Register Pill
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: shadcn.SecondaryButton(
              density: shadcn.ButtonDensity.normal,
              onPressed: () => showDialog(
                context: context,
                barrierColor: Colors.transparent,
                builder: (_) => const RegisterScreen(),
              ),
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
  List<String> _currentSuggestions = [];

  Future<void> _fetchSuggestions(String query) async {
    try {
      final response = await supabase
          .from('posts')
          .select('title')
          .ilike('title', '%$query%')
          .limit(5);

      final matches = (response as List)
          .map((row) => row['title'] as String)
          .toSet()
          .toList();

      if (mounted) {
        setState(() => _currentSuggestions = matches);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Autocomplete<String>(
        optionsBuilder: (textEditingValue) {
          final query = textEditingValue.text.trim();
          if (query.isEmpty) {
            context.read<PostsProvider>().searchPosts('');
            return const Iterable<String>.empty();
          }
          _fetchSuggestions(query);
          return _currentSuggestions;
        },
        onSelected: (selection) {
          context.read<PostsProvider>().searchPosts(selection);
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 500,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border(context)),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      hoverColor: AppColors.hover(context),
                      onTap: () => onSelected(option),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Text(
                          option,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          return shadcn.TextField(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            controller: controller,
            focusNode: focusNode,
            onSubmitted: (value) {
              context.read<PostsProvider>().searchPosts(value);
              onFieldSubmitted();
            },
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.border(context)),
            placeholder: Text(
              'Search...',
              style: AppTextStyles.body(context, size: 12),
            ),
            features: [
              shadcn.InputFeature.leading(
                Row(
                  children: [
                    Icon(
                      LucideIcons.search,
                      size: 14,
                      color: AppColors.textSecondary(context),
                    ),
                  ],
                ),
              ),
              const shadcn.InputFeature.clear(),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  final String? avatarUrl;
  const _ProfileMenu({this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark(context);

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
                          leading: Icon(
                            isDark ? LucideIcons.moon : LucideIcons.sun,
                            size: 18,
                          ),
                          trailing: IgnorePointer(
                            child: shadcn.Switch(
                              value: isDark,
                              onChanged: (_) {},
                            ),
                          ),
                          onPressed: (context) {
                            themeProvider.toggleTheme(!isDark);
                          },
                          child: Text(isDark ? 'Dark Mode' : 'Light Mode'),
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
            child: UserAvatar(avatarUrl: avatarUrl, radius: 16),
          ),
        );
      },
    );
  }
}

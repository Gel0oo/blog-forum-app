// lib/widgets/top_app_bar.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../theme/app_theme.dart';
import '../screens/profile/profile_screen.dart';

class TopAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TopAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;
    final profileProvider = context.watch<ProfileProvider>();

    return AppBar(
      toolbarHeight: preferredSize.height,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Text(
        'StayPosted',
        style: GoogleFonts.getFont(
          'Fira Sans',
          fontSize: 26,
          color: AppColors.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
      backgroundColor: AppColors.background(context),
      elevation: 0,
      shape: Border(
        bottom: BorderSide(
          color: AppColors.border(context),
          width: 1,
        ),
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
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Login'),
          ),
          TextButton(
            onPressed: () => context.go('/register'),
            child: const Text('Register'),
          ),
        ],
      ],
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  final String? avatarUrl;
  const _ProfileMenu({this.avatarUrl});

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
                    duration: const Duration(milliseconds: 5000),
                    curve: Curves.easeInOut,
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.9 + (0.08 * value),
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
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
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl!) : null,
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
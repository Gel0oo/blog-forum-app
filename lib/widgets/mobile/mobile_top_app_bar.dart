// lib/widgets/mobile/mobile_top_app_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../user_avatar.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/posts/post_form_screen.dart';
import '../../screens/profile/profile_screen.dart';

class MobileTopAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MobileTopAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(42);

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;
    final profileProvider = context.watch<ProfileProvider>();

    return Container(
      height: preferredSize.height,
      decoration: BoxDecoration(
        color: AppColors.background(context),
        border: Border(
          bottom: BorderSide(color: AppColors.border(context), width: 1),
        ),
      ),
      padding: const EdgeInsets.only(right: 12, left: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: SvgPicture.asset('assets/logo.svg', width: 64, height: 64),
          ),
          const Spacer(),
          if (isLoggedIn) ...[
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: Icon(
                LucideIcons.pencil,
                size: 18,
                color: AppColors.textPrimary(context),
              ),
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const PostFormScreen())),
            ),
            const SizedBox(width: 8),
            _MobileProfileMenu(
              avatarUrl: profileProvider.profile?['avatar_url'],
            ),
          ] else ...[
            shadcn.PrimaryButton(
              density: shadcn.ButtonDensity.dense,
              onPressed: () => showDialog(
                context: context,
                barrierColor: Colors.transparent,
                builder: (_) => const LoginScreen(),
              ),
              child: const Text('Login', style: TextStyle(fontSize: 11)),
            ),
            const SizedBox(width: 6),
            shadcn.SecondaryButton(
              density: shadcn.ButtonDensity.dense,
              onPressed: () => showDialog(
                context: context,
                barrierColor: Colors.transparent,
                builder: (_) => const RegisterScreen(),
              ),
              child: const Text('Register', style: TextStyle(fontSize: 11)),
            ),
          ],
        ],
      ),
    );
  }
}

class _MobileProfileMenu extends StatelessWidget {
  final String? avatarUrl;
  const _MobileProfileMenu({this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark(context);

    return PopupMenuButton<String>(
      tooltip: 'Profile Menu',
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under, // <-- Opens BELOW the avatar
      offset: const Offset(0, 6),
      color: AppColors.cardBackground(context),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border(context)),
      ),
      onSelected: (value) {
        if (value == 'profile') {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
        } else if (value == 'theme') {
          themeProvider.toggleTheme(!isDark);
        } else if (value == 'logout') {
          context.read<AuthProvider>().signOut();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(
                LucideIcons.user,
                size: 18,
                color: AppColors.textPrimary(context),
              ),
              const SizedBox(width: 10),
              Text(
                'Profile',
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'theme',
          child: Row(
            children: [
              Icon(
                isDark ? LucideIcons.moon : LucideIcons.sun,
                size: 18,
                color: AppColors.textPrimary(context),
              ),
              const SizedBox(width: 10),
              Text(
                isDark ? 'Dark Mode' : 'Light Mode',
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          child: const Row(
            children: [
              Icon(LucideIcons.logOut, size: 18, color: Colors.redAccent),
              SizedBox(width: 10),
              Text(
                'Logout',
                style: TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
      child: UserAvatar(avatarUrl: avatarUrl, radius: 14),
    );
  }
}

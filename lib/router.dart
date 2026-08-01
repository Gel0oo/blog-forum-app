// lib/router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/posts/post_list_screen.dart';
import 'screens/posts/post_detail_screen.dart';

/// Reusable Right-to-Left Slide Page Route for Navigator.push
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  SlidePageRoute({required this.page})
    : super(
        opaque: false,
        barrierColor: const Color(0xFF16191C),
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(1.0, 0.0), // Slide in from right
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
      );
}

GoRouter buildRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final loggedIn = authProvider.isLoggedIn;
      final onAuthPage =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (loggedIn && onAuthPage) return '/';
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return Stack(
            children: [
              const PostListScreen(),
              if (state.matchedLocation == '/login') const LoginScreen(),
              if (state.matchedLocation == '/register') const RegisterScreen(),
            ],
          );
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const SizedBox.shrink(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const SizedBox.shrink(),
          ),
          GoRoute(
            path: '/register',
            builder: (context, state) => const SizedBox.shrink(),
          ),
        ],
      ),
      GoRoute(
        path: '/post/:id',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            barrierColor: const Color(0xFF16191C),
            child: Container(
              color: const Color(0xFF16191C),
              child: PostDetailScreen(postId: state.pathParameters['id']),
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  final opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                  );
                  final slide =
                      Tween<Offset>(
                        begin: const Offset(0.12, 0.0), // Subtle 12% slide in
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      );

                  return FadeTransition(
                    opacity: opacity,
                    child: SlideTransition(position: slide, child: child),
                  );
                },
          );
        },
      ),
    ],
  );
}

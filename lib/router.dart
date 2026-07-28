// lib/router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/posts/post_list_screen.dart';
import 'screens/posts/post_detail_screen.dart';

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
          GoRoute(path: '/', builder: (context, state) => const SizedBox.shrink()),
          GoRoute(path: '/login', builder: (context, state) => const SizedBox.shrink()),
          GoRoute(path: '/register', builder: (context, state) => const SizedBox.shrink()),
        ],
      ),
      GoRoute(
        path: '/post/:id',
        builder: (context, state) => PostDetailScreen(postId: state.pathParameters['id']),
      ),
    ],
  );
}
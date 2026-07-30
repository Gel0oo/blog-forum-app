// lib/main.dart

import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'supabase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/posts_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/theme_provider.dart';
import 'router.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  GoRouter? _router;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PostsProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Builder(
        builder: (context) {
          final authProvider = context.watch<AuthProvider>();
          final themeProvider = context.watch<ThemeProvider>();
          _router ??= buildRouter(authProvider);

          return ShadcnApp.router(
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              colorScheme: ColorSchemes.slate(
                ThemeMode.light,
              ).copyWith(
                primary: () => AppColors.primary,
                ring: () => AppColors.primary,
                background: () => const Color(0xFFF9FAFB), // #f9fafb
                card: () => const Color(0xFFFFFFFF),       // #ffffff
                border: () => const Color(0xFFD1D4D9),     // #d1d4d9
              ),
              scaling: 1.15,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorSchemes.slate(
                ThemeMode.dark,
              ).copyWith(
                primary: () => AppColors.primary,
                ring: () => AppColors.primary,
                background: () => const Color(0xFF16191C), // #16191c
                card: () => const Color(0xFF1C2024),       // #1c2024
                border: () => const Color(0xFF2F3338),     // #2f3338
              ),
              scaling: 1.15,
            ),
            routerConfig: _router!,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: false),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
// lib/main.dart

import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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

          return ShadcnApp.router(
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              colorScheme: ColorSchemes.slate(
                ThemeMode.light,
              ).copyWith(primary: () => AppColors.primary),
              scaling: 1.15,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorSchemes.slate(
                ThemeMode.dark,
              ).copyWith(primary: () => AppColors.primary, ring: () => AppColors.primary),
              scaling: 1.15,
            ),
            routerConfig: buildRouter(authProvider),
            builder: (context, child) {
              // Force animations on regardless of the OS "reduce motion" setting,
              // so every visitor sees the same popover/transition behavior you do.
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

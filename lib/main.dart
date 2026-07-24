// lib/main.dart

import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import 'supabase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/posts_provider.dart';
import 'providers/profile_provider.dart';
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
      ],
      child: Builder(
        builder: (context) {
          final authProvider = context.watch<AuthProvider>();
          return ShadcnApp.router(
            debugShowCheckedModeBanner: false,
            themeMode: ThemeMode.system, // Uses built-in OS light/dark modes
            theme: ThemeData(
              colorScheme: ColorSchemes.slate(ThemeMode.light).copyWith(
                primary: () => AppColors.primary, // ValueGetter<Color> function
              ),
              scaling: 1.15,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorSchemes.slate(ThemeMode.dark).copyWith(
                primary: () => AppColors.primary, // ValueGetter<Color> function
              ),
              scaling: 1.15,
            ),
            routerConfig: buildRouter(authProvider),
          );
        },
      ),
    );
  }
}
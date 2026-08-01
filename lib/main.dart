// lib/main.dart

import 'package:flutter/material.dart' as material;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'supabase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/posts_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/theme_provider.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// Global Right-to-Left Slide Page Transition for all MaterialPageRoutes
class _SlideTransitionsBuilder extends material.PageTransitionsBuilder {
  const _SlideTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    material.PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0.12, 0.0), // Subtle 12% slide in
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

    return FadeTransition(
      opacity: opacityAnimation,
      child: SlideTransition(position: slideAnimation, child: child),
    );
  }
}

class AppScrollBehavior extends material.MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.trackpad,
  };

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return Scrollbar(controller: details.controller, child: child);
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
}

class SmoothScrollController extends ScrollController {
  SmoothScrollController({
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
  });

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return _SmoothScrollPosition(
      physics: physics,
      context: context,
      initialPixels: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
    );
  }
}

class _SmoothScrollPosition extends ScrollPositionWithSingleContext {
  _SmoothScrollPosition({
    required super.physics,
    required super.context,
    super.initialPixels,
    super.keepScrollOffset,
    super.oldPosition,
    super.debugLabel,
  });

  double _velocity = 0.0;
  DateTime? _lastScroll;

  @override
  void pointerScroll(double delta) {
    if (delta == 0.0) return;

    final now = DateTime.now();
    if (_lastScroll != null &&
        now.difference(_lastScroll!).inMilliseconds < 140) {
      _velocity = (_velocity + delta * 1.1).clamp(-700.0, 700.0);
    } else {
      _velocity = delta * 1.0;
    }
    _lastScroll = now;

    final target = (pixels + _velocity).clamp(minScrollExtent, maxScrollExtent);
    if (target == pixels) return;

    animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  GoRouter? _router;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      await initSupabase();
    } catch (e) {
      debugPrint('Supabase initialization error: $e');
    } finally {
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Container(
          color: const Color(0xFF16191C),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SpinKitThreeBounce(color: Color(0xFF6366F1), size: 32.0),
                const SizedBox(height: 16),
                Text(
                  'Loading Postly...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                    fontFamily: 'sans-serif',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
              colorScheme: ColorSchemes.slate(ThemeMode.light).copyWith(
                primary: () => AppColors.primary,
                ring: () => AppColors.primary,
                background: () => const Color(0xFFFFFFFF),
                card: () => const Color(0xFFFFFFFF),
                border: () => const material.Color.fromARGB(255, 211, 212, 214),
                popover: () => const Color(0xFFFFFFFF),
                popoverForeground: () => const material.Color.fromARGB(255, 229, 230, 231),
              ),
              scaling: 1.15,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorSchemes.slate(ThemeMode.dark).copyWith(
                primary: () => AppColors.primary,
                ring: () => AppColors.primary,
                background: () => const Color(0xFF16191C),
                card: () => const Color(0xFF1C2024),
                border: () => const Color(0xFF2F3338),
                popover: () => const Color(0xFF25292E),
                popoverForeground: () => const Color(0xFFE3E4E6),
              ),
              scaling: 1.15,
            ),
            routerConfig: _router!,
            builder: (context, child) {
              final materialTheme = material.Theme.of(context).copyWith(
                pageTransitionsTheme: material.PageTransitionsTheme(
                  builders: {
                    material.TargetPlatform.android:
                        const _SlideTransitionsBuilder(),
                    material.TargetPlatform.iOS:
                        const _SlideTransitionsBuilder(),
                    material.TargetPlatform.macOS:
                        const _SlideTransitionsBuilder(),
                    material.TargetPlatform.windows:
                        const _SlideTransitionsBuilder(),
                    material.TargetPlatform.linux:
                        const _SlideTransitionsBuilder(),
                    material.TargetPlatform.fuchsia:
                        const _SlideTransitionsBuilder(),
                  },
                ),
              );

              return MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: false),
                child: ScrollConfiguration(
                  behavior: AppScrollBehavior(),
                  child: PrimaryScrollController(
                    controller: SmoothScrollController(),
                    child: material.Theme(
                      data: materialTheme,
                      child: Container(
                        child: child!,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

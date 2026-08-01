// lib/providers/theme_provider.dart
import 'package:web/web.dart' as web;
import 'package:shadcn_flutter/shadcn_flutter.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    final saved = web.window.localStorage.getItem(_key);
    if (saved == 'dark') _themeMode = ThemeMode.dark;
    if (saved == 'light') _themeMode = ThemeMode.light;
  }

  bool isDark(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    web.window.localStorage.setItem(_key, isDark ? 'dark' : 'light');
    notifyListeners();
  }
}
// lib/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

class AppColors {
  static const primary = Color(0xFF5B5CEB);

  // Dynamic getters hooked directly into Shadcn ColorScheme
  static Color background(BuildContext context) =>
      shadcn.Theme.of(context).colorScheme.background;

  static Color cardBackground(BuildContext context) =>
      shadcn.Theme.of(context).colorScheme.card;

  static Color textPrimary(BuildContext context) =>
      shadcn.Theme.of(context).colorScheme.foreground;

  static Color textSecondary(BuildContext context) =>
      shadcn.Theme.of(context).colorScheme.mutedForeground;

  static Color border(BuildContext context) =>
      shadcn.Theme.of(context).colorScheme.border;

  static Color hover(BuildContext context) =>
    AppColors.textPrimary(context).withValues(alpha: 0.05);
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const between = 28.0;
  static const xl = 32.0;
}

class AppRadius {
  static const value = 7.0;
}

class AppTextStyles {
  static TextStyle heading(BuildContext context, {double size = 20, Color? color}) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: color ?? AppColors.textPrimary(context),
      letterSpacing: -0.2,
    );
  }

  static TextStyle body(BuildContext context, {double size = 14, Color? color}) {
    return GoogleFonts.nunito(
      fontSize: size,
      fontWeight: FontWeight.w400,
      color: color ?? AppColors.textSecondary(context),
    );
  }
}
// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/profile_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool showPassword = false;
  String? error;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => error = 'Please enter both email and password.');
      return;
    }

    setState(() {
      error = null;
      isLoading = true;
    });

    try {
      await context.read<AuthProvider>().signIn(email, password);
      if (mounted) {
        await context.read<ProfileProvider>().fetchProfile(); // Instantly loads avatar & name
        if (mounted) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            context.go('/');
          }
        }
      }
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('invalid login credentials') ||
          errStr.contains('invalid_credentials')) {
        setState(() => error = 'Invalid email or password.');
      } else {
        setState(() => error = 'Failed to log in. Please check your details.');
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.5),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBackground(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border(context)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      'Log In',
                      style: AppTextStyles.heading(context, size: 22),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                        icon: Icon(
                          LucideIcons.x,
                          size: 20,
                          color: AppColors.textSecondary(context),
                        ),
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            context.go('/');
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Pretty easy, right? Just enter your email and password to log in.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(context, size: 12),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: emailController,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary(context),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Email *',
                    hintStyle: AppTextStyles.body(context, size: 13),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.cardBackground(context),
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    suffixIcon: const SizedBox(width: 40, height: 40),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: !showPassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => handleLogin(),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary(context),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Password *',
                    hintStyle: AppTextStyles.body(context, size: 13),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.cardBackground(context),
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    suffixIcon: SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          showPassword
                              ? LucideIcons.eyeOff
                              : LucideIcons.eye,
                          size: 16,
                          color: AppColors.textSecondary(context),
                        ),
                        onPressed: () =>
                            setState(() => showPassword = !showPassword),
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (error != null) ...[
                  Text(
                    error!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'New to Postly? ',
                      style: AppTextStyles.body(context, size: 13),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                          showDialog(
                            context: context,
                            barrierColor: Colors.transparent,
                            builder: (_) => const RegisterScreen(),
                          );
                        } else {
                          context.go('/register');
                        }
                      },
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 42,
                  child: shadcn.PrimaryButton(
                    onPressed: isLoading ? null : handleLogin,
                    child: Center(
                      child: Text(
                        isLoading ? 'Logging in...' : 'Log In',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
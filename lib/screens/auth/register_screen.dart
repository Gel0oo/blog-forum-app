// lib/screens/auth/register_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/profile_provider.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool showPassword = false;
  String? error;
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> handleRegister() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => error = 'Please fill in all fields.');
      return;
    }

    if (password.length < 6) {
      setState(() => error = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      error = null;
      isLoading = true;
    });

    try {
      await context.read<AuthProvider>().signUp(
            email,
            password,
            name: name,
          );
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
      setState(() => error = 'Registration failed. Please try again.');
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
                      'Sign Up',
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
                  'Takes a couple of seconds to register :)',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(context, size: 12),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary(context),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Display Name *',
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
                  onSubmitted: (_) => handleRegister(),
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
                      'Already a Postly user? ',
                      style: AppTextStyles.body(context, size: 13),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                          showDialog(
                            context: context,
                            barrierColor: Colors.transparent,
                            builder: (_) => const LoginScreen(),
                          );
                        } else {
                          context.go('/login');
                        }
                      },
                      child: const Text(
                        'Log In',
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
                    onPressed: isLoading ? null : handleRegister,
                    child: Center(
                      child: Text(
                        isLoading ? 'Signing up...' : 'Sign Up',
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
// lib/screens/auth/register_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String? error;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> handleRegister() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => error = 'Please enter both email and password.');
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
      await context.read<AuthProvider>().signUp(email, password);
      if (mounted) context.go('/');
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
                // Header: Title centered on exact same row as X button
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
                        onPressed: () => context.go('/'),
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
                // Email
                shadcn.TextField(
                  controller: emailController,
                  borderRadius: BorderRadius.circular(999),
                  placeholder: Text(
                    'Email *',
                    style: AppTextStyles.body(context, size: 13),
                  ),
                  features: const [shadcn.InputFeature.clear()],
                ),
                const SizedBox(height: 12),
                // Password
                shadcn.TextField(
                  controller: passwordController,
                  obscureText: true,
                  borderRadius: BorderRadius.circular(999),
                  placeholder: Text(
                    'Password *',
                    style: AppTextStyles.body(context, size: 13),
                  ),
                  features: const [shadcn.InputFeature.clear()],
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
                // Log In Switch Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already a Postly user? ',
                      style: AppTextStyles.body(context, size: 13),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/login'),
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
                // Centered Sign Up Button
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
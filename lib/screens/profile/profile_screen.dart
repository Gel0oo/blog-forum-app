// lib/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import '../../providers/profile_provider.dart';
import '../../theme/app_theme.dart';
import '../../supabase_config.dart';
import '../../widgets/top_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final nameController = TextEditingController();
  bool isEditingName = false;
  bool isSaving = false;
  String? error;
  String? successMessage; // <--- Inline success message state

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<ProfileProvider>().fetchProfile();
      if (!mounted) return;
      final profile = context.read<ProfileProvider>().profile;
      if (profile != null) {
        nameController.text = profile['name'] ?? '';
      }
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      await context.read<ProfileProvider>().updateAvatar(bytes);
      setState(() => successMessage = 'Avatar updated successfully.');
    }
  }

  Future<void> saveName() async {
    final newName = nameController.text.trim();
    if (newName.isEmpty) {
      setState(() {
        error = 'Display name cannot be empty.';
        successMessage = null;
      });
      return;
    }

    setState(() {
      isSaving = true;
      error = null;
      successMessage = null;
    });

    try {
      final userId = supabase.auth.currentUser!.id;

      final duplicateCheck = await supabase
          .from('profiles')
          .select('id')
          .ilike('name', newName)
          .neq('id', userId)
          .maybeSingle();

      if (duplicateCheck != null) {
        setState(() {
          error = 'This display name is already taken.';
          isSaving = false;
        });
        return;
      }

      if (!mounted) return;
      await context.read<ProfileProvider>().updateName(newName);

      if (mounted) {
        setState(() {
          isSaving = false;
          isEditingName = false;
          successMessage =
              'Profile updated successfully.'; // Set green success text
        });
      }
    } catch (e) {
      setState(() {
        error = 'Failed to update name: $e';
        isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final avatarUrl = profileProvider.profile?['avatar_url'];

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: const TopAppBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: SizedBox(
            width: 540,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        LucideIcons.arrowLeft,
                        size: 20,
                        color: AppColors.textPrimary(context),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Profile Settings',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Main Profile Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar Photo Section
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: pickAvatar,
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 48,
                                    backgroundImage: avatarUrl != null
                                        ? NetworkImage(avatarUrl)
                                        : null,
                                    child: avatarUrl == null
                                        ? Icon(
                                            LucideIcons.user,
                                            size: 44,
                                            color: AppColors.textSecondary(
                                              context,
                                            ),
                                          )
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.cardBackground(
                                            context,
                                          ),
                                          width: 2,
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(6),
                                      child: const Icon(
                                        LucideIcons.camera,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                shadcn.SecondaryButton(
                                  density: shadcn.ButtonDensity.dense,
                                  onPressed: pickAvatar,
                                  child: const Text('Change Photo'),
                                ),
                                if (avatarUrl != null) ...[
                                  const SizedBox(width: 8),
                                  shadcn.DestructiveButton(
                                    density: shadcn.ButtonDensity.dense,
                                    onPressed: () {
                                      context
                                          .read<ProfileProvider>()
                                          .removeAvatar();
                                      setState(
                                        () => successMessage =
                                            'Photo removed successfully.',
                                      );
                                    },
                                    child: const Text('Remove'),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Divider(color: AppColors.border(context)),
                      const SizedBox(height: 20),

                      // Display Name Section
                      Text(
                        'Display Name',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Name Field
                      shadcn.TextField(
                        controller: nameController,
                        readOnly: !isEditingName,
                        borderRadius: BorderRadius.circular(AppRadius.value),
                        border: Border.all(color: AppColors.border(context)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        placeholder: Text(
                          'Enter your name',
                          style: AppTextStyles.body(context, size: 14),
                        ),
                        features: [
                          shadcn.InputFeature.trailing(
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              icon: Icon(
                                isEditingName
                                    ? LucideIcons.x
                                    : LucideIcons.pencil,
                                size: 16,
                                color: AppColors.textSecondary(context),
                              ),
                              onPressed: () {
                                setState(() {
                                  if (isEditingName) {
                                    final profile = context
                                        .read<ProfileProvider>()
                                        .profile;
                                    nameController.text =
                                        profile?['name'] ?? '';
                                    error = null;
                                  }
                                  successMessage = null;
                                  isEditingName = !isEditingName;
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      // Inline Green Success Message directly below TextField
                      if (successMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          successMessage!,
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],

                      // Inline Red Error Message directly below TextField
                      if (error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          error!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],

                      // Save Changes Button (Visible ONLY when editing)
                      if (isEditingName) ...[
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: shadcn.PrimaryButton(
                            onPressed: isSaving ? null : saveName,
                            child: Center(
                              child: Text(
                                isSaving ? 'Saving...' : 'Save Changes',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
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
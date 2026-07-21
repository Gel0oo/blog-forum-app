import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/profile_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final nameController = TextEditingController();
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await context.read<ProfileProvider>().fetchProfile();
        final profile = context.read<ProfileProvider>().profile;
        if (profile != null && mounted) {
          nameController.text = profile['name'] ?? '';
        }
      }
    });
  }

  Future<void> pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await file.readAsBytes();
      await context.read<ProfileProvider>().updateAvatar(bytes);
    }
  }

  Future<void> saveName() async {
    setState(() => isSaving = true);
    await context.read<ProfileProvider>().updateName(nameController.text);
    setState(() => isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final avatarUrl = profileProvider.profile?['avatar_url'];

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: pickAvatar,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: avatarUrl != null
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl == null
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Tap avatar to change'),
                  if (avatarUrl != null)
                    TextButton(
                      onPressed: () =>
                          context.read<ProfileProvider>().removeAvatar(),
                      child: const Text('Remove photo'),
                    ),
                  const SizedBox(height: 24),
                  const SizedBox(height: 24),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isSaving ? null : saveName,
                    child: Text(isSaving ? 'Saving...' : 'Save Name'),
                  ),
                ],
              ),
            ),
    );
  }
}

// lib/screens/posts/post_form_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import '../../providers/posts_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/top_app_bar.dart';
import '../../widgets/post_form/form_markdown.dart';
import '../../widgets/post_form/form_imagepicker.dart';

class PostFormScreen extends StatefulWidget {
  final Map<String, dynamic>? existingPost;
  const PostFormScreen({super.key, this.existingPost});

  @override
  State<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen> {
  final titleController = TextEditingController();
  late final TextEditingController bodyController;
  final List<Uint8List> pickedImages = [];
  final List<String> imageIdsToDelete = [];
  List<dynamic> existingImages = [];
  String? error;
  bool isSubmitting = false;

  bool get isEditing => widget.existingPost != null;

  @override
  void initState() {
    super.initState();
    bodyController = MarkdownVisualController(context);
    if (isEditing) {
      titleController.text = widget.existingPost!['title'] ?? '';
      bodyController.text = widget.existingPost!['body'] ?? '';
      existingImages = List.from(widget.existingPost!['post_images'] ?? []);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    bodyController.dispose();
    super.dispose();
  }

  Future<void> pickImages() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage();
    for (final file in files) {
      final bytes = await file.readAsBytes();
      setState(() => pickedImages.add(bytes));
    }
  }

  Future<void> handleSubmit() async {
    if (titleController.text.trim().isEmpty) {
      setState(() => error = 'Title cannot be empty.');
      return;
    }

    setState(() {
      isSubmitting = true;
      error = null;
    });

    try {
      final provider = context.read<PostsProvider>();
      if (isEditing) {
        await provider.updatePost(
          postId: widget.existingPost!['id'],
          title: titleController.text.trim(),
          body: bodyController.text.trim(),
          newImageBytes: pickedImages,
          imageIdsToDelete: imageIdsToDelete,
        );
      } else {
        await provider.createPost(
          title: titleController.text.trim(),
          body: bodyController.text.trim(),
          imageBytes: pickedImages,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: const TopAppBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: SizedBox(
            width: 720,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      isEditing ? 'Edit Post' : 'Create Post',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Title Input
                shadcn.TextField(
                  controller: titleController,
                  borderRadius: BorderRadius.circular(AppRadius.value),
                  border: Border.all(color: AppColors.border(context)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  placeholder: Text(
                    'Title *',
                    style: AppTextStyles.body(context, size: 14),
                  ),
                  features: const [shadcn.InputFeature.clear()],
                ),
                const SizedBox(height: 16),

                // Markdown Editor Component
                FormMarkdown(controller: bodyController),
                const SizedBox(height: 16),

                // Image Picker Box
                FormImagePicker(
                  onTap: pickImages,
                  existingImages: existingImages,
                  pickedImages: pickedImages,
                  onRemoveExisting: (id) => setState(() {
                    imageIdsToDelete.add(id);
                    existingImages.removeWhere((img) => img['id'] == id);
                  }),
                  onRemovePicked: (index) =>
                      setState(() => pickedImages.removeAt(index)),
                ),
                const SizedBox(height: 16),

                if (error != null) ...[
                  Text(
                    error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                ],

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    shadcn.SecondaryButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    shadcn.PrimaryButton(
                      onPressed: isSubmitting ? null : handleSubmit,
                      child: Text(
                        isSubmitting
                            ? 'Posting...'
                            : (isEditing ? 'Save Changes' : 'Post'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
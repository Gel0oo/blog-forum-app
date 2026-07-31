// lib/screens/posts/post_form_screen.dart

import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import '../../utils/upload_image.dart';
import '../../providers/posts_provider.dart';
import '../../theme/app_theme.dart';
import '../../supabase_config.dart';
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
  late final MarkdownVisualController bodyController;
  final List<Uint8List> pickedImages = [];
  final List<String> imageIdsToDelete = [];
  List<dynamic> existingImages = [];
  String? error;
  bool isSubmitting = false;

  bool get isEditing => widget.existingPost != null;

  @override
  void initState() {
    super.initState();
    bodyController = MarkdownVisualController(
      context,
      pickedImages: pickedImages,
    );
    if (isEditing) {
      titleController.text = widget.existingPost!['title'] ?? '';
      bodyController.text = widget.existingPost!['body'] ?? '';
      existingImages = List.from(widget.existingPost!['post_images'] ?? []);
    }

    if (kIsWeb) {
      _listenForPastedImages();
    }
  }

  void _listenForPastedImages() {
    web.window.addEventListener(
      'flutter_image_pasted',
      (web.Event event) {
        try {
          final customEvent = event as web.CustomEvent;
          final dataUrl = (customEvent.detail as JSString).toDart;
          if (dataUrl.contains(',')) {
            final base64Str = dataUrl.split(',').last;
            final bytes = base64Decode(base64Str);
            if (mounted) {
              setState(() => pickedImages.add(bytes));
            }
          }
        } catch (_) {}
      }.toJS,
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    bodyController.dispose();
    super.dispose();
  }

  void _onToolbarImagePicked(Uint8List bytes) {
    setState(() => pickedImages.add(bytes));
    final index = pickedImages.length - 1;
    final token = 'IMAGE_$index';
    final markdownTag = '![Image]($token)';

    final currentText = bodyController.text;
    final selection = bodyController.selection;

    if (selection.isValid && selection.start >= 0) {
      final start = selection.start;
      final needsLeadingNewline =
          start > 0 && !currentText.substring(0, start).endsWith('\n\n');
      final prefix = needsLeadingNewline
          ? (currentText.substring(0, start).endsWith('\n') ? '\n' : '\n\n')
          : '';
      final insertion = '$prefix$markdownTag\n\n';

      final newText = currentText.replaceRange(start, selection.end, insertion);
      bodyController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start + insertion.length),
      );
    } else {
      final needsNewline =
          currentText.isNotEmpty && !currentText.endsWith('\n\n');
      final prefix = needsNewline
          ? (currentText.endsWith('\n') ? '\n' : '\n\n')
          : '';
      bodyController.text = '$currentText$prefix$markdownTag\n\n';
    }
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
      String finalBody = bodyController.text.trim();
      final userId = supabase.auth.currentUser!.id;

      for (var i = 0; i < pickedImages.length; i++) {
        final url = await uploadPostImage(userId, pickedImages[i], i);

        final token = 'IMAGE_$i';
        finalBody = finalBody.replaceAll('![$token]($token)', '![Image]($url)');
        finalBody = finalBody.replaceAll('($token)', '($url)');

        if (isEditing) {
          await supabase.from('post_images').insert({
            'post_id': widget.existingPost!['id'],
            'url': url,
          });
        }
      }
      
      if (isEditing) {
        await provider.updatePost(
          postId: widget.existingPost!['id'],
          title: titleController.text.trim(),
          body: finalBody,
          newImageBytes: [],
          imageIdsToDelete: imageIdsToDelete,
        );
      } else {
        await provider.createPost(
          title: titleController.text.trim(),
          body: finalBody,
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
            width: 1100,
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

                // 1. Article Title Input
                shadcn.TextField(
                  controller: titleController,
                  borderRadius: BorderRadius.circular(AppRadius.value),
                  border: Border.all(color: AppColors.border(context)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  placeholder: Text(
                    'Title *',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  features: const [shadcn.InputFeature.clear()],
                ),
                const SizedBox(height: 20),

                // 2. Header Cover Photo Dropzone
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
                  onImageDropped: (bytes) =>
                      setState(() => pickedImages.add(bytes)),
                ),
                const SizedBox(height: 20),

                // 3. Markdown Body Canvas
                FormMarkdown(
                  controller: bodyController,
                  onImageFilePicked: _onToolbarImagePicked,
                ),
                const SizedBox(height: 20),

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
                            ? 'Publishing...'
                            : (isEditing ? 'Save Changes' : 'Publish'),
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

// This screen allows users to create a new post or edit an exisiting one.

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/posts_provider.dart';

class PostFormScreen extends StatefulWidget {
  final Map<String, dynamic>? existingPost;
  const PostFormScreen({super.key, this.existingPost});

  @override
  State<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen> {
  final titleController = TextEditingController();
  final bodyController = TextEditingController();
  final List<Uint8List> pickedImages = [];
  final List<String> imageIdsToDelete = [];
  List<dynamic> existingImages = [];
  String? error;
  bool isSubmitting = false;

  bool get isEditing => widget.existingPost != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      titleController.text = widget.existingPost!['title'];
      bodyController.text = widget.existingPost!['body'];
      existingImages = List.from(widget.existingPost!['post_images']);
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

  void removeExistingImage(String imageId) {
    setState(() {
      imageIdsToDelete.add(imageId);
      existingImages.removeWhere((img) => img['id'] == imageId);
    });
  }

  Future<void> handleSubmit() async {
    setState(() => isSubmitting = true);
    try {
      final provider = context.read<PostsProvider>();
      if (isEditing) {
        await provider.updatePost(
          postId: widget.existingPost!['id'],
          title: titleController.text,
          body: bodyController.text,
          newImageBytes: pickedImages,
          imageIdsToDelete: imageIdsToDelete,
        );
      } else {
        await provider.createPost(
          title: titleController.text,
          body: bodyController.text,
          imageBytes: pickedImages,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Post')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: bodyController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Body'),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                ...existingImages.map(
                  (img) => Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Image.network(
                        img['url'],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: -8,
                        right: -8,
                        child: GestureDetector(
                          onTap: () => removeExistingImage(img['id']),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(2),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ...pickedImages.map(
                  (bytes) => Image.memory(
                    bytes,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
            TextButton(onPressed: pickImages, child: const Text('Add Images')),
            const SizedBox(height: 16),
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: isSubmitting ? null : handleSubmit,
              child: Text(isSubmitting ? 'Posting...' : 'Post'),
            ),
          ],
        ),
      ),
    );
  }
}

// lib/widgets/post_form/post_form_imagepicker.dart (Combined Picker + Preview)

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_theme.dart';

class PostFormImagePicker extends StatelessWidget {
  final VoidCallback onTap;
  final List<dynamic> existingImages;
  final List<Uint8List> pickedImages;
  final ValueChanged<String> onRemoveExisting;
  final ValueChanged<int> onRemovePicked;

  const PostFormImagePicker({
    super.key,
    required this.onTap,
    required this.existingImages,
    required this.pickedImages,
    required this.onRemoveExisting,
    required this.onRemovePicked,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Upload Dropzone Box
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.value),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground(context),
              borderRadius: BorderRadius.circular(AppRadius.value),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Column(
              children: [
                const Icon(LucideIcons.imagePlus,
                    size: 28, color: AppColors.primary),
                const SizedBox(height: 8),
                Text(
                  'Click to upload images',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. Thumbnails Preview Grid below upload box
        if (existingImages.isNotEmpty || pickedImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ...existingImages.map(
                (img) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        img['url'],
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: GestureDetector(
                        onTap: () => onRemoveExisting(img['id']),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(3),
                          child: const Icon(LucideIcons.x,
                              size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...pickedImages.asMap().entries.map(
                (entry) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        entry.value,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: GestureDetector(
                        onTap: () => onRemovePicked(entry.key),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(3),
                          child: const Icon(LucideIcons.x,
                              size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
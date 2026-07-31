// lib/widgets/post_form/form_imagepicker.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import '../../theme/app_theme.dart';

class FormImagePicker extends StatefulWidget {
  final VoidCallback onTap;
  final List<dynamic> existingImages;
  final List<Uint8List> pickedImages;
  final ValueChanged<String> onRemoveExisting;
  final ValueChanged<int> onRemovePicked;
  final ValueChanged<Uint8List>? onImageDropped;

  const FormImagePicker({
    super.key,
    required this.onTap,
    required this.existingImages,
    required this.pickedImages,
    required this.onRemoveExisting,
    required this.onRemovePicked,
    this.onImageDropped,
  });

  @override
  State<FormImagePicker> createState() => _FormImagePickerState();
}

class _FormImagePickerState extends State<FormImagePicker> {
  bool isDragging = false;

  void _showImagesModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final total = widget.existingImages.length + widget.pickedImages.length;
          if (total == 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Navigator.of(context).canPop()) Navigator.pop(context);
            });
          }

          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: 480,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Uploaded Cover Photos ($total)',
                        style: AppTextStyles.heading(context, size: 18),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                        icon: Icon(
                          LucideIcons.x,
                          size: 18,
                          color: AppColors.textSecondary(context),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ...widget.existingImages.map(
                        (img) => _buildModalThumbnail(
                          context,
                          imageWidget: Image.network(
                            img['url'],
                            width: 96,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                          onDelete: () {
                            widget.onRemoveExisting(img['id']);
                            setModalState(() {});
                          },
                        ),
                      ),
                      ...widget.pickedImages.asMap().entries.map(
                        (entry) => _buildModalThumbnail(
                          context,
                          imageWidget: Image.memory(
                            entry.value,
                            width: 96,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                          onDelete: () {
                            widget.onRemovePicked(entry.key);
                            setModalState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: shadcn.PrimaryButton(
                      density: shadcn.ButtonDensity.normal,
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModalThumbnail(
    BuildContext context, {
    required Widget imageWidget,
    required VoidCallback onDelete,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imageWidget,
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(3),
              child: const Icon(LucideIcons.x, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalImages = widget.existingImages.length + widget.pickedImages.length;

    return DropTarget(
      onDragEntered: (_) => setState(() => isDragging = true),
      onDragExited: (_) => setState(() => isDragging = false),
      onDragDone: (details) async {
        setState(() => isDragging = false);
        for (final file in details.files) {
          final bytes = await file.readAsBytes();
          if (widget.onImageDropped != null) {
            widget.onImageDropped!(bytes);
          }
        }
      },
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: isDragging
              ? AppColors.primary
              : AppColors.border(context),
          strokeWidth: isDragging ? 2.5 : 1.5,
          gap: 6.0,
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppRadius.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            color: isDragging
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              children: [
                Icon(
                  LucideIcons.imagePlus,
                  size: 32,
                  color: isDragging ? AppColors.primary : AppColors.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  'Header Cover Photo (Optional)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isDragging
                      ? 'Drop image here to upload!'
                      : 'Click, Drag & Drop or Paste (Ctrl+V) image file to upload cover banner.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(context, size: 12),
                ),
                if (totalImages > 0) ...[
                  const SizedBox(height: 14),
                  shadcn.SecondaryButton(
                    density: shadcn.ButtonDensity.dense,
                    onPressed: () => _showImagesModal(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.images, size: 14),
                        const SizedBox(width: 6),
                        Text('View Uploaded Photos ($totalImages)'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.gap = 6.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(8),
      ));

    final dashPath = Path();
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + gap),
          Offset.zero,
        );
        distance += gap * 2;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color;
}
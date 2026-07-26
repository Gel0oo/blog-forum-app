// lib/widgets/post_list/post_image.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'post_card_skeleton.dart';

class PostImage extends StatefulWidget {
  final String url;
  const PostImage({super.key, required this.url});

  @override
  State<PostImage> createState() => _PostImageState();
}

class _PostImageState extends State<PostImage> {
  double? aspectRatio;

  @override
  void initState() {
    super.initState();
    Image.network(widget.url).image
        .resolve(const ImageConfiguration())
        .addListener(
          ImageStreamListener((info, _) {
            if (mounted) {
              setState(
                () => aspectRatio = info.image.width / info.image.height,
              );
            }
          }),
        );
  }

  @override
  Widget build(BuildContext context) {
    if (aspectRatio == null) {
      return SkeletonBox(
        width: double.infinity,
        height: 200,
        borderRadius: BorderRadius.circular(10),
      );
    }

    const double maxHeight = 500.0;

    if (aspectRatio! >= 1.2) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(maxHeight: maxHeight),
          width: double.infinity,
          child: AspectRatio(
            aspectRatio: aspectRatio!,
            child: Image.network(widget.url, fit: BoxFit.cover),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: maxHeight,
        width: double.infinity,
        color: Colors.black.withValues(alpha: 0.1),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Transform.scale(
              scale: 1.25,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: 30,
                  sigmaY: 30,
                  tileMode: TileMode.clamp,
                ),
                child: Image.network(widget.url, fit: BoxFit.cover),
              ),
            ),
            Container(color: Colors.black.withValues(alpha: 0.2)),
            Center(child: Image.network(widget.url, fit: BoxFit.contain)),
          ],
        ),
      ),
    );
  }
}
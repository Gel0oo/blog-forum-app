import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ImageViewerScreen extends StatefulWidget {
  final String url;
  const ImageViewerScreen({super.key, required this.url});

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  final TransformationController _controller = TransformationController();
  final FocusNode _focusNode = FocusNode();

  void _handleScroll(PointerScrollEvent event) {
    final currentScale = _controller.value.getMaxScaleOnAxis();
    final zoomingIn = event.scrollDelta.dy < 0;
    final factor = zoomingIn ? 1.1 : 0.9;
    final targetScale = currentScale * (zoomingIn ? 1.1 : 0.9);
    if (targetScale < 1.0 || targetScale > 5.0) return;

    _controller.value = _controller.value.clone()..scaleByDouble(factor, factor, factor, 1.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode..requestFocus(),
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop();
        }
      },
      child: GestureDetector(
        // Tapping anywhere that isn't the image itself closes the viewer.
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(color: Colors.black.withValues(alpha: 0.3)),
              ),
            ),
            Center(
              child: Listener(
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent) _handleScroll(event);
                },
                child: GestureDetector(
                  // Absorb taps on the image itself so they don't bubble up
                  // to the outer GestureDetector and close the viewer.
                  onTap: () {},
                  child: InteractiveViewer(
                    transformationController: _controller,
                    clipBehavior: Clip.none,
                    boundaryMargin: const EdgeInsets.all(double.infinity),
                    minScale: 1.0,
                    maxScale: 5.0,
                    child: Image.network(widget.url, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

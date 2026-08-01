// lib/widgets/post_detail/detail_image_carousel.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import '../image_viewer.dart';

/// Auto-playing multi-image carousel. Pauses on hover, advances every 5s.
class DetailImageCarousel extends StatefulWidget {
  final List<String> urls;
  const DetailImageCarousel({super.key, required this.urls});

  @override
  State<DetailImageCarousel> createState() => _DetailImageCarouselState();
}

class _DetailImageCarouselState extends State<DetailImageCarousel> {
  final shadcn.CarouselController _controller = shadcn.CarouselController();
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    if (widget.urls.length <= 1) return;
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        _controller.animateNext(const Duration(milliseconds: 400));
      }
    });
  }

  void _pauseAutoPlay() {
    _autoPlayTimer?.cancel();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _openViewer(String url) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close image',
      barrierColor: Colors.transparent,
      pageBuilder: (context, animation, secondaryAnimation) =>
          ImageViewerScreen(url: url),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double height = 420;

    return MouseRegion(
      onEnter: (_) => _pauseAutoPlay(), // Pause auto-slide when mouse hovers
      onExit: (_) => _startAutoPlay(),  // Resume auto-slide when mouse leaves
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            shadcn.Carousel(
              controller: _controller,
              transition: const shadcn.CarouselTransition.sliding(),
              itemCount: widget.urls.length,
              duration: null, // Avoid bugged shadcn internal timer
              itemBuilder: (context, index) {
                final url = widget.urls[index];
                return GestureDetector(
                  onTap: () => _openViewer(url),
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: height,
                  ),
                );
              },
            ),
            Positioned(
              left: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: _NavButton(
                  icon: Icons.chevron_left,
                  onTap: () {
                    _pauseAutoPlay();
                    _controller
                        .animatePrevious(const Duration(milliseconds: 300));
                    _startAutoPlay();
                  },
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: _NavButton(
                  icon: Icons.chevron_right,
                  onTap: () {
                    _pauseAutoPlay();
                    _controller
                        .animateNext(const Duration(milliseconds: 300));
                    _startAutoPlay();
                  },
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: shadcn.CarouselDotIndicator(
                  itemCount: widget.urls.length,
                  controller: _controller,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.4),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
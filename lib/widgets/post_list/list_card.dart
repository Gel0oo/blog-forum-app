// lib/widgets/post_list/list_card.dart

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../utils/time_ago.dart';
import '../../screens/posts/post_detail_screen.dart';
import '../menu_dropdown.dart';

class ListCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final ScrollController scrollController;
  final bool isHero;

  const ListCard({
    super.key,
    required this.post,
    required this.scrollController,
    this.isHero = false,
  });

  @override
  State<ListCard> createState() => _ListCardState();
}

class _ListCardState extends State<ListCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final images = (widget.post['post_images'] as List?) ?? [];
    final authorName = widget.post['author']?['name'] ?? 'Author';
    final authorAvatar = widget.post['author']?['avatar_url'];
    final imageUrl = images.isNotEmpty ? images[0]['url'] as String? : null;

    if (widget.isHero) {
      return _buildHeroCard(context, imageUrl, authorName, authorAvatar);
    }

    return _buildGridCard(context, imageUrl, authorName, authorAvatar);
  }

  // Hero Split Banner
  Widget _buildHeroCard(
    BuildContext context,
    String? imageUrl,
    String authorName,
    String? authorAvatar,
  ) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final hasImage = imageUrl != null;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(post: widget.post),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.cardBackground(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovered
                  ? AppColors.primary.withValues(alpha: 0.6)
                  : AppColors.border(context),
              width: 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: hasImage
                ? (isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeroImage(imageUrl),
                          _buildHeroContent(context, authorName, authorAvatar),
                        ],
                      )
                    : IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 12,
                              child: _buildHeroImage(imageUrl),
                            ),
                            Expanded(
                              flex: 10,
                              child: _buildHeroContent(
                                  context, authorName, authorAvatar),
                            ),
                          ],
                        ),
                      ))
                : Container(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'FEATURED STORY',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '• ${formatDate(widget.post['created_at'])}',
                              style: AppTextStyles.body(context, size: 12),
                            ),
                            const Spacer(),
                            MenuDropdown(
                              post: widget.post,
                              scrollController: widget.scrollController,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.post['title'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.heading(context, size: 28),
                        ),
                        const SizedBox(height: 12),
                        Text.rich(
                          TextSpan(
                            children: _parseInlineMarkdown(
                              widget.post['body'] ?? '',
                              AppTextStyles.body(context, size: 15),
                            ),
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: authorAvatar != null
                                  ? NetworkImage(authorAvatar)
                                  : null,
                              child: authorAvatar == null
                                  ? const Icon(LucideIcons.user, size: 16)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              authorName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => PostDetailScreen(
                                        post: widget.post),
                                  ),
                                );
                              },
                              icon: const Text(
                                'Read full article',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              label:
                                  const Icon(LucideIcons.arrowRight, size: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImage(String imageUrl) {
    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
      clipBehavior: Clip.hardEdge,
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedScale(
              scale: isHovered ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(
                  sigmaX: isHovered ? 2.0 : 0.0,
                  sigmaY: isHovered ? 2.0 : 0.0,
                ),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroContent(
    BuildContext context,
    String authorName,
    String? authorAvatar,
  ) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(
                'FEATURED STORY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '• ${formatDate(widget.post['created_at'])}',
                style: AppTextStyles.body(context, size: 11),
              ),
              const Spacer(),
              MenuDropdown(
                post: widget.post,
                scrollController: widget.scrollController,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.post['title'] ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.heading(context, size: 24),
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              children: _parseInlineMarkdown(
                widget.post['body'] ?? '',
                AppTextStyles.body(context, size: 14),
              ),
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PostDetailScreen(post: widget.post),
                ),
              );
            },
            icon: const Text(
              'Read the full article',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            label: const Icon(LucideIcons.arrowRight, size: 16),
          ),
        ],
      ),
    );
  }

  // Publication Grid Card
  Widget _buildGridCard(
    BuildContext context,
    String? imageUrl,
    String authorName,
    String? authorAvatar,
  ) {
    final hasImage = imageUrl != null;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(post: widget.post),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.cardBackground(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovered
                  ? AppColors.primary.withValues(alpha: 0.6)
                  : AppColors.border(context),
              width: 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Top 16:9 Header
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (hasImage)
                        AnimatedScale(
                          scale: isHovered ? 1.08 : 1.0,
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          child: ImageFiltered(
                            imageFilter: ui.ImageFilter.blur(
                              sigmaX: isHovered ? 2.0 : 0.0,
                              sigmaY: isHovered ? 2.0 : 0.0,
                            ),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  _buildFallbackBanner(
                                context,
                                authorName,
                                authorAvatar,
                              ),
                            ),
                          ),
                        )
                      else if (authorAvatar != null)
                        _DynamicImageGradientBanner(
                          imageUrl: authorAvatar,
                          isHovered: isHovered,
                        )
                      else
                        Container(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          child: const Center(
                            child: Icon(LucideIcons.user, size: 36),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 2. Content Body
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundImage: authorAvatar != null
                              ? NetworkImage(authorAvatar)
                              : null,
                          child: authorAvatar == null
                              ? const Icon(LucideIcons.user, size: 12)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'by $authorName • ${timeAgo(widget.post['created_at'])}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body(context, size: 13),
                          ),
                        ),
                        MenuDropdown(
                          post: widget.post,
                          scrollController: widget.scrollController,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Text(
                      widget.post['title'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.heading(context, size: 20),
                    ),
                    const SizedBox(height: 8),

                    Text.rich(
                      TextSpan(
                        children: _parseInlineMarkdown(
                          widget.post['body'] ?? '',
                          AppTextStyles.body(context, size: 14),
                        ),
                      ),
                      maxLines: hasImage ? 2 : 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 18),

                    Divider(
                      color: AppColors.border(context)
                          .withValues(alpha: 0.5),
                      height: 1,
                    ),
                    const SizedBox(height: 14),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatDate(widget.post['created_at']),
                          style: AppTextStyles.body(context, size: 12),
                        ),
                        Row(
                          children: [
                            Text(
                              'Read more',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isHovered
                                    ? AppColors.primary
                                    : AppColors.textPrimary(context),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              LucideIcons.arrowRight,
                              size: 14,
                              color: isHovered
                                  ? AppColors.primary
                                  : AppColors.textPrimary(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Fallback Banner
  Widget _buildFallbackBanner(
    BuildContext context,
    String authorName,
    String? authorAvatar,
  ) {
    if (authorAvatar != null) {
      return _DynamicImageGradientBanner(
        imageUrl: authorAvatar,
        isHovered: isHovered,
      );
    }

    return Container(
      color: AppColors.primary.withValues(alpha: 0.2),
      child: const Center(
        child: Icon(LucideIcons.user, size: 36),
      ),
    );
  }
}

// Extracted Dominant Image Color Extractor Banner
class _DynamicImageGradientBanner extends StatefulWidget {
  final String imageUrl;
  final bool isHovered;

  const _DynamicImageGradientBanner({
    required this.imageUrl,
    required this.isHovered,
  });

  @override
  State<_DynamicImageGradientBanner> createState() =>
      __DynamicImageGradientBannerState();
}

class __DynamicImageGradientBannerState
    extends State<_DynamicImageGradientBanner> {
  Color _extractedColor = const Color(0xFF4A3B2C);

  @override
  void initState() {
    super.initState();
    _extractDominantColor();
  }

  @override
  void didUpdateWidget(covariant _DynamicImageGradientBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _extractDominantColor();
    }
  }

  Future<void> _extractDominantColor() async {
    try {
      final imageProvider = NetworkImage(widget.imageUrl);
      final stream = imageProvider.resolve(const ImageConfiguration());
      stream.addListener(
        ImageStreamListener((info, _) async {
          try {
            final byteData = await info.image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            );
            if (byteData == null) return;

            final bytes = byteData.buffer.asUint8List();
            int rSum = 0, gSum = 0, bSum = 0, count = 0;

            for (int i = 0; i < bytes.length; i += 64) {
              rSum += bytes[i];
              gSum += bytes[i + 1];
              bSum += bytes[i + 2];
              count++;
            }

            if (count > 0 && mounted) {
              final avgR = (rSum / count).round().clamp(0, 255);
              final avgG = (gSum / count).round().clamp(0, 255);
              final avgB = (bSum / count).round().clamp(0, 255);
              setState(() {
                _extractedColor = Color.fromRGBO(avgR, avgG, avgB, 1.0);
              });
            }
          } catch (_) {}
        }),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final hsl = HSLColor.fromColor(_extractedColor);
    final darkColor =
        hsl.withLightness((hsl.lightness * 0.7).clamp(0.15, 0.45)).toColor();
    final lightColor =
        hsl.withLightness((hsl.lightness * 1.2).clamp(0.3, 0.7)).toColor();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  lightColor.withValues(alpha: 0.85),
                  darkColor.withValues(alpha: 0.55),
                  AppColors.cardBackground(context),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: ClipRRect(
            child: AnimatedScale(
              scale: widget.isHovered ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              child: Image.network(
                widget.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

List<InlineSpan> _parseInlineMarkdown(String text, TextStyle baseStyle) {
  text = text.replaceAllMapped(RegExp(r'^-\s+', multiLine: true), (_) => '•  ');

  final pattern = RegExp(
    r'(\*\*\*(.+?)\*\*\*)|(\*\*(.+?)\*\*)|(\*(.+?)\*)|(\[(.+?)\]\((.+?)\))',
  );

  final spans = <InlineSpan>[];
  int lastEnd = 0;

  for (final match in pattern.allMatches(text)) {
    if (match.start > lastEnd) {
      spans.add(
        TextSpan(text: text.substring(lastEnd, match.start), style: baseStyle),
      );
    }

    if (match.group(1) != null) {
      // ***bold italic***
      spans.add(
        TextSpan(
          text: match.group(2),
          style: baseStyle.copyWith(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    } else if (match.group(3) != null) {
      // **bold**
      spans.add(
        TextSpan(
          text: match.group(4),
          style: baseStyle.copyWith(fontWeight: FontWeight.bold),
        ),
      );
    } else if (match.group(5) != null) {
      // *italic*
      spans.add(
        TextSpan(
          text: match.group(6),
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        ),
      );
    } else if (match.group(7) != null) {
      // [text](url) - All links rendered in bold purple with underline
      final rawLinkText = match.group(8) ?? '';
      final cleanText = rawLinkText.replaceAll('*', '');

      spans.add(
        TextSpan(
          text: cleanText,
          style: baseStyle.copyWith(
            decoration: TextDecoration.underline,
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontStyle: rawLinkText.contains('*')
                ? FontStyle.italic
                : FontStyle.normal,
          ),
        ),
      );
    }
    lastEnd = match.end;
  }

  if (lastEnd < text.length) {
    spans.add(TextSpan(text: text.substring(lastEnd), style: baseStyle));
  }

  return spans;
}
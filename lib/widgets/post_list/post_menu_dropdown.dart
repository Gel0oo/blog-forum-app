// lib/widgets/post_list/post_menu_dropdown.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import '../../theme/app_theme.dart';

class PostMenuDropdown extends StatefulWidget {
  final String postBody;
  final ScrollController? scrollController;
  const PostMenuDropdown({
    super.key,
    required this.postBody,
    this.scrollController,
  });

  @override
  State<PostMenuDropdown> createState() => _PostMenuDropdownState();
}

class _PostMenuDropdownState extends State<PostMenuDropdown> {
  shadcn.OverlayCompleter? _overlayCompleter;

  @override
  void initState() {
    super.initState();
    widget.scrollController?.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    _overlayCompleter?.close();
    super.dispose();
  }

  void _onScroll() {
    if (_overlayCompleter != null) {
      _overlayCompleter?.close();
      _overlayCompleter = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (btnContext) {
        return IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          style: IconButton.styleFrom(hoverColor: AppColors.hover(context)),
          icon: Icon(
            LucideIcons.moreHorizontal,
            size: 20,
            color: AppColors.textSecondary(context),
          ),
          onPressed: () {
            _overlayCompleter = shadcn.showDropdown(
              context: btnContext,
              anchorAlignment: Alignment.bottomRight,
              alignment: Alignment.topRight,
              builder: (context) {
                return MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(disableAnimations: false),
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeInOutCubic,
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.92 + (0.08 * value),
                        child: Opacity(opacity: value, child: child),
                      );
                    },
                    child: shadcn.DropdownMenu(
                      children: [
                        shadcn.MenuButton(
                          leading: const Icon(LucideIcons.copy, size: 18),
                          onPressed: (context) {
                            Clipboard.setData(
                              ClipboardData(text: widget.postBody),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Copied to clipboard'),
                              ),
                            );
                            _overlayCompleter?.close();
                            _overlayCompleter = null;
                          },
                          child: const Text('Copy text'),
                        ),
                        shadcn.MenuButton(
                          leading: const Icon(LucideIcons.flag, size: 18),
                          onPressed: (context) {
                            _overlayCompleter?.close();
                            _overlayCompleter = null;
                          },
                          child: const Text('Report'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
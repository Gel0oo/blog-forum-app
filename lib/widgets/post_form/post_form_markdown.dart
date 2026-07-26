// lib/widgets/post_form/post_form_markdown.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import '../../theme/app_theme.dart';

class MarkdownVisualController extends TextEditingController {
  final BuildContext context;
  MarkdownVisualController(this.context, {super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final children = <InlineSpan>[];
    final pattern = RegExp(r'(\*\*.*?\*\*|\*.*?\*|`.*?`|\[.*?\]\(.*?\))');

    text.splitMapJoin(
      pattern,
      onMatch: (match) {
        final fullMatch = match[0]!;

        // 1. Bold: **text**
        if (fullMatch.startsWith('**') &&
            fullMatch.endsWith('**') &&
            fullMatch.length >= 4) {
          final content = fullMatch.substring(2, fullMatch.length - 2);
          children.add(const TextSpan(
              text: '**',
              style: TextStyle(fontSize: 0.001, color: Colors.transparent)));
          children.add(TextSpan(
            text: content,
            style: (style ?? const TextStyle()).copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(context),
            ),
          ));
          children.add(const TextSpan(
              text: '**',
              style: TextStyle(fontSize: 0.001, color: Colors.transparent)));
        }
        // 2. Italic: *text*
        else if (fullMatch.startsWith('*') &&
            fullMatch.endsWith('*') &&
            fullMatch.length >= 2) {
          final content = fullMatch.substring(1, fullMatch.length - 1);
          children.add(const TextSpan(
              text: '*',
              style: TextStyle(fontSize: 0.001, color: Colors.transparent)));
          children.add(TextSpan(
            text: content,
            style: (style ?? const TextStyle()).copyWith(
              fontStyle: FontStyle.italic,
              color: AppColors.textPrimary(context),
            ),
          ));
          children.add(const TextSpan(
              text: '*',
              style: TextStyle(fontSize: 0.001, color: Colors.transparent)));
        }
        // 3. Code: `text`
        else if (fullMatch.startsWith('`') &&
            fullMatch.endsWith('`') &&
            fullMatch.length >= 2) {
          final content = fullMatch.substring(1, fullMatch.length - 1);
          children.add(const TextSpan(
              text: '`',
              style: TextStyle(fontSize: 0.001, color: Colors.transparent)));
          children.add(TextSpan(
            text: content,
            style: GoogleFonts.firaCode(
              fontSize: 13,
              color: AppColors.primary,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            ),
          ));
          children.add(const TextSpan(
              text: '`',
              style: TextStyle(fontSize: 0.001, color: Colors.transparent)));
        }
        // 4. Link: [text](url)
        else if (fullMatch.startsWith('[') && fullMatch.contains('](')) {
          final closeBracket = fullMatch.indexOf('](');
          final linkText = fullMatch.substring(1, closeBracket);
          final url = fullMatch.substring(closeBracket + 2, fullMatch.length - 1);

          children.add(const TextSpan(
              text: '[',
              style: TextStyle(fontSize: 0.001, color: Colors.transparent)));
          children.add(TextSpan(
            text: linkText,
            style: (style ?? const TextStyle()).copyWith(
              color: AppColors.primary,
              decoration: TextDecoration.underline,
            ),
          ));
          children.add(TextSpan(
              text: ']($url)',
              style: const TextStyle(fontSize: 0.001, color: Colors.transparent)));
        } else {
          children.add(TextSpan(text: fullMatch, style: style));
        }
        return fullMatch;
      },
      onNonMatch: (nonMatch) {
        children.add(TextSpan(text: nonMatch, style: style));
        return nonMatch;
      },
    );

    return TextSpan(style: style, children: children);
  }
}

class PostFormMarkdown extends StatefulWidget {
  final TextEditingController controller;
  const PostFormMarkdown({super.key, required this.controller});

  @override
  State<PostFormMarkdown> createState() => _PostFormMarkdownState();
}

class _PostFormMarkdownState extends State<PostFormMarkdown> {
  void _toggleFormat(String tag) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    if (!selection.isValid) return;

    if (!selection.isCollapsed) {
      final selectedText = selection.textInside(text);
      if (selectedText.startsWith(tag) &&
          selectedText.endsWith(tag) &&
          selectedText.length >= tag.length * 2) {
        final unwrapped =
            selectedText.substring(tag.length, selectedText.length - tag.length);
        final newText =
            text.replaceRange(selection.start, selection.end, unwrapped);
        widget.controller.text = newText;
        widget.controller.selection = TextSelection(
          baseOffset: selection.start,
          extentOffset: selection.start + unwrapped.length,
        );
      } else {
        final wrapped = '$tag$selectedText$tag';
        final newText =
            text.replaceRange(selection.start, selection.end, wrapped);
        widget.controller.text = newText;
        widget.controller.selection = TextSelection(
          baseOffset: selection.start,
          extentOffset: selection.start + wrapped.length,
        );
      }
      return;
    }

    final cursor = selection.start;
    const placeholder = 'text';
    final inserted = '$tag$placeholder$tag';
    final newText = text.replaceRange(cursor, cursor, inserted);
    widget.controller.text = newText;
    widget.controller.selection = TextSelection(
      baseOffset: cursor + tag.length,
      extentOffset: cursor + tag.length + placeholder.length,
    );
  }

  void _insertLink() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    if (!selection.isValid) return;

    if (!selection.isCollapsed) {
      final selectedText = selection.textInside(text);
      final inserted = '[$selectedText](https://)';
      final newText =
          text.replaceRange(selection.start, selection.end, inserted);
      widget.controller.text = newText;
    } else {
      final cursor = selection.start;
      const inserted = '[link text](https://)';
      final newText = text.replaceRange(cursor, cursor, inserted);
      widget.controller.text = newText;
      widget.controller.selection = TextSelection(
        baseOffset: cursor + 1,
        extentOffset: cursor + 10,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyB, control: true): () =>
            _toggleFormat('**'),
        const SingleActivator(LogicalKeyboardKey.keyB, meta: true): () =>
            _toggleFormat('**'),
        const SingleActivator(LogicalKeyboardKey.keyI, control: true): () =>
            _toggleFormat('*'),
        const SingleActivator(LogicalKeyboardKey.keyI, meta: true): () =>
            _toggleFormat('*'),
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): _insertLink,
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): _insertLink,
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground(context),
          borderRadius: BorderRadius.circular(AppRadius.value),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Column(
          children: [
            // Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.border(context)),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Bold (Ctrl+B)',
                    icon: const Icon(LucideIcons.bold, size: 16),
                    onPressed: () => _toggleFormat('**'),
                  ),
                  IconButton(
                    tooltip: 'Italic (Ctrl+I)',
                    icon: const Icon(LucideIcons.italic, size: 16),
                    onPressed: () => _toggleFormat('*'),
                  ),
                  IconButton(
                    tooltip: 'Link (Ctrl+K)',
                    icon: const Icon(LucideIcons.link, size: 16),
                    onPressed: _insertLink, // Corrected to insert link format
                  ),
                  IconButton(
                    tooltip: 'Code',
                    icon: const Icon(LucideIcons.code, size: 16),
                    onPressed: () => _toggleFormat('`'), // Inserts code format
                  ),
                ],
              ),
            ),
            // Text Area
            shadcn.TextArea(
              controller: widget.controller,
              maxLines: 8,
              filled: false,
              border: const Border(),
              padding: const EdgeInsets.all(14),
              placeholder: Text(
                'Body text (optional)',
                style: AppTextStyles.body(context, size: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
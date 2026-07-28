// lib/widgets/post_form/form_markdown.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final pattern = RegExp(r'(\*\*.*?\*\*|\*.*?\*|\[.*?\]\(.*?\))');

    text.splitMapJoin(
      pattern,
      onMatch: (match) {
        final fullMatch = match[0]!;

        if (fullMatch.startsWith('**') &&
            fullMatch.endsWith('**') &&
            fullMatch.length >= 4) {
          children.add(
            TextSpan(
              text: fullMatch,
              style: (style ?? const TextStyle()).copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
              ),
            ),
          );
        } else if (fullMatch.startsWith('*') &&
            fullMatch.endsWith('*') &&
            fullMatch.length >= 2) {
          children.add(
            TextSpan(
              text: fullMatch,
              style: (style ?? const TextStyle()).copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.textPrimary(context),
              ),
            ),
          );
        } else if (fullMatch.startsWith('[') &&
            fullMatch.contains('](') &&
            fullMatch.endsWith(')')) {
          final closeBracket = fullMatch.indexOf('](');
          final linkText = fullMatch.substring(1, closeBracket);
          final url = fullMatch.substring(
            closeBracket + 2,
            fullMatch.length - 1,
          );

          final muted = TextStyle(color: AppColors.textSecondary(context));

          children.add(TextSpan(text: '[', style: muted));
          children.add(
            TextSpan(
              text: linkText,
              style: (style ?? const TextStyle()).copyWith(
                color: AppColors.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          );
          children.add(TextSpan(text: '](', style: muted));
          children.add(TextSpan(text: url, style: muted));
          children.add(TextSpan(text: ')', style: muted));
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

class FormMarkdown extends StatefulWidget {
  final TextEditingController controller;
  const FormMarkdown({super.key, required this.controller});

  @override
  State<FormMarkdown> createState() => _FormMarkdownState();
}

class _FormMarkdownState extends State<FormMarkdown> {
  double _editorHeight = 200;

  String _previousText = '';
  TextSelection _previousSelection = const TextSelection.collapsed(offset: 0);
  bool _isProgrammaticChange = false;

  @override
  void initState() {
    super.initState();
    _previousText = widget.controller.text;
    _previousSelection = widget.controller.selection;
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  // Every programmatic edit in this file goes through here, so bookkeeping
  // for the change-detector below always stays in sync and never mistakes
  // our own edits for something the user typed.
  void _setControllerState(String text, TextSelection selection) {
    _isProgrammaticChange = true;
    widget.controller.value = TextEditingValue(
      text: text,
      selection: selection,
    );
    _previousText = text;
    _previousSelection = selection;
    _isProgrammaticChange = false;
  }

  void _onControllerChanged() {
    if (_isProgrammaticChange) return;

    final text = widget.controller.text;
    final selection = widget.controller.selection;

    final oldCursor = _previousSelection.isValid
        ? _previousSelection.start
        : -1;

    // Detect: exactly one '\n' was inserted right at the old cursor position
    // and nothing else changed — i.e. the user pressed Enter with a
    // collapsed selection, letting the text field insert its normal newline.
    final isSingleNewlineInsert =
        selection.isValid &&
        selection.isCollapsed &&
        oldCursor >= 0 &&
        selection.start == oldCursor + 1 &&
        text.length == _previousText.length + 1 &&
        oldCursor < text.length &&
        text[oldCursor] == '\n' &&
        text.substring(0, oldCursor) == _previousText.substring(0, oldCursor) &&
        text.substring(oldCursor + 1) == _previousText.substring(oldCursor);

    _previousText = text;
    _previousSelection = selection;

    if (isSingleNewlineInsert) {
      _maybeContinueList(text, oldCursor);
    }
  }

  void _maybeContinueList(String text, int newlineIndex) {
    final prevLineStart = text.lastIndexOf('\n', newlineIndex - 1) + 1;
    final prevLine = text.substring(prevLineStart, newlineIndex);

    final bulletMatch = RegExp(r'^(\s*)-\s').firstMatch(prevLine);
    final numberedMatch = RegExp(r'^(\s*)(\d+)\.\s').firstMatch(prevLine);

    String? continuation;
    bool prevLineIsEmptyPrefix = false;

    if (bulletMatch != null) {
      final indent = bulletMatch.group(1) ?? '';
      continuation = '$indent- ';
      prevLineIsEmptyPrefix = prevLine.trim() == '-';
    } else if (numberedMatch != null) {
      final indent = numberedMatch.group(1) ?? '';
      final number = int.parse(numberedMatch.group(2)!);
      continuation = '$indent${number + 1}. ';
      prevLineIsEmptyPrefix = prevLine.trim() == '${numberedMatch.group(2)}.';
    }

    if (continuation == null) return;

    if (prevLineIsEmptyPrefix) {
      // Empty bullet/number + Enter = exit the list, not add another blank one.
      final newText = text.replaceRange(prevLineStart, newlineIndex + 1, '');
      _setControllerState(
        newText,
        TextSelection.collapsed(offset: prevLineStart),
      );
    } else {
      final insertPos = newlineIndex + 1;
      final newText = text.replaceRange(insertPos, insertPos, continuation);
      _setControllerState(
        newText,
        TextSelection.collapsed(offset: insertPos + continuation.length),
      );
    }
  }

  void _toggleFormat(String tag) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    if (!selection.isValid) return;

    if (!selection.isCollapsed) {
      final selectedText = selection.textInside(text);
      if (selectedText.startsWith(tag) &&
          selectedText.endsWith(tag) &&
          selectedText.length >= tag.length * 2) {
        final unwrapped = selectedText.substring(
          tag.length,
          selectedText.length - tag.length,
        );
        final newText = text.replaceRange(
          selection.start,
          selection.end,
          unwrapped,
        );
        _setControllerState(
          newText,
          TextSelection(
            baseOffset: selection.start,
            extentOffset: selection.start + unwrapped.length,
          ),
        );
      } else {
        final wrapped = '$tag$selectedText$tag';
        final newText = text.replaceRange(
          selection.start,
          selection.end,
          wrapped,
        );
        _setControllerState(
          newText,
          TextSelection(
            baseOffset: selection.start,
            extentOffset: selection.start + wrapped.length,
          ),
        );
      }
      return;
    }

    final cursor = selection.start;
    const placeholder = 'text';
    final inserted = '$tag$placeholder$tag';
    final newText = text.replaceRange(cursor, cursor, inserted);
    _setControllerState(
      newText,
      TextSelection(
        baseOffset: cursor + tag.length,
        extentOffset: cursor + tag.length + placeholder.length,
      ),
    );
  }

  Future<void> _promptLink() async {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final selectedText = selection.isValid && !selection.isCollapsed
        ? selection.textInside(text)
        : '';

    final urlController = TextEditingController();
    final linkTextController = TextEditingController(text: selectedText);

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBackground(context),
            borderRadius: BorderRadius.circular(12),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Insert Link',
                style: AppTextStyles.heading(context, size: 18),
              ),
              const SizedBox(height: 16),
              shadcn.TextField(
                controller: linkTextController,
                borderRadius: BorderRadius.circular(8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                placeholder: Text(
                  'Display Text',
                  style: AppTextStyles.body(context, size: 13),
                ),
                features: const [shadcn.InputFeature.clear()],
              ),
              const SizedBox(height: 12),
              shadcn.TextField(
                controller: urlController,
                borderRadius: BorderRadius.circular(8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                placeholder: Text(
                  'URL (e.g. https://example.com)',
                  style: AppTextStyles.body(context, size: 13),
                ),
                features: const [shadcn.InputFeature.clear()],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  shadcn.SecondaryButton(
                    density: shadcn.ButtonDensity.dense,
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  shadcn.PrimaryButton(
                    density: shadcn.ButtonDensity.dense,
                    onPressed: () {
                      final rawUrl = urlController.text.trim();
                      if (rawUrl.isEmpty) {
                        Navigator.pop(context);
                        return;
                      }
                      final formattedUrl = rawUrl.startsWith('http')
                          ? rawUrl
                          : 'https://$rawUrl';
                      final displayText = linkTextController.text.trim().isEmpty
                          ? formattedUrl
                          : linkTextController.text.trim();

                      Navigator.pop(context, {
                        'text': displayText,
                        'url': formattedUrl,
                      });
                    },
                    child: const Text(
                      'Insert',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null && mounted) {
      final linkMarkdown = '[${result['text']}](${result['url']})';
      final currentText = widget.controller.text;
      if (selection.isValid) {
        final newText = currentText.replaceRange(
          selection.start,
          selection.end,
          linkMarkdown,
        );
        _setControllerState(
          newText,
          TextSelection.collapsed(
            offset: selection.start + linkMarkdown.length,
          ),
        );
      } else {
        final newText = '$currentText$linkMarkdown';
        _setControllerState(
          newText,
          TextSelection.collapsed(offset: newText.length),
        );
      }
    }
  }

  void _insertListPrefix(String prefix) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final cursor = selection.isValid ? selection.start : text.length;

    final needsNewlineBefore = cursor > 0 && text[cursor - 1] != '\n';
    final insertion = needsNewlineBefore ? '\n$prefix' : prefix;

    final newText = text.replaceRange(cursor, cursor, insertion);
    _setControllerState(
      newText,
      TextSelection.collapsed(offset: cursor + insertion.length),
    );
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
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            _promptLink,
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): _promptLink,
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground(context),
          borderRadius: BorderRadius.circular(AppRadius.value),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Column(
          children: [
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
                    tooltip: 'Insert Link (Ctrl+K)',
                    icon: const Icon(LucideIcons.link, size: 16),
                    onPressed: _promptLink,
                  ),
                  IconButton(
                    tooltip: 'Bullet List',
                    icon: const Icon(LucideIcons.list, size: 16),
                    onPressed: () => _insertListPrefix('- '),
                  ),
                  IconButton(
                    tooltip: 'Numbered List',
                    icon: const Icon(LucideIcons.listOrdered, size: 16),
                    onPressed: () => _insertListPrefix('1. '),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: _editorHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: shadcn.TextArea(
                      controller: widget.controller,
                      maxLines: null,
                      filled: false,
                      border: const Border(),
                      padding: const EdgeInsets.fromLTRB(14, 14, 24, 24),
                      placeholder: Text(
                        'Body text (optional)',
                        style: AppTextStyles.body(context, size: 14),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onPanUpdate: (details) {
                        setState(() {
                          _editorHeight = (_editorHeight + details.delta.dy)
                              .clamp(120.0, 700.0);
                        });
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.resizeUpDown,
                        child: Container(
                          width: 28,
                          height: 28,
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

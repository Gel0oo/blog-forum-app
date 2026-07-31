// lib/widgets/post_form/form_markdown.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import '../../theme/app_theme.dart';

final _imageTagPattern = RegExp(r'!\[Image\]\([^)]*\)');

/// True if [newText] only partially overlaps an ![Image](...) tag that was
/// intact in [oldText] — i.e. someone typed or deleted INTO the tag rather
/// than fully removing it. Fully deleting/replacing a tag is still allowed.
bool _editBreaksImageTag(String oldText, String newText) {
  var prefixLen = 0;
  final maxPrefix = oldText.length < newText.length
      ? oldText.length
      : newText.length;
  while (prefixLen < maxPrefix && oldText[prefixLen] == newText[prefixLen]) {
    prefixLen++;
  }

  var suffixLen = 0;
  final maxSuffix = maxPrefix - prefixLen;
  while (suffixLen < maxSuffix &&
      oldText[oldText.length - 1 - suffixLen] ==
          newText[newText.length - 1 - suffixLen]) {
    suffixLen++;
  }

  final editStart = prefixLen;
  final editEnd = oldText.length - suffixLen; // exclusive, old-text coords

  for (final match in _imageTagPattern.allMatches(oldText)) {
    final overlaps = editStart < match.end && editEnd > match.start;
    if (!overlaps) continue;
    final fullyCovers = editStart <= match.start && editEnd >= match.end;
    if (!fullyCovers) return true; // partial edit into a tag → reject
  }
  return false;
}

class MarkdownVisualController extends TextEditingController {
  final BuildContext context;
  final List<Uint8List> pickedImages;

  MarkdownVisualController(
    this.context, {
    required this.pickedImages,
    super.text,
  });

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final children = <InlineSpan>[];
    // Regex Order: 1. Image, 2. Link (FIRST before bold), 3. Bold-Italic, 4. Bold, 5. Italic
    final pattern = RegExp(
      r'(!\[.*?\]\(.*?\))|(\*\*\*.*?\*\*\*)|(\*\*.*?\*\*)|(\*.*?\*)',
    );

    text.splitMapJoin(
      pattern,
      onMatch: (match) {
        final fullMatch = match[0]!;

        // 1. Inline Image Token Badge: ![alt](IMAGE_0) or ![alt](https://...)
        if (fullMatch.startsWith('![')) {
          final closeBracket = fullMatch.indexOf('](');
          final token = closeBracket != -1 && fullMatch.endsWith(')')
              ? fullMatch.substring(closeBracket + 2, fullMatch.length - 1)
              : '';

          Widget? thumbWidget;

          if (token.startsWith('IMAGE_')) {
            final index = int.tryParse(token.replaceFirst('IMAGE_', '')) ?? -1;
            if (index >= 0 && index < pickedImages.length) {
              thumbWidget = ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.memory(
                  pickedImages[index],
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                ),
              );
            }
          } else if (token.startsWith('http')) {
            thumbWidget = ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                token,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const Icon(LucideIcons.image, size: 16),
              ),
            );
          }

          if (thumbWidget != null) {
            children.add(
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        thumbWidget,
                        const SizedBox(width: 8),
                        const Text(
                          'Image Attached',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          } else {
            children.add(TextSpan(text: fullMatch, style: style));
          }
        }
        // 3. ***bold italic***
        else if (fullMatch.startsWith('***') &&
            fullMatch.endsWith('***') &&
            fullMatch.length >= 6) {
          final content = fullMatch.substring(3, fullMatch.length - 3);
          children.add(
            const TextSpan(
              text: '***',
              style: TextStyle(fontSize: 0.001, color: Colors.transparent),
            ),
          );
          children.add(
            TextSpan(
              text: content,
              style: (style ?? const TextStyle()).copyWith(
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                color: AppColors.textPrimary(context),
              ),
            ),
          );
          children.add(
            const TextSpan(
              text: '***',
              style: TextStyle(fontSize: 0.001, color: Colors.transparent),
            ),
          );
        }
        // 4. **bold**
        else if (fullMatch.startsWith('**') &&
            fullMatch.endsWith('**') &&
            fullMatch.length >= 4) {
          final content = fullMatch.substring(2, fullMatch.length - 2);
          children.add(
            const TextSpan(
              text: '**',
              style: TextStyle(fontSize: 0.001, color: Colors.transparent),
            ),
          );
          children.add(
            TextSpan(
              text: content,
              style: (style ?? const TextStyle()).copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
              ),
            ),
          );
          children.add(
            const TextSpan(
              text: '**',
              style: TextStyle(fontSize: 0.001, color: Colors.transparent),
            ),
          );
        }
        // 5. *italic*
        else if (fullMatch.startsWith('*') &&
            fullMatch.endsWith('*') &&
            fullMatch.length >= 2) {
          final content = fullMatch.substring(1, fullMatch.length - 1);
          children.add(
            const TextSpan(
              text: '*',
              style: TextStyle(fontSize: 0.001, color: Colors.transparent),
            ),
          );
          children.add(
            TextSpan(
              text: content,
              style: (style ?? const TextStyle()).copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.textPrimary(context),
              ),
            ),
          );
          children.add(
            const TextSpan(
              text: '*',
              style: TextStyle(fontSize: 0.001, color: Colors.transparent),
            ),
          );
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
  final ValueChanged<Uint8List>? onImageFilePicked;

  const FormMarkdown({
    super.key,
    required this.controller,
    this.onImageFilePicked,
  });

  @override
  State<FormMarkdown> createState() => _FormMarkdownState();
}

class _FormMarkdownState extends State<FormMarkdown> {
  double _editorHeight = 320;

  String _previousText = '';
  TextSelection _previousSelection = const TextSelection.collapsed(offset: 0);
  bool _isProgrammaticChange = false;

  final List<TextEditingValue> _undoStack = [];
  final List<TextEditingValue> _redoStack = [];

  @override
  void initState() {
    super.initState();
    _previousText = widget.controller.text;
    _previousSelection = widget.controller.selection;
    _undoStack.add(widget.controller.value);
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _pushUndoState(TextEditingValue value) {
    if (_undoStack.isEmpty || _undoStack.last.text != value.text) {
      _undoStack.add(value);
      if (_undoStack.length > 50) _undoStack.removeAt(0);
      _redoStack.clear();
      setState(() {});
    }
  }

  void _undo() {
    if (_undoStack.length > 1) {
      final current = _undoStack.removeLast();
      _redoStack.add(current);
      final previous = _undoStack.last;
      _setControllerState(previous.text, previous.selection, isUndoRedo: true);
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      final next = _redoStack.removeLast();
      _undoStack.add(next);
      _setControllerState(next.text, next.selection, isUndoRedo: true);
    }
  }

  void _setControllerState(
    String text,
    TextSelection selection, {
    bool isUndoRedo = false,
  }) {
    _isProgrammaticChange = true;
    final newValue = TextEditingValue(text: text, selection: selection);
    widget.controller.value = newValue;
    _previousText = text;
    _previousSelection = selection;
    _isProgrammaticChange = false;

    if (!isUndoRedo) {
      _pushUndoState(newValue);
    } else {
      setState(() {});
    }
  }

  void _onControllerChanged() {
    if (_isProgrammaticChange) return;

    final text = widget.controller.text;
    final selection = widget.controller.selection;

    // A click/keystroke landed inside an existing image tag instead of
    // beside it — bounce the edit back instead of letting the tag corrupt.
    if (_editBreaksImageTag(_previousText, text)) {
      _isProgrammaticChange = true;
      widget.controller.value = TextEditingValue(
        text: _previousText,
        selection: _previousSelection,
      );
      _isProgrammaticChange = false;
      return;
    }

    _pushUndoState(widget.controller.value);

    final oldCursor = _previousSelection.isValid
        ? _previousSelection.start
        : -1;

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

  void _formatListPrefix({required bool isNumbered}) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    if (!selection.isValid) return;

    final start = selection.start;
    final end = selection.end;

    final lineStart = text.lastIndexOf('\n', start > 0 ? start - 1 : 0);
    final actualStart = lineStart == -1 ? 0 : lineStart + 1;

    final selectedBlock = text.substring(actualStart, end);
    final lines = selectedBlock.split('\n');

    final formattedLines = <String>[];
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final prefix = isNumbered ? '${i + 1}. ' : '- ';
      if (line.startsWith('- ')) {
        formattedLines.add(line.substring(2));
      } else if (RegExp(r'^\d+\.\s').hasMatch(line)) {
        formattedLines.add(line.replaceFirst(RegExp(r'^\d+\.\s'), ''));
      } else {
        formattedLines.add('$prefix$line');
      }
    }

    final newBlock = formattedLines.join('\n');
    final newText = text.replaceRange(actualStart, end, newBlock);

    _setControllerState(
      newText,
      TextSelection(
        baseOffset: actualStart,
        extentOffset: actualStart + newBlock.length,
      ),
    );
  }

  void _toggleFormat(String tag) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    if (!selection.isValid) return;

    if (!selection.isCollapsed) {
      final selectedText = selection.textInside(text);

      if (tag == '**') {
        if (selectedText.startsWith('***') &&
            selectedText.endsWith('***') &&
            selectedText.length >= 6) {
          final unwrapped = selectedText.substring(2, selectedText.length - 2);
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
        } else if (selectedText.startsWith('**') &&
            selectedText.endsWith('**') &&
            selectedText.length >= 4) {
          final unwrapped = selectedText.substring(2, selectedText.length - 2);
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
          final wrapped = '**$selectedText**';
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
      } else if (tag == '*') {
        if (selectedText.startsWith('***') &&
            selectedText.endsWith('***') &&
            selectedText.length >= 6) {
          final unwrapped = selectedText.substring(1, selectedText.length - 1);
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
        } else if (selectedText.startsWith('*') &&
            !selectedText.startsWith('**') &&
            selectedText.endsWith('*') &&
            !selectedText.endsWith('**') &&
            selectedText.length >= 2) {
          final unwrapped = selectedText.substring(1, selectedText.length - 1);
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
          final wrapped = '*$selectedText*';
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

  Future<void> _pickAndInsertImageFile() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (widget.onImageFilePicked != null) {
      widget.onImageFilePicked!(bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): _undo,
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): _undo,
        const SingleActivator(
          LogicalKeyboardKey.keyZ,
          control: true,
          shift: true,
        ): _redo,
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true):
            _redo,
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): _redo,
        const SingleActivator(LogicalKeyboardKey.keyY, meta: true): _redo,
        const SingleActivator(LogicalKeyboardKey.keyB, control: true): () =>
            _toggleFormat('**'),
        const SingleActivator(LogicalKeyboardKey.keyB, meta: true): () =>
            _toggleFormat('**'),
        const SingleActivator(LogicalKeyboardKey.keyI, control: true): () =>
            _toggleFormat('*'),
        const SingleActivator(LogicalKeyboardKey.keyI, meta: true): () =>
            _toggleFormat('*'),
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
                    tooltip: 'Insert Image',
                    icon: const Icon(LucideIcons.image, size: 16),
                    onPressed: _pickAndInsertImageFile,
                  ),
                  IconButton(
                    tooltip: 'Bullet List',
                    icon: const Icon(LucideIcons.list, size: 16),
                    onPressed: () => _formatListPrefix(isNumbered: false),
                  ),
                  IconButton(
                    tooltip: 'Numbered List',
                    icon: const Icon(LucideIcons.listOrdered, size: 16),
                    onPressed: () => _formatListPrefix(isNumbered: true),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Undo (Ctrl+Z)',
                    icon: const Icon(LucideIcons.undo, size: 16),
                    onPressed: _undoStack.length > 1 ? _undo : null,
                  ),
                  IconButton(
                    tooltip: 'Redo (Ctrl+Y)',
                    icon: const Icon(LucideIcons.redo, size: 16),
                    onPressed: _redoStack.isNotEmpty ? _redo : null,
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
                        'Write a post...',
                        style: AppTextStyles.body(context, size: 15),
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
                              .clamp(200.0, 800.0);
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

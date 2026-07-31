// lib/utils/inline_markdown.dart

import 'package:flutter/material.dart';

/// Parses **bold**, *italic*, ***bold italic*** and leading "- " bullets
/// into styled InlineSpans for compact previews (feed cards, etc).
List<InlineSpan> parseInlineMarkdown(String text, TextStyle baseStyle) {
  text = text.replaceAllMapped(RegExp(r'^-\s+', multiLine: true), (_) => '•  ');

  final pattern = RegExp(r'(\*\*\*(.+?)\*\*\*)|(\*\*(.+?)\*\*)|(\*(.+?)\*)');

  final spans = <InlineSpan>[];
  int lastEnd = 0;

  for (final match in pattern.allMatches(text)) {
    if (match.start > lastEnd) {
      spans.add(
        TextSpan(text: text.substring(lastEnd, match.start), style: baseStyle),
      );
    }

    if (match.group(1) != null) {
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
      spans.add(
        TextSpan(
          text: match.group(4),
          style: baseStyle.copyWith(fontWeight: FontWeight.bold),
        ),
      );
    } else if (match.group(5) != null) {
      spans.add(
        TextSpan(
          text: match.group(6),
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
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
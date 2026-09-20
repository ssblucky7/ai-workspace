import 'package:flutter/material.dart';

import 'code_block.dart';

/// Parses markdown content and splits it into text segments and code blocks.
/// Returns a list of widgets (Text and CodeBlock) for rendering.
class MarkdownContent extends StatelessWidget {
  const MarkdownContent({
    super.key,
    required this.content,
    this.style,
  });

  final String content;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final segments = _parseMarkdown(content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: segments.map((segment) {
        if (segment.isCode) {
          return CodeBlock(code: segment.content, language: segment.language);
        } else {
          return SelectableText(
            segment.content,
            style: style,
          );
        }
      }).toList(),
    );
  }

  List<_MarkdownSegment> _parseMarkdown(String content) {
    final segments = <_MarkdownSegment>[];
    final lines = content.split('\n');
    int i = 0;

    while (i < lines.length) {
      final line = lines[i];

      // Check for code block start
      final codeBlockMatch = RegExp(r'^```(\w*)$').firstMatch(line);
      if (codeBlockMatch != null) {
        final language = codeBlockMatch.group(1);
        final codeLines = <String>[];
        i++;

        // Collect code lines until closing ```
        while (i < lines.length && !lines[i].trim().startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }

        // Skip closing ```
        if (i < lines.length) i++;

        final code = codeLines.join('\n');
        if (code.isNotEmpty) {
          segments.add(_MarkdownSegment(
            content: code,
            isCode: true,
            language: language?.isNotEmpty == true ? language : null,
          ));
        }
      } else {
        // Regular text - collect consecutive non-code lines
        final textLines = <String>[];
        while (i < lines.length) {
          final line = lines[i];
          final codeBlockMatch = RegExp(r'^```(\w*)$').firstMatch(line);
          if (codeBlockMatch != null) break;
          textLines.add(line);
          i++;
        }
        if (textLines.isNotEmpty) {
          segments.add(_MarkdownSegment(
            content: textLines.join('\n'),
            isCode: false,
          ));
        }
      }
    }

    // Filter out empty segments
    return segments.where((s) => s.content.trim().isNotEmpty).toList();
  }
}

class _MarkdownSegment {
  const _MarkdownSegment({
    required this.content,
    required this.isCode,
    this.language,
  });

  final String content;
  final bool isCode;
  final String? language;
}

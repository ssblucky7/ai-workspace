import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A widget that renders markdown code blocks with syntax highlighting and copy button.
/// Parses ```language\ncode\n``` patterns in text.
class CodeBlock extends StatelessWidget {
  const CodeBlock({
    super.key,
    required this.code,
    this.language,
  });

  final String code;
  final String? language;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF3D3D3D) : const Color(0xFFE0E0E0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with language label and copy button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFEEEEEE),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF3D3D3D) : const Color(0xFFE0E0E0),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (language != null && language!.isNotEmpty)
                  Text(
                    language!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontFamily: 'monospace',
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  tooltip: 'Copy code',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Code copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Code content
          Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              code,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

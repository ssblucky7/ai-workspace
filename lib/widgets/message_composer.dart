import 'package:flutter/material.dart';

/// Multiline chat input with send button, character-count guard, and
/// keyboard-safe layout. The send action is disabled while [isSending] or
/// the trimmed input is empty.
class MessageComposer extends StatefulWidget {
  const MessageComposer({
    super.key,
    required this.onSend,
    this.isSending = false,
    this.hint = 'Type a message…',
  });

  final ValueChanged<String> onSend;
  final bool isSending;
  final String hint;

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isSending) return;
    widget.onSend(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final viewInsets = mediaQuery.viewInsets;
    final padding = mediaQuery.padding;
    
    // Calculate bottom padding to avoid system navigation bar and keyboard
    final bottomPadding = 12 + viewInsets.bottom + padding.bottom;
    
    return SafeArea(
      top: false,
      bottom: true,
      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          top: 8,
          bottom: bottomPadding,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: !widget.isSending,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                maxLines: 5,
                minLines: 1,
                maxLength: 32000,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, _) {
                final canSend = value.text.trim().isNotEmpty && !widget.isSending;
                return IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: canSend
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHigh,
                    foregroundColor: canSend
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: canSend ? _submit : null,
                  icon: widget.isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  tooltip: 'Send message',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

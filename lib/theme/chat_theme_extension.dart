import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Theme-specific styling for chat message bubbles.
///
/// Kept as a [ThemeExtension] so bubbles switch correctly with the app theme
/// without any hardcoded colors inside the bubble widget.
@immutable
class ChatThemeExtension extends ThemeExtension<ChatThemeExtension> {
  const ChatThemeExtension({
    required this.userBubble,
    required this.userBubbleText,
    required this.assistantBubble,
    required this.assistantBubbleText,
    required this.failedBubble,
    required this.failedBubbleText,
  });

  final Color userBubble;
  final Color userBubbleText;
  final Color assistantBubble;
  final Color assistantBubbleText;
  final Color failedBubble;
  final Color failedBubbleText;

  @override
  ChatThemeExtension copyWith({
    Color? userBubble,
    Color? userBubbleText,
    Color? assistantBubble,
    Color? assistantBubbleText,
    Color? failedBubble,
    Color? failedBubbleText,
  }) => ChatThemeExtension(
    userBubble: userBubble ?? this.userBubble,
    userBubbleText: userBubbleText ?? this.userBubbleText,
    assistantBubble: assistantBubble ?? this.assistantBubble,
    assistantBubbleText: assistantBubbleText ?? this.assistantBubbleText,
    failedBubble: failedBubble ?? this.failedBubble,
    failedBubbleText: failedBubbleText ?? this.failedBubbleText,
  );

  @override
  ChatThemeExtension lerp(ChatThemeExtension? other, double t) {
    if (other is! ChatThemeExtension) return this;
    return ChatThemeExtension(
      userBubble: Color.lerp(userBubble, other.userBubble, t)!,
      userBubbleText: Color.lerp(userBubbleText, other.userBubbleText, t)!,
      assistantBubble: Color.lerp(assistantBubble, other.assistantBubble, t)!,
      assistantBubbleText: Color.lerp(
        assistantBubbleText,
        other.assistantBubbleText,
        t,
      )!,
      failedBubble: Color.lerp(failedBubble, other.failedBubble, t)!,
      failedBubbleText: Color.lerp(
        failedBubbleText,
        other.failedBubbleText,
        t,
      )!,
    );
  }
}

/// Convenience accessor: never null because both app themes register the
/// extension; the fallback keeps the widget defensive if used in isolation.
ChatThemeExtension chatTheme(BuildContext context) =>
    Theme.of(context).extension<ChatThemeExtension>() ??
    const ChatThemeExtension(
      userBubble: AppColors.primaryContainerLight,
      userBubbleText: Color(0xFF1B1B1F),
      assistantBubble: Color(0xFFF2F1EC),
      assistantBubbleText: Color(0xFF1B1B1F),
      failedBubble: Color(0xFFFFEDEA),
      failedBubbleText: Color(0xFFBA1A1A),
    );

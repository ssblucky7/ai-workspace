import 'package:flutter/material.dart';

/// Simple aligned avatar placeholder: circular container with the user's
/// initials or a generic icon.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({super.key, required this.initials, this.size = 44});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

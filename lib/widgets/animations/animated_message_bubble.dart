import 'package:flutter/material.dart';

/// A wrapper that animates the entrance of chat message bubbles.
/// Uses a staggered slide + fade animation for smooth appearance.
class AnimatedMessageBubble extends StatefulWidget {
  const AnimatedMessageBubble({
    super.key,
    required this.child,
    required this.index,
    required this.isUser,
    this.delay = Duration.zero,
  });

  final Widget child;
  final int index;
  final bool isUser;
  final Duration delay;

  @override
  State<AnimatedMessageBubble> createState() => _AnimatedMessageBubbleState();
}

class _AnimatedMessageBubbleState extends State<AnimatedMessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    final beginOffset = widget.isUser ? const Offset(0.3, 0) : const Offset(-0.3, 0);
    _slideAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

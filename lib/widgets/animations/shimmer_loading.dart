import 'package:flutter/material.dart';

/// A shimmer loading effect for skeleton screens.
class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _clamp(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color resolvedBaseColor = widget.baseColor ?? 
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    final Color resolvedHighlightColor = widget.highlightColor ?? 
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [resolvedBaseColor, resolvedHighlightColor, resolvedBaseColor],
          stops: [
            _clamp(_controller.value - 0.3, 0.0, 1.0),
            _clamp(_controller.value, 0.0, 1.0),
            _clamp(_controller.value + 0.3, 0.0, 1.0),
          ],
        ).createShader(bounds),
        blendMode: BlendMode.srcATop,
        child: widget.child,
      ),
    );
  }
}

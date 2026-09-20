import 'package:flutter/material.dart';

/// Page transition animations for Hero-style navigation.
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  SlidePageRoute({
    required Widget page,
    super.settings,
    this.direction = AxisDirection.right,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final begin = Offset(
              direction == AxisDirection.right ? 1.0 : -1.0,
              0,
            );
            final end = Offset.zero;
            final curve = Curves.easeInOutCubic;

            var tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
        );

  final AxisDirection direction;
  final Duration duration;
}

/// Fade + scale transition for dialogs and bottom sheets.
class ScaleFadeTransition<T> extends PageRouteBuilder<T> {
  ScaleFadeTransition({
    required Widget page,
    super.settings,
    this.duration = const Duration(milliseconds: 250),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          opaque: false,
          barrierColor: Colors.black54,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final scale = Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
            final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            );

            return FadeTransition(
              opacity: fade,
              child: ScaleTransition(
                scale: scale,
                child: child,
              ),
            );
          },
        );

  final Duration duration;
}

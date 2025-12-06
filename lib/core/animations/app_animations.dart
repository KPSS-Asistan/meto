import 'package:flutter/material.dart';

/// App-wide animation constants and utilities
/// Material Design 3 standardına uygun, hızlı ve performanslı
class AppAnimations {
  // Duration constants (Material Design 3)
  static const Duration fast = Duration(milliseconds: 100);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);

  // Curves (Material Design 3)
  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve standard = Curves.easeInOut;
  static const Curve decelerate = Curves.easeOut;
  static const Curve accelerate = Curves.easeIn;

  /// Fade in animation (en performanslı)
  static Widget fadeIn({
    required Widget child,
    Duration duration = normal,
    Curve curve = emphasized,
    double begin = 0.0,
    double end = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Scale animation (butona basma efekti)
  static Widget scale({
    required Widget child,
    Duration duration = fast,
    Curve curve = emphasized,
    double begin = 0.95,
    double end = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Slide animation (sayfa geçişleri)
  static Widget slideIn({
    required Widget child,
    Duration duration = normal,
    Curve curve = emphasized,
    Offset begin = const Offset(0, 0.05),
    Offset end = Offset.zero,
  }) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Combined fade + slide (en yaygın)
  static Widget fadeSlideIn({
    required Widget child,
    Duration duration = normal,
    Curve curve = emphasized,
    Offset slideBegin = const Offset(0, 20),
    double fadeBegin = 0.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: fadeBegin + (1.0 - fadeBegin) * value,
          child: Transform.translate(
            offset: Offset(
              slideBegin.dx * (1 - value),
              slideBegin.dy * (1 - value),
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// Staggered list animation (liste itemleri için)
  static Widget staggeredList({
    required int index,
    required Widget child,
    Duration duration = normal,
    int delayMs = 50,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration + Duration(milliseconds: delayMs * index),
      curve: emphasized,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// Shimmer effect (loading için)
  static Widget shimmer({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -1.0, end: 2.0),
      duration: duration,
      curve: Curves.linear,
      builder: (context, value, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                value - 0.3,
                value,
                value + 0.3,
              ],
              colors: const [
                Colors.transparent,
                Colors.white24,
                Colors.transparent,
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: child,
    );
  }

  /// Ripple effect (butona basma)
  static Widget ripple({
    required Widget child,
    required VoidCallback onTap,
    Color? color,
    BorderRadius? borderRadius,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        splashColor: color?.withValues(alpha: 0.1),
        highlightColor: color?.withValues(alpha: 0.05),
        child: child,
      ),
    );
  }

  /// Hero animation wrapper
  static Widget hero({
    required String tag,
    required Widget child,
  }) {
    return Hero(
      tag: tag,
      child: Material(
        color: Colors.transparent,
        child: child,
      ),
    );
  }

  /// Bounce animation (success feedback)
  static Widget bounce({
    required Widget child,
    Duration duration = const Duration(milliseconds: 600),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Rotation animation (refresh icon)
  static Widget rotate({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1000),
    bool repeat = true,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: Curves.linear,
      builder: (context, value, child) {
        return Transform.rotate(
          angle: value * 2 * 3.14159,
          child: child,
        );
      },
      onEnd: repeat
          ? () {
              // Repeat animation
            }
          : null,
      child: child,
    );
  }

  /// Pulse animation (notification badge)
  static Widget pulse({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1000),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 1.2),
      duration: duration,
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: 2.0 - value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Animated list item widget
class AnimatedListItem extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration duration;
  final int delayMs;

  const AnimatedListItem({
    super.key,
    required this.index,
    required this.child,
    this.duration = AppAnimations.normal,
    this.delayMs = 50,
  });

  @override
  Widget build(BuildContext context) {
    return AppAnimations.staggeredList(
      index: index,
      duration: duration,
      delayMs: delayMs,
      child: child,
    );
  }
}

/// Animated page wrapper
class AnimatedPage extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const AnimatedPage({
    super.key,
    required this.child,
    this.duration = AppAnimations.normal,
  });

  @override
  Widget build(BuildContext context) {
    return AppAnimations.fadeSlideIn(
      duration: duration,
      child: child,
    );
  }
}

/// Animated card wrapper
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;

  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.duration = AppAnimations.fast,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: widget.duration,
        curve: AppAnimations.emphasized,
        child: widget.child,
      ),
    );
  }
}

/// Page transition helpers (GoRouter için)
/// Not: GoRouter'da pageBuilder içinde kullanılır
class AppPageTransition {
  /// Fade transition widget
  static Widget fadeTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  /// Slide transition widget
  static Widget slideTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child, {
    Offset begin = const Offset(1.0, 0.0),
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: begin,
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: AppAnimations.emphasized,
      )),
      child: child,
    );
  }

  /// Scale transition widget
  static Widget scaleTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.9,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: AppAnimations.emphasized,
      )),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }
}

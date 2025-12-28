import 'package:flutter/material.dart';

/// ⚡ Optimized Widget Collection
/// Performans için optimize edilmiş widget'lar

/// Optimized Text - const constructor ile
class OptText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const OptText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Optimized Container with RepaintBoundary
class OptContainer extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Decoration? decoration;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;
  final bool useRepaintBoundary;

  const OptContainer({
    super.key,
    this.child,
    this.padding,
    this.margin,
    this.decoration,
    this.width,
    this.height,
    this.alignment,
    this.useRepaintBoundary = false,
  });

  @override
  Widget build(BuildContext context) {
    final container = Container(
      padding: padding,
      margin: margin,
      decoration: decoration,
      width: width,
      height: height,
      alignment: alignment,
      child: child,
    );

    return useRepaintBoundary ? RepaintBoundary(child: container) : container;
  }
}

/// Optimized Card with shadow caching
class OptCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? color;
  final Color? borderColor;
  final double elevation;
  final VoidCallback? onTap;

  const OptCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.color,
    this.borderColor,
    this.elevation = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = color ?? (isDark ? const Color(0xFF1E293B) : Colors.white);
    final border = borderColor ?? (isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6));

    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: border),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: elevation * 2,
                  offset: Offset(0, elevation),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Padding(
              padding: padding ?? EdgeInsets.zero,
              child: child,
            ),
          ),
        ),
      ),
    );

    return RepaintBoundary(child: card);
  }
}

/// Optimized Icon Button
class OptIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;
  final String? tooltip;

  const OptIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.size = 24,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: size, color: color),
      onPressed: onPressed,
      tooltip: tooltip,
      splashRadius: size * 0.8,
      constraints: BoxConstraints(
        minWidth: size + 16,
        minHeight: size + 16,
      ),
      padding: EdgeInsets.zero,
    );
  }
}

/// Spacing widgets (const için)
class Gap extends StatelessWidget {
  final double size;
  final bool horizontal;

  const Gap(this.size, {super.key, this.horizontal = false});
  
  const Gap.h(this.size, {super.key}) : horizontal = true;
  const Gap.v(this.size, {super.key}) : horizontal = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: horizontal ? size : null,
      height: horizontal ? null : size,
    );
  }
}

/// Common gaps
class Gaps {
  static const h4 = SizedBox(width: 4);
  static const h8 = SizedBox(width: 8);
  static const h12 = SizedBox(width: 12);
  static const h16 = SizedBox(width: 16);
  static const h20 = SizedBox(width: 20);
  static const h24 = SizedBox(width: 24);
  
  static const v4 = SizedBox(height: 4);
  static const v8 = SizedBox(height: 8);
  static const v12 = SizedBox(height: 12);
  static const v16 = SizedBox(height: 16);
  static const v20 = SizedBox(height: 20);
  static const v24 = SizedBox(height: 24);
  static const v32 = SizedBox(height: 32);
}

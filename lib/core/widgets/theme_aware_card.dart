import 'package:flutter/material.dart';

/// Theme-aware card widget for consistent dark mode support
class ThemeAwareCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final VoidCallback? onTap;
  final Color? customColor;

  const ThemeAwareCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.onTap,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final container = Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: customColor ?? Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(borderRadius ?? 18),
        border: Border.all(
          color: isDark 
              ? const Color(0xFF334155) 
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: container,
      );
    }

    return container;
  }
}

/// Theme-aware text for consistent dark mode support
class ThemeAwareText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool isPrimary;

  const ThemeAwareText(
    this.text, {
    super.key,
    this.fontSize,
    this.fontWeight,
    this.style,
    this.maxLines,
    this.overflow,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final defaultColor = isPrimary
        ? (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))
        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280));

    return Text(
      text,
      style: style?.copyWith(
        fontSize: fontSize ?? style?.fontSize,
        fontWeight: fontWeight ?? style?.fontWeight,
        color: style?.color ?? defaultColor,
      ) ?? TextStyle(
        fontSize: fontSize ?? 15,
        fontWeight: fontWeight,
        color: defaultColor,
      ),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

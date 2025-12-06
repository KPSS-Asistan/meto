import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Theme-aware header widget for consistent dark mode support
class ThemeAwareHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onClose;
  final List<Widget>? actions;

  const ThemeAwareHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onClose,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ RepaintBoundary - Header statik, repaint'e gerek yok
    return RepaintBoundary(
      child: Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 24),
            onPressed: onClose ?? () => context.pop(),
            style: IconButton.styleFrom(
              backgroundColor: isDark 
                  ? const Color(0xFF334155) 
                  : const Color(0xFFF5F5F5),
              foregroundColor: isDark 
                  ? const Color(0xFFF1F5F9) 
                  : const Color(0xFF1C1B1F),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark 
                        ? const Color(0xFFF1F5F9) 
                        : const Color(0xFF1C1B1F),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark 
                          ? const Color(0xFF94A3B8) 
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:kpss_2026/core/theme/app_colors.dart';

/// Açılır/kapanır section widget
/// Oval arka plan, icon solda, başlık ortada, ok sağda
class ExpandableSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const ExpandableSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  State<ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<ExpandableSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = true;
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        // Başlık - arka plan yok, sadece yazı
        InkWell(
          onTap: _toggleExpanded,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 8,
            ),
            child: Row(
              children: [
                // Sol - Icon
                Icon(
                  widget.icon,
                  size: 22,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
                // Başlık - ortalanmış
                Expanded(
                  child: Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                // Sağ - Ok
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // İçerik
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isExpanded ? widget.child : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

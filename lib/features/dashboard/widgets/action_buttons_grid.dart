import 'package:flutter/material.dart';
import 'package:kpss_2026/core/theme/app_colors.dart';

class ActionButtonsGrid extends StatelessWidget {
  final VoidCallback onDenemeTap;
  final VoidCallback onHatalarTap;
  final VoidCallback onFavorilerTap;

  const ActionButtonsGrid({
    super.key,
    required this.onDenemeTap,
    required this.onHatalarTap,
    required this.onFavorilerTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      children: [
        // Deneme butonu
        Expanded(
          child: _buildActionButton(
            context: context,
            icon: Icons.shuffle_rounded,
            label: 'Deneme',
            color: const Color(0xFFFF6B35),
            isDark: isDark,
            onTap: onDenemeTap,
          ),
        ),
        const SizedBox(width: 10),
        // Hatalarım butonu
        Expanded(
          child: _buildActionButton(
            context: context,
            icon: Icons.close_rounded,
            label: 'Hatalarım',
            color: const Color(0xFFDC2626),
            isDark: isDark,
            onTap: onHatalarTap,
          ),
        ),
        const SizedBox(width: 10),
        // Favorilerim butonu
        Expanded(
          child: _buildActionButton(
            context: context,
            icon: Icons.star_rounded,
            label: 'Favoriler',
            color: const Color(0xFFD97706),
            isDark: isDark,
            onTap: onFavorilerTap,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

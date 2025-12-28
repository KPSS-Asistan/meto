import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Profil sayfası için yeniden kullanılabilir menü öğesi
class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;
  final bool isDark;
  final int animationIndex;
  final bool isPremiumLocked;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
    required this.isDark,
    this.animationIndex = 0,
    this.isPremiumLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isPremiumLocked ? Colors.grey : accentColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Icon with lock overlay
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, color: effectiveColor, size: 26),
                    if (isPremiumLocked)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF818CF8), Color(0xFFA78BFA)],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            LucideIcons.lock,
                            size: 8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isPremiumLocked
                                  ? (isDark ? Colors.grey.shade500 : Colors.grey.shade600)
                                  : (isDark ? Colors.white : const Color(0xFF1E293B)),
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (isPremiumLocked) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF818CF8), Color(0xFFA78BFA)],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'PRO',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isPremiumLocked ? LucideIcons.crown : LucideIcons.chevronRight,
                  color: isPremiumLocked
                      ? const Color(0xFF818CF8)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.3)
                          : const Color(0xFF94A3B8)),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (80 + animationIndex * 50).ms).slideX(begin: 0.02, end: 0);
  }
}

/// Profil sayfası için section başlığı
class ProfileSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const ProfileSectionHeader({
    super.key,
    required this.title,
    required this.icon,
  });

  static const _secondaryTextColor = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: _secondaryTextColor,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: _secondaryTextColor,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 100.ms);
  }
}

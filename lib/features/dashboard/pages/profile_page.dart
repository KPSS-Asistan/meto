import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:moon_design/moon_design.dart';
import 'package:kpss_2026/features/profile/stats_page.dart';
import 'package:kpss_2026/features/profile/achievements_page.dart';

/// Moon Design System ile modernize edilmiş Profil Sayfası
/// Profesyonel, minimalist ve fütüristik tasarım dili
class ProfilePage extends StatelessWidget {
  final String? displayName;
  const ProfilePage({super.key, this.displayName});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final moonColors = context.moonColors;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          physics: const BouncingScrollPhysics(),
          children: [
            // Section: Performans
            _buildSectionHeader('Performans', Icons.bar_chart_rounded, moonColors),
            const SizedBox(height: 12),
            _buildMoonMenuItem(
              context: context,
              icon: Icons.trending_up_rounded,
              title: 'İstatistikler',
              subtitle: 'Performans analizi ve grafikler',
              accentColor: moonColors?.piccolo ?? const Color(0xFF6366F1),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsPage())),
              isDark: isDark,
              index: 0,
            ),
            _buildMoonMenuItem(
              context: context,
              icon: Icons.emoji_events_rounded,
              title: 'Başarılar',
              subtitle: 'Rozetler ve kazanımlar',
              accentColor: const Color(0xFFF59E0B),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AchievementsPage())),
              isDark: isDark,
              index: 1,
            ),
            _buildMoonMenuItem(
              context: context,
              icon: Icons.calendar_month_rounded,
              title: 'Çalışma Takvimi',
              subtitle: 'Günlük seri ve hedefler',
              accentColor: const Color(0xFFEA580C),
              onTap: () => context.push('/streak-calendar'),
              isDark: isDark,
              index: 2,
            ),
            _buildMoonMenuItem(
              context: context,
              icon: Icons.auto_awesome_rounded,
              title: 'Ders Programı',
              subtitle: 'Kişisel haftalık çalışma planı',
              accentColor: const Color(0xFF8B5CF6),
              onTap: () => context.push('/study-schedule'),
              isDark: isDark,
              index: 3,
            ),

            const SizedBox(height: 24),

            // Section: Ayarlar
            _buildSectionHeader('Uygulama', Icons.settings_rounded, moonColors),
            const SizedBox(height: 12),
            _buildMoonMenuItem(
              context: context,
              icon: Icons.tune_rounded,
              title: 'Ayarlar',
              subtitle: 'Tema, bildirimler ve tercihler',
              accentColor: const Color(0xFF14B8A6),
              onTap: () => context.push('/settings'),
              isDark: isDark,
              index: 4,
            ),
            _buildMoonMenuItem(
              context: context,
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Geri Bildirim',
              subtitle: 'Öneri ve sorunlarınızı paylaşın',
              accentColor: const Color(0xFFEC4899),
              onTap: () => context.push('/feedback'),
              isDark: isDark,
              index: 5,
            ),

            const SizedBox(height: 24),

            // Section: Destek
            _buildSectionHeader('Destek', Icons.help_outline_rounded, moonColors),
            const SizedBox(height: 12),
            _buildMoonMenuItem(
              context: context,
              icon: Icons.quiz_rounded,
              title: 'Yardım Merkezi',
              subtitle: 'Sık sorulan sorular',
              accentColor: const Color(0xFF22C55E),
              onTap: () => context.push('/help'),
              isDark: isDark,
              index: 6,
            ),
            _buildMoonMenuItem(
              context: context,
              icon: Icons.info_outline_rounded,
              title: 'Hakkında',
              subtitle: 'Sürüm ve lisans bilgileri',
              accentColor: const Color(0xFF3B82F6),
              onTap: () => context.push('/about'),
              isDark: isDark,
              index: 7,
            ),

            const SizedBox(height: 32),

            // Logout Button
            _buildLogoutButton(context, isDark),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// Section header with icon
  Widget _buildSectionHeader(String title, IconData icon, MoonColors? moonColors) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: moonColors?.trunks ?? const Color(0xFF64748B),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: moonColors?.trunks ?? const Color(0xFF64748B),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 100.ms);
  }

  /// Moon Design styled menu item - clean, flat icons (like stats page)
  Widget _buildMoonMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required VoidCallback onTap,
    required bool isDark,
    required int index,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MoonMenuItem(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        backgroundColor: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white,
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              // Sadece ikon - arka plan YOK
              Icon(icon, color: accentColor, size: 26),
              const SizedBox(width: 14),
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        letterSpacing: -0.2,
                      ),
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
              // Arrow indicator
              Icon(
                Icons.chevron_right_rounded,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.3)
                    : const Color(0xFF94A3B8),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (80 + index * 50).ms).slideX(begin: 0.02, end: 0);
  }

  /// Clean logout button
  Widget _buildLogoutButton(BuildContext context, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showLogoutDialog(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.08 : 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFEF4444).withValues(alpha: 0.3),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.logout_rounded,
                color: Color(0xFFEF4444),
                size: 20,
              ),
              SizedBox(width: 10),
              Text(
                'Çıkış Yap',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  /// Logout confirmation dialog - clean design
  Future<void> _showLogoutDialog(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFEF4444),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                // Title
                Text(
                  'Çıkış Yap',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                // Message
                Text(
                  'Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 24),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isDark ? Colors.white24 : Colors.grey.shade300,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'İptal',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Çıkış Yap',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true && context.mounted) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) context.go('/auth');
    }
  }
}

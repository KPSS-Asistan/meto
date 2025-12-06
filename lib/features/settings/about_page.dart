import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Hakkında Sayfası - Modern ve Minimalist
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const _primaryBlue = Color(0xFF6366F1);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtextColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Hakkında', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        physics: const BouncingScrollPhysics(),
        children: [
          // Logo ve Versiyon
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryBlue, _primaryBlue.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 48),
                ),
                const SizedBox(height: 20),
                Text('KPSS Asistan', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 4),
                Text('2026', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: _primaryBlue)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Versiyon 1.0.0', style: TextStyle(fontSize: 13, color: _primaryBlue, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 20),

          // Açıklama
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: _primaryBlue, size: 22),
                    const SizedBox(width: 10),
                    Text('Uygulama Hakkında', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'KPSS Asistan, KPSS sınavına hazırlanan adaylar için geliştirilmiş kapsamlı bir çalışma platformudur. '
                  'Tarih, Türkçe, Coğrafya ve Vatandaşlık derslerinden binlerce soru ile pratik yapabilir, '
                  'ilerlemenizi takip edebilir ve hedeflerinize ulaşabilirsiniz.',
                  style: TextStyle(fontSize: 14, color: subtextColor, height: 1.6),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 16),

          // Özellikler
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.star_outline_rounded, color: const Color(0xFFF59E0B), size: 22),
                    const SizedBox(width: 10),
                    Text('Özellikler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFeature('📚', 'Binlerce güncel soru', subtextColor),
                _buildFeature('📊', 'Detaylı istatistikler', subtextColor),
                _buildFeature('🔥', 'Seri takip sistemi', subtextColor),
                _buildFeature('🏆', 'Başarı rozetleri', subtextColor),
                _buildFeature('📱', 'Offline çalışma modu', subtextColor),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 16),

          // İletişim
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.mail_outline_rounded, color: const Color(0xFF10B981), size: 22),
                    const SizedBox(width: 10),
                    Text('İletişim', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildContactItem(Icons.email_rounded, 'destek@kpssasistan.com', subtextColor, textColor),
                const SizedBox(height: 12),
                _buildContactItem(Icons.language_rounded, 'www.kpssasistan.com', subtextColor, textColor),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 24),

          // Footer
          Center(
            child: Text(
              '© 2024 KPSS Asistan. Tüm hakları saklıdır.',
              style: TextStyle(fontSize: 12, color: subtextColor),
            ),
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFeature(String emoji, String text, Color subtextColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(fontSize: 14, color: subtextColor)),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text, Color subtextColor, Color textColor) {
    return Row(
      children: [
        Icon(icon, color: subtextColor, size: 20),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(fontSize: 14, color: textColor)),
      ],
    );
  }
}

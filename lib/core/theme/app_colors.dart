import 'package:flutter/material.dart';

/// Academic Premium Design System - Colors
/// Minimal, professional, academic tone
class AppColors {
  AppColors._();

  // Primary - Indigo/Purple gradient
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color accent = Color(0xFF8B5CF6); // Purple

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF1F2937); // Gray 800
  static const Color textTertiary = Color(0xFF6B7280); // Gray 500

  // Background Colors
  static const Color background = Color(0xFFF9FAFB); // Gray 50
  static const Color surface = Colors.white;
  static const Color surfaceHover = Color(0xFFF3F4F6); // Gray 100

  // Border Colors
  static const Color border = Color(0xFFE5E7EB); // Gray 200
  static const Color borderLight = Color(0xFFF3F4F6); // Gray 100

  // Lesson Colors (Academic palette)
  static const Color lessonTarih = Color(0xFFDC2626); // Red
  static const Color lessonCografya = Color(0xFF059669); // Green
  static const Color lessonTurkce = Color(0xFF2563EB); // Blue
  static const Color lessonVatandaslik = Color(0xFFD97706); // Amber
  static const Color lessonMatematik = Color(0xFF7C3AED); // Purple
  static const Color lessonGenel = Color(0xFF0284C7); // Sky

  // Status Colors
  static const Color success = Color(0xFF059669); // Green 600
  static const Color error = Color(0xFFDC2626); // Red 600
  static const Color warning = Color(0xFFD97706); // Amber 600
  static const Color info = Color(0xFF0284C7); // Sky 600

  // AI Coach Gradient
  static const List<Color> aiGradient = [primary, accent];

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0F172A); // Slate 900
  static const Color darkSurface = Color(0xFF1E293B); // Slate 800
  static const Color darkSurfaceHover = Color(0xFF334155); // Slate 700
  static const Color darkTextPrimary = Color(0xFFF1F5F9); // Slate 100
  static const Color darkTextSecondary = Color(0xFFCBD5E1); // Slate 300
  static const Color darkTextTertiary = Color(0xFF94A3B8); // Slate 400
  static const Color darkBorder = Color(0xFF334155); // Slate 700
  static const Color darkBorderLight = Color(0xFF475569); // Slate 600

  // Get lesson color by name
  static Color getLessonColor(String lessonName) {
    final normalized = lessonName.toLowerCase().trim();
    final Map<String, Color> colors = {
      'tarih': lessonTarih,
      'coğrafya': lessonCografya,
      'cografya': lessonCografya,
      'türkçe': lessonTurkce,
      'turkce': lessonTurkce,
      'vatandaşlık': lessonVatandaslik,
      'vatandaslik': lessonVatandaslik,
      'matematik': lessonMatematik,
      'genel': lessonGenel,
    };
    return colors[normalized] ?? primary;
  }

  // Get lesson icon by name - Premium Distinctive Icons
  static IconData getLessonIcon(String lessonName) {
    final normalized = lessonName.toLowerCase().trim();
    final Map<String, IconData> icons = {
      'tarih': Icons.museum_rounded,           // Tarihi yapı/Müze - Klasik tarih simgesi
      'coğrafya': Icons.map_rounded,           // Harita - Coğrafya klasik
      'cografya': Icons.map_rounded,
      'türkçe': Icons.auto_stories_rounded,    // Açık kitap/Hikaye - Paragraf ve dil bilgisi
      'turkce': Icons.auto_stories_rounded,
      'vatandaşlık': Icons.how_to_vote_rounded, // Oy sandığı - Vatandaşlık
      'vatandaslik': Icons.how_to_vote_rounded,
      'matematik': Icons.pie_chart_rounded,    // Grafik - Matematik
      'eğitim bilimleri': Icons.psychology_rounded,
      'egitim bilimleri': Icons.psychology_rounded,
      'genel': Icons.school_rounded,
    };
    return icons[normalized] ?? Icons.menu_book_rounded;
  }
}

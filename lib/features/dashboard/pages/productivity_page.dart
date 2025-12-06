import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kpss_2026/core/theme/app_colors.dart';
import 'package:kpss_2026/core/constants/study_techniques_data.dart';

/// Verimlilik sayfası - Çalışma Teknikleri Kartları
class ProductivityPage extends StatelessWidget {
  const ProductivityPage({super.key});

  // Kategori verileri
  static const List<_CategoryData> _categories = [
    _CategoryData(
      id: 'timeManagement',
      title: 'Zaman Yönetimi',
      subtitle: 'Saatlerini verimli kullan',
      icon: Icons.schedule_rounded,
      color: Color(0xFF6366F1),
    ),
    _CategoryData(
      id: 'breakGuide',
      title: 'Mola Rehberi',
      subtitle: 'Nasıl dinlenmelisin?',
      icon: Icons.coffee_rounded,
      color: Color(0xFF10B981), // Green
    ),
    _CategoryData(
      id: 'examHacks',
      title: 'Sınav Taktikleri',
      subtitle: 'Net arttıran taktikler',
      icon: Icons.auto_graph_rounded,
      color: Color(0xFFF43F5E), // Rose
    ),
    _CategoryData(
      id: 'bioHacking',
      title: 'Bio-Performans',
      subtitle: 'Uyku, beslenme ve beyin',
      icon: Icons.battery_charging_full_rounded,
      color: Color(0xFF8B5CF6), // Violet
    ),
    _CategoryData(
      id: 'noteTaking',
      title: 'Not Alma Teknikleri',
      subtitle: 'Bilgiyi kalıcı kaydet',
      icon: Icons.edit_note_rounded,
      color: Color(0xFF14B8A6),
    ),
    _CategoryData(
      id: 'memory',
      title: 'Hafıza Teknikleri',
      subtitle: 'Uzun süre hatırla',
      icon: Icons.psychology_rounded,
      color: Color(0xFFF59E0B),
    ),
    _CategoryData(
      id: 'reading',
      title: 'Okuma Stratejileri',
      subtitle: 'Hızlı ve etkili oku',
      icon: Icons.menu_book_rounded,
      color: Color(0xFFEC4899),
    ),
    _CategoryData(
      id: 'studyPlanning',
      title: 'Çalışma Planlama',
      subtitle: 'Programlı ilerle',
      icon: Icons.calendar_month_rounded,
      color: Color(0xFF0EA5E9), // Sky
    ),
    _CategoryData(
      id: 'concentration',
      title: 'Odaklanma',
      subtitle: 'Dikkatini topla',
      icon: Icons.center_focus_strong_rounded,
      color: Color(0xFFEF4444),
    ),
    _CategoryData(
      id: 'motivation',
      title: 'Motivasyon',
      subtitle: 'Hedefine odaklan',
      icon: Icons.emoji_events_rounded,
      color: Color(0xFF22C55E),
    ),
    _CategoryData(
      id: 'stressManagement',
      title: 'Stres Yönetimi',
      subtitle: 'Kaygını kontrol et',
      icon: Icons.spa_rounded,
      color: Color(0xFF3B82F6),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.background,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final techniqueCount = StudyTechniquesData.getTechniquesByCategory(category.id).length;

          return Padding(
            padding: EdgeInsets.only(bottom: index < _categories.length - 1 ? 12 : 0),
            child: _CategoryCard(
              category: category,
              techniqueCount: techniqueCount,
              isDark: isDark,
            ).animate().fadeIn(delay: (40 * index).ms, duration: 350.ms).slideX(begin: 0.02, end: 0),
          );
        },
      ),
    );
  }
}

class _CategoryData {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _CategoryData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _CategoryCard extends StatelessWidget {
  final _CategoryData category;
  final int techniqueCount;
  final bool isDark;

  const _CategoryCard({
    required this.category,
    required this.techniqueCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => context.push('/productivity/category/${category.id}'),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark 
                  ? category.color.withValues(alpha: 0.15) 
                  : category.color.withValues(alpha: 0.12),
              width: 1.5,
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            children: [
              // Icon with gradient background
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      category.color,
                      category.color.withValues(alpha: 0.75),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  category.icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      category.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),

              // Count Badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: isDark ? 0.12 : 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '$techniqueCount',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: category.color,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Arrow
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.05) 
                      : Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

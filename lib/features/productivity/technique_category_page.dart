import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/models/study_technique_model.dart';
import '../../core/constants/study_techniques_data.dart';
import '../../core/theme/app_colors.dart';

class TechniqueCategoryPage extends StatelessWidget {
  final String category;

  const TechniqueCategoryPage({
    required this.category,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final techniques = StudyTechniquesData.getTechniquesByCategory(category);
    final categoryName = _getCategoryName();
    final categoryColor = _getCategoryColor();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(
          categoryName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getCategoryIcon(), size: 16, color: categoryColor),
                const SizedBox(width: 6),
                Text(
                  '${techniques.length} teknik',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: categoryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: techniques.length,
        itemBuilder: (context, index) {
          final technique = techniques[index];
          return Padding(
            padding: EdgeInsets.only(bottom: index < techniques.length - 1 ? 12 : 0),
            child: _TechniqueCard(
              technique: technique,
              color: categoryColor,
              isDark: isDark,
              index: index,
            ),
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon() {
    switch (category) {
      case 'timeManagement':
        return Icons.schedule_rounded;
      case 'motivation':
        return Icons.emoji_events_rounded;
      case 'studyPlanning':
        return Icons.calendar_month_rounded;
      case 'concentration':
        return Icons.center_focus_strong_rounded;
      case 'breakGuide':
        return Icons.coffee_rounded;
      case 'examFastLearning':
        return Icons.auto_graph_rounded;
      case 'noteMemory':
        return Icons.psychology_rounded;
      default:
        return Icons.lightbulb_rounded;
    }
  }

  String _getCategoryName() {
    switch (category) {
      case 'timeManagement':
        return 'Zaman Yönetimi';
      case 'motivation':
        return 'Motivasyon';
      case 'studyPlanning':
        return 'Çalışma Planlama';
      case 'concentration':
        return 'Odaklanma';
      case 'breakGuide':
        return 'Mola Rehberi';
      case 'examFastLearning':
        return 'Sınav & Hızlı Öğrenme';
      case 'noteMemory':
        return 'Not & Hafıza Teknikleri';
      default:
        return 'Teknikler';
    }
  }

  Color _getCategoryColor() {
    switch (category) {
      case 'timeManagement':
        return const Color(0xFF6366F1);
      case 'motivation':
        return const Color(0xFF22C55E);
      case 'studyPlanning':
        return const Color(0xFF0EA5E9);
      case 'concentration':
        return const Color(0xFFEF4444);
      case 'breakGuide':
        return const Color(0xFF10B981);
      case 'examFastLearning':
        return const Color(0xFFF43F5E);
      case 'noteMemory':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6366F1);
    }
  }
}

class _TechniqueCard extends StatelessWidget {
  final StudyTechnique technique;
  final Color color;
  final bool isDark;
  final int index;

  const _TechniqueCard({
    required this.technique,
    required this.color,
    required this.isDark,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.push('/productivity/technique/${technique.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            children: [
              // Numara
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color,
                      color.withValues(alpha: 0.75),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      technique.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      technique.shortDescription,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Arrow
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.12 : 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: color,
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (40 * index).ms, duration: 350.ms).slideX(begin: 0.02, end: 0);
  }
}

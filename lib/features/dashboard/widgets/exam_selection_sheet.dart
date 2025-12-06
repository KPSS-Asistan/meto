import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kpss_2026/core/data/topics_data.dart';
import 'package:kpss_2026/core/theme/app_colors.dart';

class ExamSelectionSheet extends StatelessWidget {
  const ExamSelectionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.shuffle_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Text(
                'Deneme Oluştur',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildExamOption(
            ctx: context,
            title: 'Hızlı Test (10 Soru)',
            subtitle: 'Rastgele bir konudan hemen test çöz',
            icon: Icons.bolt_rounded,
            color: const Color(0xFFFF6B35),
            isDark: isDark,
            onTap: () => _startQuickTest(context),
          ),
          const SizedBox(height: 12),
          _buildExamOption(
            ctx: context,
            title: 'Genel Yetenek Denemesi',
            subtitle: 'Türkçe ve Matematik (60 Soru)',
            icon: Icons.calculate_rounded,
            color: const Color(0xFF0284C7),
            isDark: isDark,
            onTap: () => _startKPSSExam(context, 'gy'),
          ),
          const SizedBox(height: 12),
          _buildExamOption(
            ctx: context,
            title: 'Genel Kültür Denemesi',
            subtitle: 'Tarih, Coğrafya, Vatandaşlık (60 Soru)',
            icon: Icons.public_rounded,
            color: const Color(0xFF059669),
            isDark: isDark,
            onTap: () => _startKPSSExam(context, 'gk'),
          ),
          const SizedBox(height: 12),
          _buildExamOption(
            ctx: context,
            title: 'Tam Deneme Sınavı',
            subtitle: 'GY + GK (120 Soru)',
            icon: Icons.school_rounded,
            color: const Color(0xFF7C3AED),
            isDark: isDark,
            onTap: () => _startKPSSExam(context, 'full'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildExamOption({
    required BuildContext ctx,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(ctx);
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startQuickTest(BuildContext context) {
    if (topicsData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Henüz konu bulunamadı')),
      );
      return;
    }
    
    final random = Random();
    final topic = topicsData[random.nextInt(topicsData.length)];
    final topicId = topic['id'] as String;
    final topicName = topic['name'] as String;
    final lessonId = topic['lesson_id'] as String;
    
    context.push(
      '/lessons/$lessonId/topics/$topicId/quiz',
      extra: {'topicName': topicName, 'lessonId': lessonId},
    );
  }

  void _startKPSSExam(BuildContext context, String examType) {
    // TODO: Exam screen implementation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$examType denemesi yakında eklenecek!')),
    );
  }
}

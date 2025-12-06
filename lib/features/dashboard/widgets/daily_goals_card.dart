import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kpss_2026/core/theme/app_colors.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';

class DailyGoalsCard extends StatelessWidget {
  const DailyGoalsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      buildWhen: (prev, curr) =>
          prev.dailyQuestionsCompleted != curr.dailyQuestionsCompleted ||
          prev.dailyExplanationsCompleted != curr.dailyExplanationsCompleted ||
          prev.dailyFlashcardsCompleted != curr.dailyFlashcardsCompleted ||
          prev.currentStreak != curr.currentStreak ||
          prev.dailyQuestionsTarget != curr.dailyQuestionsTarget ||
          prev.dailyExplanationsTarget != curr.dailyExplanationsTarget ||
          prev.dailyFlashcardsTarget != curr.dailyFlashcardsTarget,
      builder: (context, state) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final isAllCompleted = state.isAllGoalsCompleted;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık satırı
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isAllCompleted 
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      color: isAllCompleted ? AppColors.success : AppColors.warning,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Günlük Hedef',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          isAllCompleted ? 'Tamamlandı! 🎉' : 'Bugünü tamamla',
                          style: TextStyle(
                            fontSize: 12,
                            color: isAllCompleted 
                                ? AppColors.success
                                : (isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Düzenle Butonu
                  IconButton(
                    icon: Icon(Icons.edit_rounded, color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary, size: 20),
                    tooltip: 'Hedefleri Düzenle',
                    onPressed: () => _showEditTargetsDialog(context, state),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  
                  const SizedBox(width: 8),

                  // Streak badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          isAllCompleted ? AppColors.success : AppColors.warning,
                          (isAllCompleted ? AppColors.success : AppColors.warning).withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.whatshot_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${state.currentStreak}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Çizgi
              Divider(
                color: isDark ? AppColors.darkBorder : AppColors.border,
                height: 1,
              ),
              
              const SizedBox(height: 12),
              
              // Görev kartları
              Row(
                children: [
                  _buildGoalItem(
                    icon: Icons.quiz_rounded,
                    label: 'Soru',
                    current: state.dailyQuestionsCompleted,
                    target: state.dailyQuestionsTarget,
                    color: const Color(0xFFFF6B35),
                    isDark: isDark,
                  ),
                  _buildGoalItem(
                    icon: Icons.menu_book_rounded,
                    label: 'Konu',
                    current: state.dailyExplanationsCompleted,
                    target: state.dailyExplanationsTarget,
                    color: const Color(0xFF0284C7),
                    isDark: isDark,
                  ),
                  _buildGoalItem(
                    icon: Icons.style_rounded,
                    label: 'Kart',
                    current: state.dailyFlashcardsCompleted,
                    target: state.dailyFlashcardsTarget,
                    color: const Color(0xFF8B5CF6),
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditTargetsDialog(BuildContext context, DashboardState state) {
    int q = state.dailyQuestionsTarget;
    int e = state.dailyExplanationsTarget;
    int f = state.dailyFlashcardsTarget;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // ⚡ Cubit referansını dialog açılmadan önce al
    final cubit = context.read<DashboardCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              title: Text('Günlük Hedefler', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSlider(dialogContext, 'Soru Hedefi', q, 10, 200, (v) => setState(() => q = v.toInt()), isDark),
                  const SizedBox(height: 16),
                  _buildSlider(dialogContext, 'Konu Hedefi', e, 1, 10, (v) => setState(() => e = v.toInt()), isDark),
                  const SizedBox(height: 16),
                  _buildSlider(dialogContext, 'Kart Hedefi', f, 5, 100, (v) => setState(() => f = v.toInt()), isDark),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // ⚡ Önceden aldığımız cubit referansını kullan
                    cubit.updateDailyTargets(
                      questions: q,
                      explanations: e,
                      flashcards: f,
                    );
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSlider(BuildContext context, String label, int value, double min, double max, ValueChanged<double> onChanged, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87)),
            Text('$value', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          label: value.toString(),
          activeColor: AppColors.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildGoalItem({
    required IconData icon,
    required String label,
    required int current,
    required int target,
    required Color color,
    required bool isDark,
  }) {
    final isCompleted = current >= target;
    
    return Expanded(
      child: Column(
        children: [
          Icon(
            isCompleted ? Icons.check_circle_rounded : icon,
            color: isCompleted ? AppColors.success : color,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            '$current/$target',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isCompleted 
                  ? AppColors.success
                  : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

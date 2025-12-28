import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class StreakCard extends StatelessWidget {
  final int currentStreak;
  final List<bool> weekData;

  const StreakCard({
    super.key,
    required this.currentStreak,
    required this.weekData,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final today = DateTime.now().weekday; // 1 = Pazartesi, 7 = Pazar

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5722).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.flame,
                      color: Color(0xFFFF5722),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$currentStreak Günlük Seri!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        'Bu hafta istikrarın harika 🔥',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Opsiyonel: Freeze veya başka bir ikon
            ],
          ),

          const SizedBox(height: 20),

          // Week Days
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final dayIndex = index + 1; // 1-7
              final isCompleted = weekData.length > index && weekData[index];
              final isToday = dayIndex == today;
              final isFuture = dayIndex > today;

              return _buildDayItem(
                context, 
                dayIndex: dayIndex, 
                isCompleted: isCompleted,
                isToday: isToday,
                isFuture: isFuture,
                isDark: isDark,
              );
            }),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, duration: 400.ms);
  }

  Widget _buildDayItem(
    BuildContext context, {
    required int dayIndex,
    required bool isCompleted,
    required bool isToday,
    required bool isFuture,
    required bool isDark,
  }) {
    final dayNames = ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pz'];
    final label = dayNames[dayIndex - 1];

    Color bgColor;
    Color iconColor;
    IconData? icon;

    if (isCompleted) {
      bgColor = const Color(0xFF22C55E); // Success Green
      iconColor = Colors.white;
      icon = LucideIcons.check;
    } else if (isToday) {
      bgColor = const Color(0xFFFF5722).withValues(alpha: 0.1);
      iconColor = const Color(0xFFFF5722);
      icon = LucideIcons.flame; // Bugün çalışılmadıysa fire
    } else if (isFuture) {
      bgColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;
      iconColor = isDark ? Colors.grey[600]! : Colors.grey[400]!;
      icon = null;
    } else {
      // Geçmiş ve kaçırılmış
      bgColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;
      iconColor = isDark ? Colors.grey[600]! : Colors.grey[400]!;
      icon = LucideIcons.x;
    }

    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: isToday && !isCompleted
                ? Border.all(color: const Color(0xFFFF5722), width: 2)
                : null,
          ),
          child: icon != null
              ? Icon(icon, color: iconColor, size: 20)
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
            color: isToday
                ? (isDark ? Colors.white : Colors.black)
                : (isDark ? Colors.grey[500] : Colors.grey[500]),
          ),
        ),
      ],
    );
  }
}

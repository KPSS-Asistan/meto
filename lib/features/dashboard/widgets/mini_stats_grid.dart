import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:kpss_2026/core/services/quiz_stats_service.dart';
import 'package:kpss_2026/core/services/streak_service.dart';
import 'package:kpss_2026/core/services/local_progress_service.dart';

/// Mini İstatistik Grid - Dashboard için kompakt istatistik gösterimi
/// 4'lü grid: Çözülen Soru, Başarı Oranı, Okunan Konu, Günlük Seri
class MiniStatsGrid extends StatefulWidget {
  const MiniStatsGrid({super.key});

  @override
  State<MiniStatsGrid> createState() => _MiniStatsGridState();
}

class _MiniStatsGridState extends State<MiniStatsGrid> {
  int _totalSolved = 0;
  int _successRate = 0;
  int _topicsRead = 0;
  int _currentStreak = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      // Quiz Stats
      final totalSolved = await QuizStatsService.getTotalSolved();
      final successRate = await QuizStatsService.getSuccessRate();
      
      // Streak
      final currentStreak = await StreakService.getCurrentStreak();
      
      // Local Progress - Okunan konular
      final progressService = await LocalProgressService.getInstance();
      final userData = progressService.userData;
      final topicsRead = userData.topicProgress.values
          .where((p) => p.isExplanationRead == true)
          .length;

      if (mounted) {
        setState(() {
          _totalSolved = totalSolved;
          _successRate = successRate.round();
          _topicsRead = topicsRead;
          _currentStreak = currentStreak;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return _buildLoadingState(isDark);
    }

    final dividerColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: LucideIcons.clipboardCheck,
              value: _formatNumber(_totalSolved),
              label: 'Çözülen',
              color: const Color(0xFF6366F1),
              isDark: isDark,
              index: 0,
            ),
          ),
          _buildDivider(dividerColor),
          Expanded(
            child: _buildStatItem(
              icon: LucideIcons.target,
              value: '%$_successRate',
              label: 'Başarı',
              color: const Color(0xFF10B981),
              isDark: isDark,
              index: 1,
            ),
          ),
          _buildDivider(dividerColor),
          Expanded(
            child: _buildStatItem(
              icon: LucideIcons.bookOpen,
              value: '$_topicsRead',
              label: 'Okunan',
              color: const Color(0xFFF59E0B),
              isDark: isDark,
              index: 2,
            ),
          ),
          _buildDivider(dividerColor),
          Expanded(
            child: _buildStatItem(
              icon: LucideIcons.flame,
              value: '$_currentStreak',
              label: 'Seri',
              color: const Color(0xFFEF4444),
              isDark: isDark,
              index: 3,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildDivider(Color color) {
    return Container(
      width: 1,
      height: 40,
      color: color,
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isDark,
    required int index,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 21,
          color: color,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    ).animate(delay: (100 + index * 80).ms)
     .fadeIn(duration: 300.ms);
  }

  Widget _buildLoadingState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: List.generate(4, (index) => 
          Expanded(
            child: Container(
              margin: EdgeInsets.only(left: index > 0 ? 12 : 0),
              height: 80,
              decoration: BoxDecoration(
                color: isDark 
                    ? const Color(0xFF334155).withValues(alpha: 0.5)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

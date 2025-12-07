import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kpss_2026/core/services/streak_service.dart';

/// Çalışma Takvimi Sayfası - Modern ve Minimalist
class StreakCalendarPage extends StatefulWidget {
  const StreakCalendarPage({super.key});

  @override
  State<StreakCalendarPage> createState() => _StreakCalendarPageState();
}

class _StreakCalendarPageState extends State<StreakCalendarPage> {
  DateTime _selectedMonth = DateTime.now();
  Set<int> _studiedDays = {};
  int _currentStreak = 0;
  int _longestStreak = 0;
  int _totalDays = 0;
  bool _isLoading = true;

  static const _primaryBlue = Color(0xFF6366F1);
  static const _successGreen = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final studiedDays = await StreakService.getStudiedDaysForMonth(
        _selectedMonth.year,
        _selectedMonth.month,
      );
      final current = await StreakService.getCurrentStreak();
      final longest = await StreakService.getLongestStreak();
      final total = await StreakService.getTotalStudiedDays();

      if (mounted) {
        setState(() {
          _studiedDays = studiedDays;
          _currentStreak = current;
          _longestStreak = longest;
          _totalDays = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
      _isLoading = true;
    });
    _loadData();
  }

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
        title: const Text('Çalışma Takvimi', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // İstatistikler
                      _buildStats(cardColor, textColor, subtextColor),
                      const SizedBox(height: 24),
                      
                      // Takvim
                      _buildCalendar(cardColor, textColor, subtextColor, isDark),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildStats(Color cardColor, Color textColor, Color subtextColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          _buildStatItem('$_currentStreak', 'Mevcut', 'Seri', _primaryBlue, textColor, subtextColor),
          Container(width: 1, height: 50, color: subtextColor.withValues(alpha: 0.2)),
          _buildStatItem('$_longestStreak', 'En Uzun', 'Seri', _successGreen, textColor, subtextColor),
          Container(width: 1, height: 50, color: subtextColor.withValues(alpha: 0.2)),
          _buildStatItem('$_totalDays', 'Toplam', 'Çalışılan Gün', const Color(0xFFF59E0B), textColor, subtextColor),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildStatItem(String value, String l1, String l2, Color c, Color tc, Color sc) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: c)),
          const SizedBox(height: 4),
          Text(l1, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: tc)),
          Text(l2, style: TextStyle(fontSize: 11, color: sc)),
        ],
      ),
    );
  }

  Widget _buildCalendar(Color cardColor, Color textColor, Color subtextColor, bool isDark) {
    final daysInMonth = DateUtils.getDaysInMonth(_selectedMonth.year, _selectedMonth.month);
    final firstWeekday = DateTime(_selectedMonth.year, _selectedMonth.month, 1).weekday;
    final today = DateTime.now();
    final isCurrentMonth = _selectedMonth.year == today.year && _selectedMonth.month == today.month;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Ay Seçici
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => _changeMonth(-1),
                icon: Icon(Icons.chevron_left_rounded, color: textColor),
              ),
              Text(
                '${_getMonthName(_selectedMonth.month)} ${_selectedMonth.year}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
              ),
              IconButton(
                onPressed: isCurrentMonth ? null : () => _changeMonth(1),
                icon: Icon(
                  Icons.chevron_right_rounded,
                  color: isCurrentMonth ? subtextColor.withValues(alpha: 0.3) : textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Gün başlıkları
          Row(
            children: ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: subtextColor)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),

          // Günler Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: 42,
            itemBuilder: (context, index) {
              final dayOffset = index - (firstWeekday - 1);
              if (dayOffset < 1 || dayOffset > daysInMonth) {
                return const SizedBox();
              }

              final isStudied = _studiedDays.contains(dayOffset);
              final isToday = isCurrentMonth && dayOffset == today.day;
              final isFuture = isCurrentMonth && dayOffset > today.day;

              return Container(
                decoration: BoxDecoration(
                  color: isStudied
                      ? _successGreen
                      : isToday
                          ? _primaryBlue.withValues(alpha: 0.15)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isToday ? Border.all(color: _primaryBlue, width: 2) : null,
                ),
                child: Center(
                  child: Text(
                    '$dayOffset',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                      color: isStudied
                          ? Colors.white
                          : isFuture
                              ? subtextColor.withValues(alpha: 0.4)
                              : textColor,
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(_successGreen, 'Çalışıldı', subtextColor),
              const SizedBox(width: 20),
              _buildLegend(_primaryBlue, 'Bugün', subtextColor),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.03, end: 0);
  }

  Widget _buildLegend(Color color, String label, Color subtextColor) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: subtextColor)),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = ['', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 
                    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    return months[month];
  }
}

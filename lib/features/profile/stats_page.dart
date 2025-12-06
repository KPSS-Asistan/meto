import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:kpss_2026/core/theme/app_colors.dart';
import 'package:kpss_2026/core/services/quiz_stats_service.dart';
import 'package:kpss_2026/core/data/lessons_data.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  int _totalQuestions = 0;
  int _correctAnswers = 0;
  int _todaySolved = 0;
  List<Map<String, dynamic>> _weeklyStats = [];
  Map<String, Map<String, int>> _lessonStats = {};
  List<Map<String, dynamic>> _weakTopics = [];
  bool _isLoading = true;

  static const _primaryBlue = Color(0xFF6366F1);
  static const _successGreen = Color(0xFF10B981);
  static const _warningOrange = Color(0xFFF59E0B);
  static const _errorRed = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final results = await Future.wait([
        QuizStatsService.getTotalSolved(),
        QuizStatsService.getTotalCorrect(),
        QuizStatsService.getWeeklyStats(),
        QuizStatsService.getLessonStats(),
        QuizStatsService.getTodayStats(),
        QuizStatsService.getWeakTopicAnalysis(),
      ]);
      if (mounted) {
        setState(() {
          _totalQuestions = results[0] as int;
          _correctAnswers = results[1] as int;
          _weeklyStats = results[2] as List<Map<String, dynamic>>;
          _lessonStats = results[3] as Map<String, Map<String, int>>;
          _todaySolved = (results[4] as Map<String, dynamic>)['solved'] ?? 0;
          _weakTopics = results[5] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _accuracy => _totalQuestions > 0 ? (_correctAnswers / _totalQuestions * 100) : 0;

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
        title: const Text('İstatistikler', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                physics: const BouncingScrollPhysics(),
                children: [
                  // ÖZET
                  _buildSimpleStats(cardColor, textColor, subtextColor),
                  const SizedBox(height: 20),

                  // PERFORMANS
                  _buildPerformanceTrend(cardColor, textColor, subtextColor),
                  const SizedBox(height: 20),

                  // ZAYIF KONU ANALİZİ - Her zaman göster
                  _buildWeakTopicCard(cardColor, textColor, subtextColor),
                  const SizedBox(height: 20),

                  // DERSLER - Her zaman göster
                  _buildLessonPerformance(cardColor, textColor, subtextColor),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSimpleStats(Color cardColor, Color textColor, Color subtextColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(child: _statItem('$_totalQuestions', 'Toplam', 'Çözülen Soru', _primaryBlue, textColor, subtextColor)),
          Container(width: 1, height: 50, color: subtextColor.withValues(alpha: 0.2)),
          Expanded(child: _statItem('%${_accuracy.round()}', 'Başarı', 'Yüzdesi', _successGreen, textColor, subtextColor)),
          Container(width: 1, height: 50, color: subtextColor.withValues(alpha: 0.2)),
          Expanded(child: _statItem('$_todaySolved', 'Bugün', 'Çözülen Soru', _warningOrange, textColor, subtextColor)),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _statItem(String value, String l1, String l2, Color c, Color tc, Color sc) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: c)),
        const SizedBox(height: 4),
        Text(l1, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: tc)),
        Text(l2, style: TextStyle(fontSize: 11, color: sc)),
      ],
    );
  }

  Widget _buildPerformanceTrend(Color cardColor, Color textColor, Color subtextColor) {
    List<FlSpot> spots = [];
    double cumulative = 0;
    for (int i = 0; i < _weeklyStats.length; i++) {
      cumulative += (_weeklyStats[i]['solved'] as int).toDouble();
      spots.add(FlSpot(i.toDouble(), cumulative));
    }
    final hasData = spots.isNotEmpty && spots.any((s) => s.y > 0);
    if (spots.isEmpty) spots = List.generate(7, (i) => FlSpot(i.toDouble(), 0));
    final maxY = hasData ? (spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.3).clamp(5.0, 1000.0) : 10.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Performans Trendi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
              if (hasData)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: _successGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                  child: Text('+${cumulative.toInt()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _successGreen)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Son 7 günlük kümülatif ilerleme', style: TextStyle(fontSize: 12, color: subtextColor)),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: hasData
                ? LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY / 4,
                        getDrawingHorizontalLine: (v) => FlLine(color: subtextColor.withValues(alpha: 0.1), strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i >= 0 && i < _weeklyStats.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    _weeklyStats[i]['dayName'] as String,
                                    style: TextStyle(fontSize: 11, color: subtextColor, fontWeight: FontWeight.w500),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: 6,
                      minY: 0,
                      maxY: maxY,
                      lineTouchData: LineTouchData(
                        handleBuiltInTouches: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => const Color(0xFF1E293B),
                          tooltipRoundedRadius: 8,
                          tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              return LineTooltipItem(
                                '${spot.y.toInt()} soru',
                                const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.3,
                          color: _primaryBlue,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                              radius: 5,
                              color: Colors.white,
                              strokeWidth: 2.5,
                              strokeColor: _primaryBlue,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [_primaryBlue.withValues(alpha: 0.3), _primaryBlue.withValues(alpha: 0.0)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.show_chart_rounded, size: 48, color: subtextColor.withValues(alpha: 0.3)),
                        const SizedBox(height: 8),
                        Text('Soru çözdükçe grafiğin oluşacak', style: TextStyle(fontSize: 13, color: subtextColor)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.03, end: 0);
  }

  Widget _buildLessonPerformance(Color cardColor, Color textColor, Color subtextColor) {
    // Tüm dersleri listele (lessons_data'dan)
    final allLessons = lessonsData.map((l) => <String, String>{
      'id': l['id'] as String,
      'name': l['name'] as String,
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ders Performansı', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 16),
          ...allLessons.asMap().entries.map((entry) {
            final index = entry.key;
            final lesson = entry.value;
            final lessonId = lesson['id']!;
            final lessonName = lesson['name']!;
            
            // Bu ders için istatistik var mı?
            final stats = _lessonStats[lessonId];
            final solved = stats?['solved'] ?? 0;
            final correct = stats?['correct'] ?? 0;
            final accuracy = solved > 0 ? (correct / solved * 100).round() : 0;
            final color = AppColors.getLessonColor(lessonName);
            final icon = AppColors.getLessonIcon(lessonName);

            return Container(
              margin: EdgeInsets.only(bottom: index < allLessons.length - 1 ? 16 : 0),
              child: Row(
                children: [
                  // Sadece ikon
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 14),
                  // Ders bilgisi
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lessonName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          solved > 0 ? '$solved soru çözüldü · $correct doğru' : 'Henüz soru çözülmedi',
                          style: TextStyle(fontSize: 13, color: subtextColor),
                        ),
                      ],
                    ),
                  ),
                  // Başarı
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: solved == 0 
                          ? subtextColor.withValues(alpha: 0.1)
                          : (accuracy >= 70 ? _successGreen : (accuracy >= 50 ? _warningOrange : _errorRed)).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      solved > 0 ? '%$accuracy' : '-',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: solved == 0 
                            ? subtextColor 
                            : (accuracy >= 70 ? _successGreen : (accuracy >= 50 ? _warningOrange : _errorRed)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.03, end: 0);
  }

  /// Zayıf Konu Analizi - Tıklanabilir Özet Kart
  Widget _buildWeakTopicCard(Color cardColor, Color textColor, Color subtextColor) {
    final criticalCount = _weakTopics.where((t) => t['status'] == 'critical').length;
    final warningCount = _weakTopics.where((t) => t['status'] == 'warning').length;
    final improvingCount = _weakTopics.where((t) => t['status'] == 'improving').length;
    final hasWeakTopics = _weakTopics.isNotEmpty;
    
    return GestureDetector(
      onTap: () => _showWeakTopicsBottomSheet(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: hasWeakTopics 
              ? Border.all(color: _errorRed.withValues(alpha: 0.2), width: 1)
              : null,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: hasWeakTopics 
                      ? [_errorRed.withValues(alpha: 0.15), _warningOrange.withValues(alpha: 0.1)]
                      : [_successGreen.withValues(alpha: 0.15), _successGreen.withValues(alpha: 0.1)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                hasWeakTopics ? Icons.psychology_alt_rounded : Icons.verified_rounded,
                color: hasWeakTopics ? _errorRed : _successGreen,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Zayıf Konu Analizi',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (hasWeakTopics)
                    Row(
                      children: [
                        if (criticalCount > 0) _statusBadge('$criticalCount Kritik', _errorRed),
                        if (criticalCount > 0 && warningCount > 0) const SizedBox(width: 6),
                        if (warningCount > 0) _statusBadge('$warningCount Orta', _warningOrange),
                        if ((criticalCount > 0 || warningCount > 0) && improvingCount > 0) const SizedBox(width: 6),
                        if (improvingCount > 0) _statusBadge('$improvingCount ↑', _successGreen),
                      ],
                    )
                  else
                    Text(
                      _totalQuestions > 20 ? 'Tebrikler! Zayıf konu yok 👏' : 'Henüz yeterli veri yok',
                      style: TextStyle(fontSize: 13, color: _totalQuestions > 20 ? _successGreen : subtextColor),
                    ),
                ],
              ),
            ),
            // Arrow
            Icon(
              Icons.chevron_right_rounded,
              color: subtextColor,
              size: 24,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.02, end: 0);
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  void _showWeakTopicsBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtextColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: subtextColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _errorRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.psychology_alt_rounded, color: _errorRed, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Zayıf Konu Analizi',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor),
                        ),
                        Text(
                          'Üzerinde çalışman gereken konular',
                          style: TextStyle(fontSize: 13, color: subtextColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Flexible(
              child: _weakTopics.isEmpty
                  ? _buildEmptyWeakTopics(textColor, subtextColor)
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      shrinkWrap: true,
                      itemCount: _weakTopics.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildWeakTopicItem(_weakTopics[index], cardColor, textColor, subtextColor);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWeakTopics(Color textColor, Color subtextColor) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _successGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.celebration_rounded, color: _successGreen, size: 48),
          ),
          const SizedBox(height: 20),
          Text(
            _totalQuestions > 20 ? 'Tebrikler! 🎉' : 'Henüz Veri Yok',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textColor),
          ),
          const SizedBox(height: 8),
          Text(
            _totalQuestions > 20 
                ? 'Çözdüğün sorularda zayıf konu tespit edilmedi.\nBöyle devam!' 
                : 'En az 20 soru çözdükten sonra\nzayıf konuların burada gösterilecek.',
            style: TextStyle(fontSize: 14, color: subtextColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeakTopicItem(Map<String, dynamic> topic, Color cardColor, Color textColor, Color subtextColor) {
    final status = topic['status'] as String;
    final topicName = topic['topicName'] as String;
    final overallAccuracy = topic['overallAccuracy'] as int;
    final recentAccuracy = topic['recentAccuracy'] as int;
    final trend = topic['trend'] as int;
    final totalSolved = topic['totalSolved'] as int;

    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (status) {
      case 'critical':
        statusColor = _errorRed;
        statusIcon = Icons.error_rounded;
        statusText = 'Kritik';
        break;
      case 'warning':
        statusColor = _warningOrange;
        statusIcon = Icons.warning_rounded;
        statusText = 'Orta';
        break;
      case 'improving':
        statusColor = _successGreen;
        statusIcon = Icons.trending_up_rounded;
        statusText = 'İyileşiyor';
        break;
      default:
        statusColor = subtextColor;
        statusIcon = Icons.help_outline;
        statusText = '?';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  topicName,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Stats Row
          Row(
            children: [
              _statBox('Genel', '%$overallAccuracy', subtextColor, textColor),
              const SizedBox(width: 12),
              Icon(Icons.arrow_forward_rounded, size: 16, color: subtextColor),
              const SizedBox(width: 12),
              _statBox(
                'Son Performans', 
                '%$recentAccuracy', 
                subtextColor, 
                trend > 0 ? _successGreen : (trend < 0 ? _errorRed : textColor),
              ),
              const Spacer(),
              Text(
                '$totalSolved soru',
                style: TextStyle(fontSize: 12, color: subtextColor),
              ),
            ],
          ),
          if (trend != 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (trend > 0 ? _successGreen : _errorRed).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    trend > 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                    size: 16,
                    color: trend > 0 ? _successGreen : _errorRed,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    trend > 0 ? '+$trend puan iyileşme' : '$trend puan düşüş',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: trend > 0 ? _successGreen : _errorRed,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color labelColor, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: labelColor)),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: valueColor)),
      ],
    );
  }
}

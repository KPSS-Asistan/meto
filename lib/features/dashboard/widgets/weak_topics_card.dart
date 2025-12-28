import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:kpss_2026/core/services/quiz_stats_service.dart';

class WeakTopicsCard extends StatelessWidget {
  const WeakTopicsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: QuizStatsService.getWeakTopicAnalysis(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          // Zayıf konu yoksa gösterme (Veya tebrik et)
          return const SizedBox.shrink();
        }

        final weakTopics = snapshot.data!;
        final isDark = Theme.of(context).brightness == Brightness.dark;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.1), // Amber Warning
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.triangleAlert,
                      color: Color(0xFFFFB300),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Dikkat Gerektirenler',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Bu konulardaki başarı oranın genel ortalamanın altında. Tekrar etmeni öneririm.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              
              // Topics List
              ...weakTopics.map((topic) => _buildTopicItem(context, topic, isDark)),
              
              const SizedBox(height: 12),
              
              // Call to Action
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Zayıf konulardan test oluştur
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444), // Red for urgency
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(LucideIcons.dumbbell),
                  label: const Text('Bu Konulara Çalış'),
                ),
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.1, duration: 400.ms, delay: 100.ms);
      },
    );
  }

  Widget _buildTopicItem(BuildContext context, Map<String, dynamic> topic, bool isDark) {
    final name = topic['topicName'];
    final accuracy = topic['overallAccuracy'];
    final status = topic['status']; 
    
    // Status color
    Color statusColor;
    if (status == 'critical') {
      statusColor = const Color(0xFFEF4444); // Red
    } else if (status == 'warning') {
      statusColor = const Color(0xFFF97316); // Orange
    } else {
      statusColor = const Color(0xFFEAB308); // Yellow
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          // Name and Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[200] : Colors.grey[800],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '%$accuracy',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: accuracy / 100,
                    backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

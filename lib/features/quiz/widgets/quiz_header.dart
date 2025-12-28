import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/services/revenuecat_service.dart';
import 'favorite_button.dart';

/// Quiz ekranının üst bar'ı - Timer, soru sayacı ve aksiyon butonları
class QuizHeader extends StatelessWidget {
  final int remainingSeconds;
  final int currentIndex;
  final int totalQuestions;
  final String questionId;
  final VoidCallback onExit;
  final VoidCallback onReport;
  final VoidCallback onAskAI;

  const QuizHeader({
    super.key,
    required this.remainingSeconds,
    required this.currentIndex,
    required this.totalQuestions,
    required this.questionId,
    required this.onExit,
    required this.onReport,
    required this.onAskAI,
  });

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timerColor = remainingSeconds <= 300
        ? const Color(0xFFEF4444)
        : const Color(0xFF6366F1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF374151) : Colors.grey.shade100,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.02),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sol taraf - Aksiyon butonları
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HeaderIconButton(
                icon: LucideIcons.x,
                onTap: onExit,
              ),
              Container(
                height: 20,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: isDark ? const Color(0xFF374151) : Colors.grey.shade200,
              ),
              _HeaderIconButton(
                icon: LucideIcons.flag,
                onTap: onReport,
              ),
              FavoriteButton(questionId: questionId),
              _HeaderIconButton(
                icon: RevenueCatService().isPremium
                    ? LucideIcons.lightbulb
                    : LucideIcons.lock,
                onTap: onAskAI,
                isHighlighted: RevenueCatService().isPremium,
              ),
            ],
          ),
          // Sağ taraf - Timer ve sayaç
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Timer badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: timerColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: timerColor.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.timer,
                      size: 16,
                      color: timerColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(remainingSeconds),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: timerColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Question counter badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF374151) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF4B5563) : Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Text(
                  '${currentIndex + 1}/$totalQuestions',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Header için ikon butonu
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isHighlighted;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isHighlighted
              ? const Color(0xFF6366F1).withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isHighlighted
              ? const Color(0xFF6366F1)
              : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:kpss_2026/core/widgets/formatted_question_text.dart';

/// Cevapları İnceleme Sayfası
class QuizReviewPage extends StatelessWidget {
  final List<dynamic> questions;
  final Map<int, dynamic> userAnswers;
  final String topicName;

  const QuizReviewPage({
    super.key,
    required this.questions,
    required this.userAnswers,
    required this.topicName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Cevap Anahtarı'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final question = questions[index];
          // QuestionModel'den verileri al
          final questionText = question.questionText ?? '';
          final options = question.options as Map<String, String>? ?? {};
          final correctAnswer = question.correctAnswer ?? '';
          final userAnswer = userAnswers[index];
          
          final isCorrect = userAnswer == correctAnswer;
          final isEmpty = userAnswer == null;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Soru Başlığı ve Durum
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (isEmpty)
                        _buildStatusBadge('BOŞ', Colors.grey)
                      else if (isCorrect)
                        _buildStatusBadge('DOĞRU', const Color(0xFF10B981))
                      else
                        _buildStatusBadge('YANLIŞ', const Color(0xFFEF4444)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Soru Metni
                  FormattedQuestionText(
                    text: questionText,
                    fontSize: 15,
                    showBulletCard: true,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Cevaplar - Gerçek seçenekleri göster
                  ...options.entries.map((entry) {
                    final optionKey = entry.key;
                    final optionText = entry.value;
                    final isCorrectOption = optionKey == correctAnswer;
                    final isSelectedOption = optionKey == userAnswer;
                    return _buildAnswerRow(optionKey, optionText, isCorrectOption, isSelectedOption);
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildAnswerRow(String option, String text, bool isCorrect, bool isSelected) {
    Color? bgColor;
    Color borderColor = Colors.transparent;
    Color textColor = const Color(0xFF475569);
    IconData? icon;
    Color iconColor = Colors.transparent;

    if (isCorrect) {
      bgColor = const Color(0xFFDCFCE7);
      borderColor = const Color(0xFF22C55E);
      textColor = const Color(0xFF15803D);
      icon = LucideIcons.circleCheck;
      iconColor = const Color(0xFF15803D);
    } else if (isSelected && !isCorrect) {
      bgColor = const Color(0xFFFEE2E2);
      borderColor = const Color(0xFFEF4444);
      textColor = const Color(0xFFB91C1C);
      icon = LucideIcons.circleX;
      iconColor = const Color(0xFFB91C1C);
    } else {
      bgColor = const Color(0xFFF8FAFC);
      borderColor = const Color(0xFFE2E8F0);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(color: textColor.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isCorrect || isSelected ? FontWeight.w600 : FontWeight.normal,
                color: textColor,
              ),
            ),
          ),
          if (icon != null) ...[
            const SizedBox(width: 8),
            Icon(icon, size: 20, color: iconColor),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/models/question_model.dart';
import '../../../core/widgets/formatted_question_text.dart';
import 'option_card.dart';

/// Quiz ekranının ana içerik alanı - Soru metni ve şıklar
class QuizContent extends StatelessWidget {
  final QuestionModel question;
  final String? selectedOption;
  final bool isAnswered;
  final Function(String) onOptionSelected;

  const QuizContent({
    super.key,
    required this.question,
    required this.selectedOption,
    required this.isAnswered,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 124,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Soru metni - maddeli formatla
                FormattedQuestionText(
                  text: question.questionText,
                  fontSize: 17,
                ),

                const SizedBox(height: 24),

                // Seçenekler
                ...question.options.entries.map((entry) {
                  final optionKey = entry.key;
                  final optionText = entry.value;
                  final isSelected = selectedOption == optionKey;
                  final isCorrect = optionKey == question.correctAnswer;
                  final showResult = isAnswered;

                  return OptionCard(
                    optionKey: optionKey,
                    optionText: optionText,
                    isSelected: isSelected,
                    isCorrect: isCorrect,
                    showResult: showResult,
                    onTap: isAnswered
                        ? null
                        : () => onOptionSelected(optionKey),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

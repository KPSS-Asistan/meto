/// Quiz Question Entity
class QuizQuestion {
  final String id;
  final String question;
  final List<String> options; // 5 şık: A, B, C, D, E
  final int correctAnswerIndex; // 0-4 arası
  final String? explanation;
  final String? topicId; // Progress tracking için topic ID

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    this.explanation,
    this.topicId,
  });
}

/// Quiz Set Entity
class QuizSet {
  final String id;
  final String title;
  final String category;
  final List<QuizQuestion> questions;
  final int duration; // seconds per question

  const QuizSet({
    required this.id,
    required this.title,
    required this.category,
    required this.questions,
    this.duration = 30,
  });
}

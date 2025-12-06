import 'package:kpss_2026/core/data/questions_data.dart';
import '../../domain/entities/quiz.dart';
import '../../domain/repositories/quiz_repository.dart';

/// ⚡ HARDCODED ONLY - Firebase bağımlılığı kaldırıldı
class FirebaseQuizRepository implements QuizRepository {
  @override
  Future<QuizSet> getQuizSet(String topicId) async {
    // Hardcoded data'dan al
    final questionsData = QuestionsData.getQuestions(topicId);
    
    if (questionsData == null || questionsData.isEmpty) {
      throw Exception('Bu konu için soru bulunamadı');
    }

    final questions = questionsData.map((qData) {
      // Soru metni
      final questionText = qData['questionText'] as String? ?? '';
      
      // options map'i array'e çevir (A, B, C, D, E)
      final optionsMap = qData['options'] as Map<String, dynamic>? ?? {};
      final options = [
        optionsMap['A'] as String? ?? '',
        optionsMap['B'] as String? ?? '',
        optionsMap['C'] as String? ?? '',
        optionsMap['D'] as String? ?? '',
        optionsMap['E'] as String? ?? '',
      ];
      
      // correctAnswer'ı index'e çevir (A=0, B=1, C=2, D=3, E=4)
      final correctAnswer = (qData['correctAnswer'] as String?) ?? 'A';
      final correctIndex = correctAnswer.toUpperCase().codeUnitAt(0) - 'A'.codeUnitAt(0);
      
      return QuizQuestion(
        id: qData['id'] as String? ?? '',
        question: questionText,
        options: options,
        correctAnswerIndex: correctIndex.clamp(0, 4),
        explanation: qData['explanation'] as String?,
        topicId: topicId,
      );
    }).toList();
    
    return QuizSet(
      id: topicId,
      title: 'KPSS Quiz',
      category: 'Genel',
      questions: questions,
      duration: 60,
    );
  }
}

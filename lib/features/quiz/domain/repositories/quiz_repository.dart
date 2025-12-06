import '../entities/quiz.dart';

/// Quiz Repository Interface
abstract class QuizRepository {
  Future<QuizSet> getQuizSet(String setId);
}

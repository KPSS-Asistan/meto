import 'package:flutter_test/flutter_test.dart';
import 'package:kpss_2026/core/repositories/question_repository.dart';

/// QuestionRepository Test - Hardcoded data tests
/// Repository artık Firebase kullanmıyor, tamamen hardcoded
void main() {
  late QuestionRepository repository;

  setUp(() {
    QuestionRepository.clearCache(); // Her testten önce cache temizle
    repository = QuestionRepository();
  });

  group('QuestionRepository', () {
    test('getQuestionsByTopic should return questions for existing topic', () async {
      // Act - İslamiyet Öncesi Türk Tarihi (içerik var)
      final stream = repository.getQuestionsByTopic('JnFbEQt0uA8RSEuy22SQ');
      final questions = await stream.first;

      // Assert
      expect(questions, isNotEmpty);
    });

    test('getQuestionsByTopic should return empty list for nonexistent topic', () async {
      // Act
      final stream = repository.getQuestionsByTopic('nonexistent');
      final questions = await stream.first;

      // Assert
      expect(questions, isEmpty);
    });

    test('hasQuestions should return true for existing topic', () {
      // Act
      final hasQuestions = repository.hasQuestions('JnFbEQt0uA8RSEuy22SQ');

      // Assert
      expect(hasQuestions, isTrue);
    });

    test('hasQuestions should return false for nonexistent topic', () {
      // Act
      final hasQuestions = repository.hasQuestions('nonexistent');

      // Assert
      expect(hasQuestions, isFalse);
    });

    test('getQuestionCount should return count for existing topic', () {
      // Act
      final count = repository.getQuestionCount('JnFbEQt0uA8RSEuy22SQ');

      // Assert
      expect(count, greaterThan(0));
    });

    test('clearCache should clear memory cache', () async {
      // Arrange - Load questions first
      await repository.getQuestionsByTopic('JnFbEQt0uA8RSEuy22SQ').first;
      
      // Act
      QuestionRepository.clearCache();
      
      // Assert - Repository should still work after cache clear
      final questions = await repository.getQuestionsByTopic('JnFbEQt0uA8RSEuy22SQ').first;
      expect(questions, isNotEmpty);
    });
  });
}


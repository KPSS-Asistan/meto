import 'package:flutter_test/flutter_test.dart';
import 'package:kpss_2026/features/quiz/cubit/quiz_state.dart';
import 'package:kpss_2026/features/quiz/domain/entities/quiz.dart';

/// Quiz Cubit Test - Temel state testleri
/// Not: Full mock testleri için `flutter pub run build_runner build` gerekli
void main() {
  group('QuizState (Freezed)', () {
    test('initial state', () {
      final state = const QuizState.initial();
      expect(state, isA<QuizState>());
    });

    test('loading state', () {
      final state = const QuizState.loading();
      expect(state, isA<QuizState>());
    });

    test('error state contains message', () {
      final state = const QuizState.error('Test error');
      state.whenOrNull(
        error: (message) => expect(message, 'Test error'),
      );
    });
  });

  group('QuizQuestion', () {
    test('creates question correctly', () {
      final question = QuizQuestion(
        id: 'q1',
        question: 'Test question?',
        options: ['A', 'B', 'C', 'D', 'E'],
        correctAnswerIndex: 0,
      );

      expect(question.id, 'q1');
      expect(question.question, 'Test question?');
      expect(question.options.length, 5);
      expect(question.correctAnswerIndex, 0);
    });
  });

  group('QuizSet', () {
    test('creates quiz set correctly', () {
      final quiz = QuizSet(
        id: 'test_quiz',
        title: 'Test Quiz',
        category: 'Test',
        duration: 60,
        questions: [
          QuizQuestion(
            id: 'q1',
            question: 'Test?',
            options: ['A', 'B', 'C', 'D', 'E'],
            correctAnswerIndex: 0,
          ),
        ],
      );

      expect(quiz.id, 'test_quiz');
      expect(quiz.title, 'Test Quiz');
      expect(quiz.questions.length, 1);
    });
  });
}

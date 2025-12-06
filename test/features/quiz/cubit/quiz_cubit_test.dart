import 'package:flutter_test/flutter_test.dart';
import 'package:kpss_2026/core/models/question_model.dart';
import 'package:kpss_2026/features/quiz/cubit/quiz_state.dart';

void main() {
  final testQuestion = QuestionModel(
    id: 'q1',
    lessonId: 'l1',
    topicId: 't1',
    questionText: 'Test Soru',
    options: {'A': 'Op A', 'B': 'Op B'},
    correctAnswer: 'A',
    explanation: 'Açıklama',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  group('QuizState', () {
    test('initial state doğru olmalı', () {
      const state = QuizState.initial();
      expect(state, isA<QuizState>());
    });

    test('loading state doğru olmalı', () {
      const state = QuizState.loading();
      expect(state, isA<QuizState>());
    });

    test('loaded state doğru değerlerle oluşturulmalı', () {
      final state = QuizState.loaded(
        questions: [testQuestion],
        currentQuestionIndex: 0,
        userAnswers: {},
        selectedOption: null,
        isAnswered: false,
        remainingSeconds: 1200,
        topicId: 't1',
      );
      
      state.mapOrNull(
        loaded: (loaded) {
          expect(loaded.questions.length, 1);
          expect(loaded.currentQuestionIndex, 0);
          expect(loaded.topicId, 't1');
          expect(loaded.remainingSeconds, 1200);
          expect(loaded.isAnswered, false);
        },
      );
    });

    test('error state mesaj içermeli', () {
      const state = QuizState.error('Test hatası');
      state.mapOrNull(
        error: (error) {
          expect(error.message, 'Test hatası');
        },
      );
    });

    test('finished state skor hesaplamalı', () {
      final state = QuizState.finished(
        questions: [testQuestion],
        userAnswers: {0: 'A'},
        score: 1,
      );
      
      state.mapOrNull(
        finished: (finished) {
          expect(finished.score, 1);
          expect(finished.questions.length, 1);
          expect(finished.userAnswers[0], 'A');
        },
      );
    });

    test('loaded state copyWith çalışmalı', () {
      final state = QuizState.loaded(
        questions: [testQuestion],
        currentQuestionIndex: 0,
        userAnswers: {},
        selectedOption: null,
        isAnswered: false,
        remainingSeconds: 1200,
        topicId: 't1',
      );
      
      state.mapOrNull(
        loaded: (loaded) {
          final updated = loaded.copyWith(selectedOption: 'A');
          expect(updated.selectedOption, 'A');
          expect(updated.currentQuestionIndex, 0);
        },
      );
    });

    test('doğru cevap kontrolü çalışmalı', () {
      expect(testQuestion.correctAnswer, 'A');
      expect(testQuestion.options['A'], 'Op A');
    });
  });
}

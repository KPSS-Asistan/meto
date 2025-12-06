import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kpss_2026/core/models/topic_model.dart';
import 'package:kpss_2026/core/models/topic_explanation_model.dart';
import 'package:kpss_2026/core/repositories/topic_repository.dart';
import 'package:kpss_2026/core/repositories/cached_explanation_repository.dart';
import 'package:kpss_2026/features/lessons/cubit/lesson_cubit.dart';
import 'package:kpss_2026/features/lessons/cubit/lesson_state.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'lesson_cubit_test.mocks.dart';

@GenerateMocks([TopicRepository, CachedExplanationRepository])
void main() {
  late MockTopicRepository mockTopicRepository;
  late MockCachedExplanationRepository mockExplanationRepository;

  final now = DateTime.now();

  final mockTopics = [
    TopicModel(
      id: 'topic1',
      lessonId: 'lesson1',
      name: 'Test Topic 1',
      description: 'Description 1',
      createdAt: now,
      updatedAt: now,
    ),
    TopicModel(
      id: 'topic2',
      lessonId: 'lesson1',
      name: 'Test Topic 2',
      description: 'Description 2',
      createdAt: now,
      updatedAt: now,
    ),
  ];

  final mockExplanation = TopicExplanationModel(
    id: 'exp1',
    topicId: 'topic1',
    lessonId: 'lesson1',
    sections: [
      ExplanationSection(
        title: 'Introduction',
        type: SectionType.text,
        paragraphs: const ['This is a test paragraph.'],
        bullets: const [],
      ),
    ],
  );

  setUp(() {
    mockTopicRepository = MockTopicRepository();
    mockExplanationRepository = MockCachedExplanationRepository();
  });

  group('LessonCubit', () {
    test('initial state is correct', () {
      final cubit = LessonCubit(
        topicRepository: mockTopicRepository,
        explanationRepository: mockExplanationRepository,
      );

      expect(cubit.state.cachedTopics, isEmpty);
      expect(cubit.state.cachedExplanations, isEmpty);
      expect(cubit.state.currentTopics, isEmpty);
      expect(cubit.state.currentExplanation, isNull);
      expect(cubit.state.isLoading, false);
      expect(cubit.state.error, isNull);
    });

    group('loadTopics', () {
      blocTest<LessonCubit, LessonState>(
        'loads topics from cache when available',
        build: () {
          return LessonCubit(
            topicRepository: mockTopicRepository,
            explanationRepository: mockExplanationRepository,
          );
        },
        seed: () => LessonState(
          cachedTopics: {'lesson1': mockTopics},
        ),
        act: (cubit) => cubit.loadTopics('lesson1'),
        expect: () => [
          LessonState(
            cachedTopics: {'lesson1': mockTopics},
            currentTopics: mockTopics,
            isLoading: false,
          ),
        ],
        verify: (_) {
          verifyNever(mockTopicRepository.getTopicsByLesson(any));
        },
      );

      blocTest<LessonCubit, LessonState>(
        'fetches topics from repository when not in cache',
        build: () {
          when(mockTopicRepository.getTopicsByLesson('lesson1'))
              .thenAnswer((_) async => mockTopics);
          return LessonCubit(
            topicRepository: mockTopicRepository,
            explanationRepository: mockExplanationRepository,
          );
        },
        act: (cubit) async {
          cubit.loadTopics('lesson1');
          await Future.delayed(const Duration(milliseconds: 100));
        },
        expect: () => [
          const LessonState(isLoading: true),
          LessonState(
            cachedTopics: {'lesson1': mockTopics},
            currentTopics: mockTopics,
            isLoading: false,
          ),
        ],
        verify: (_) {
          verify(mockTopicRepository.getTopicsByLesson('lesson1')).called(1);
        },
      );

      blocTest<LessonCubit, LessonState>(
        'emits error when loading topics fails',
        build: () {
          when(mockTopicRepository.getTopicsByLesson('lesson1'))
              .thenThrow(Exception('Network error'));
          return LessonCubit(
            topicRepository: mockTopicRepository,
            explanationRepository: mockExplanationRepository,
          );
        },
        act: (cubit) async {
          cubit.loadTopics('lesson1');
          await Future.delayed(const Duration(milliseconds: 100));
        },
        expect: () => [
          const LessonState(isLoading: true),
          const LessonState(isLoading: false, error: 'Konular yüklenemedi'),
        ],
      );
    });

    group('loadExplanation', () {
      blocTest<LessonCubit, LessonState>(
        'loads explanation from cache when available',
        build: () {
          return LessonCubit(
            topicRepository: mockTopicRepository,
            explanationRepository: mockExplanationRepository,
          );
        },
        seed: () => LessonState(
          cachedExplanations: {'topic1': mockExplanation},
        ),
        act: (cubit) => cubit.loadExplanation('topic1'),
        expect: () => [
          LessonState(
            cachedExplanations: {'topic1': mockExplanation},
            currentExplanation: mockExplanation,
            isLoading: false,
          ),
        ],
        verify: (_) {
          verifyNever(mockExplanationRepository.getTopicExplanation(any));
        },
      );

      blocTest<LessonCubit, LessonState>(
        'fetches explanation from repository when not in cache',
        build: () {
          when(mockExplanationRepository.getTopicExplanation('topic1'))
              .thenAnswer((_) async => mockExplanation);
          return LessonCubit(
            topicRepository: mockTopicRepository,
            explanationRepository: mockExplanationRepository,
          );
        },
        act: (cubit) => cubit.loadExplanation('topic1'),
        expect: () => [
          const LessonState(isLoading: true),
          LessonState(
            cachedExplanations: {'topic1': mockExplanation},
            currentExplanation: mockExplanation,
            isLoading: false,
          ),
        ],
        verify: (_) {
          verify(mockExplanationRepository.getTopicExplanation('topic1'))
              .called(1);
        },
      );

      blocTest<LessonCubit, LessonState>(
        'emits error when explanation not found',
        build: () {
          when(mockExplanationRepository.getTopicExplanation('topic1'))
              .thenAnswer((_) async => null);
          return LessonCubit(
            topicRepository: mockTopicRepository,
            explanationRepository: mockExplanationRepository,
          );
        },
        act: (cubit) => cubit.loadExplanation('topic1'),
        expect: () => [
          const LessonState(isLoading: true),
          const LessonState(
            isLoading: false,
            error: 'Konu anlatımı bulunamadı',
          ),
        ],
      );
    });

    group('refreshTopics', () {
      blocTest<LessonCubit, LessonState>(
        'refreshes topics and updates cache',
        build: () {
          when(mockTopicRepository.getTopicsByLesson('lesson1'))
              .thenAnswer((_) async => mockTopics);
          return LessonCubit(
            topicRepository: mockTopicRepository,
            explanationRepository: mockExplanationRepository,
          );
        },
        seed: () => LessonState(
          cachedTopics: {'lesson1': []},
          currentTopics: [],
        ),
        act: (cubit) => cubit.refreshTopics('lesson1'),
        expect: () => [
          LessonState(
            cachedTopics: {'lesson1': mockTopics},
            currentTopics: mockTopics,
          ),
        ],
      );
    });

    group('clearCache', () {
      blocTest<LessonCubit, LessonState>(
        'clears all cached data',
        build: () {
          return LessonCubit(
            topicRepository: mockTopicRepository,
            explanationRepository: mockExplanationRepository,
          );
        },
        seed: () => LessonState(
          cachedTopics: {'lesson1': mockTopics},
          cachedExplanations: {'topic1': mockExplanation},
          currentTopics: mockTopics,
          currentExplanation: mockExplanation,
        ),
        act: (cubit) => cubit.clearCache(),
        expect: () => [const LessonState()],
      );
    });

    group('clearLessonCache', () {
      blocTest<LessonCubit, LessonState>(
        'clears cache for specific lesson',
        build: () {
          return LessonCubit(
            topicRepository: mockTopicRepository,
            explanationRepository: mockExplanationRepository,
          );
        },
        seed: () => LessonState(
          cachedTopics: {
            'lesson1': mockTopics,
            'lesson2': mockTopics,
          },
        ),
        act: (cubit) => cubit.clearLessonCache('lesson1'),
        expect: () => [
          LessonState(
            cachedTopics: {'lesson2': mockTopics},
          ),
        ],
      );
    });
  });
}

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kpss_2026/core/repositories/lesson_repository.dart';
import 'package:kpss_2026/features/dashboard/cubit/dashboard_cubit.dart';
import 'package:kpss_2026/features/dashboard/cubit/dashboard_state.dart';
import 'package:mockito/annotations.dart';

import 'dashboard_cubit_test.mocks.dart';

@GenerateMocks([LessonRepository])
void main() {
  late MockLessonRepository mockLessonRepository;

  setUp(() {
    mockLessonRepository = MockLessonRepository();
  });

  group('DashboardCubit', () {
    test('initial state has correct default values', () {
      final cubit = DashboardCubit(lessonRepository: mockLessonRepository);
      
      expect(cubit.state.selectedIndex, 0);
      expect(cubit.state.displayName, null);
      expect(cubit.state.lessons, isEmpty);
      expect(cubit.state.isLoadingLessons, true);
      expect(cubit.state.currentStreak, 0);
    });

    blocTest<DashboardCubit, DashboardState>(
      'changeTab emits new selectedIndex',
      build: () => DashboardCubit(lessonRepository: mockLessonRepository),
      act: (cubit) => cubit.changeTab(2),
      expect: () => [
        const DashboardState(selectedIndex: 2),
      ],
    );

    blocTest<DashboardCubit, DashboardState>(
      'updateLastStudyStatus updates hasLastStudy',
      build: () => DashboardCubit(lessonRepository: mockLessonRepository),
      act: (cubit) => cubit.updateLastStudyStatus(true),
      expect: () => [
        const DashboardState(hasLastStudy: true),
      ],
    );
  });
}

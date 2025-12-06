import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kpss_2026/features/practice/cubit/practice_cubit.dart';
import 'package:kpss_2026/features/practice/cubit/practice_state.dart';

void main() {
  group('PracticeCubit', () {
    test('initial state is correct', () {
      final cubit = PracticeCubit();

      expect(cubit.state.favoriteIds, isEmpty);
      expect(cubit.state.wrongAnswerIds, isEmpty);
      expect(cubit.state.isLoading, false);
      expect(cubit.state.isTogglingFavorite, false);
      expect(cubit.state.error, isNull);
    });

    group('isFavorite', () {
      test('returns true when question is in favorites', () {
        final cubit = PracticeCubit();
        cubit.emit(const PracticeState(favoriteIds: {'q1', 'q2'}));

        expect(cubit.isFavorite('q1'), true);
        expect(cubit.isFavorite('q2'), true);
        expect(cubit.isFavorite('q3'), false);
      });

      test('returns false when favorites empty', () {
        final cubit = PracticeCubit();
        expect(cubit.isFavorite('q1'), false);
      });
    });

    group('clearError', () {
      blocTest<PracticeCubit, PracticeState>(
        'clears error message',
        build: () => PracticeCubit(),
        seed: () => const PracticeState(error: 'Some error'),
        act: (cubit) => cubit.clearError(),
        expect: () => [
          const PracticeState(error: null),
        ],
      );
    });

    group('state transitions', () {
      test('state updates correctly with copyWith', () {
        const initial = PracticeState();
        
        final withLoading = initial.copyWith(isLoading: true);
        expect(withLoading.isLoading, true);
        expect(withLoading.error, isNull);
        
        final withFavorites = initial.copyWith(favoriteIds: {'q1', 'q2'});
        expect(withFavorites.favoriteIds, {'q1', 'q2'});
        
        final withError = initial.copyWith(error: 'Test error');
        expect(withError.error, 'Test error');
        
        final withToggling = initial.copyWith(isTogglingFavorite: true);
        expect(withToggling.isTogglingFavorite, true);
      });

      test('favoriteIds is a Set', () {
        const state = PracticeState(favoriteIds: {'q1', 'q2', 'q3'});
        expect(state.favoriteIds.length, 3);
        expect(state.favoriteIds.contains('q1'), true);
        expect(state.favoriteIds.contains('q2'), true);
        expect(state.favoriteIds.contains('q3'), true);
      });
    });
  });
}

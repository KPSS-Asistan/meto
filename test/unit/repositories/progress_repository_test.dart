import 'package:flutter_test/flutter_test.dart';
import 'package:kpss_2026/core/repositories/progress_repository.dart';

/// ProgressRepository Test - Local-first tests
/// Repository artık Firebase kullanmıyor, LocalProgressService kullanıyor
/// Bu testler SharedPreferences mock gerektirir
void main() {
  late ProgressRepository repository;

  setUp(() {
    repository = ProgressRepository();
  });

  group('ProgressRepository', () {
    group('TopicStats', () {
      test('TopicStats should calculate success rate correctly', () {
        // Arrange
        final stats = TopicStats(
          totalSolved: 10,
          correctCount: 7,
          wrongCount: 3,
        );

        // Assert
        expect(stats.successRate, 70.0);
      });

      test('TopicStats should return 0 for empty stats', () {
        // Arrange
        final stats = TopicStats(
          totalSolved: 0,
          correctCount: 0,
          wrongCount: 0,
        );

        // Assert
        expect(stats.successRate, 0.0);
      });
    });

    // Note: Full integration tests require SharedPreferences mock
    // These tests verify the repository can be instantiated
    test('repository should be instantiable', () {
      expect(repository, isNotNull);
    });
  });
}

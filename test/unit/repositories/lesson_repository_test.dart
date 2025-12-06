import 'package:flutter_test/flutter_test.dart';
import 'package:kpss_2026/core/repositories/lesson_repository.dart';

/// LessonRepository Test - Hardcoded data tests
/// Repository artık Firebase kullanmıyor, tamamen hardcoded
void main() {
  late LessonRepository repository;

  setUp(() {
    repository = LessonRepository();
  });

  group('LessonRepository', () {
    test('getLessons should return hardcoded lessons', () async {
      // Act
      final lessons = await repository.getLessons();

      // Assert
      expect(lessons, isNotEmpty);
      expect(lessons.length, greaterThanOrEqualTo(4)); // En az 4 ders var
    });

    test('getLessonById should return lesson when exists', () async {
      // Act - Hardcoded lesson ID kullan
      final lesson = await repository.getLessonById('caZ5LwfH3QJrBVUQCros'); // Tarih

      // Assert
      expect(lesson, isNotNull);
      expect(lesson!.name.toUpperCase(), contains('TARİH'));
    });

    test('getLessonById should return null when lesson does not exist', () async {
      // Act
      final lesson = await repository.getLessonById('nonexistent');

      // Assert
      expect(lesson, isNull);
    });

    test('refreshLessons should return same lessons', () async {
      // Act
      final lessons1 = await repository.getLessons();
      final lessons2 = await repository.refreshLessons();

      // Assert
      expect(lessons1.length, lessons2.length);
    });
  });
}

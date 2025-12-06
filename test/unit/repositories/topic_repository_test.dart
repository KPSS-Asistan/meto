import 'package:flutter_test/flutter_test.dart';
import 'package:kpss_2026/core/repositories/topic_repository.dart';

/// TopicRepository Test - Hardcoded data tests
/// Repository artık Firebase kullanmıyor, tamamen hardcoded
void main() {
  late TopicRepository repository;

  setUp(() {
    repository = TopicRepository();
    repository.clearCache(); // Her testten önce cache temizle
  });

  group('TopicRepository', () {
    test('getTopicsByLesson should return topics for Tarih', () async {
      // Act - Tarih dersi
      final topics = await repository.getTopicsByLesson('caZ5LwfH3QJrBVUQCros');

      // Assert
      expect(topics, isNotEmpty);
      expect(topics.length, greaterThanOrEqualTo(7)); // En az 7 konu
    });

    test('getTopicsByLesson should return empty list for nonexistent lesson', () async {
      // Act
      final topics = await repository.getTopicsByLesson('nonexistent');

      // Assert
      expect(topics, isEmpty);
    });

    test('getTopicById should return topic when exists', () async {
      // Act - İslamiyet Öncesi Türk Tarihi
      final topic = await repository.getTopicById('caZ5LwfH3QJrBVUQCros', 'JnFbEQt0uA8RSEuy22SQ');

      // Assert
      expect(topic, isNotNull);
      expect(topic!.name, contains('İslamiyet'));
    });

    test('getTopicById should return null when topic does not exist', () async {
      // Act
      final topic = await repository.getTopicById('caZ5LwfH3QJrBVUQCros', 'nonexistent');

      // Assert
      expect(topic, isNull);
    });

    test('getAllTopics should return all topics', () {
      // Act
      final topics = repository.getAllTopics();

      // Assert
      expect(topics, isNotEmpty);
      expect(topics.length, greaterThanOrEqualTo(28)); // En az 28 konu (4 ders x 7 konu)
    });

    test('getTopicName should return name for existing topic', () {
      // Act
      final name = repository.getTopicName('JnFbEQt0uA8RSEuy22SQ');

      // Assert
      expect(name, isNotNull);
      expect(name, contains('İslamiyet'));
    });

    test('getTopicName should return null for nonexistent topic', () {
      // Act
      final name = repository.getTopicName('nonexistent');

      // Assert
      expect(name, isNull);
    });

    test('topics should be sorted by order', () async {
      // Act
      final topics = await repository.getTopicsByLesson('caZ5LwfH3QJrBVUQCros');

      // Assert
      for (int i = 0; i < topics.length - 1; i++) {
        expect(topics[i].order, lessThanOrEqualTo(topics[i + 1].order));
      }
    });
  });
}

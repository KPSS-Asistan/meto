import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kpss_2026/core/repositories/explanation_repository.dart';

/// ExplanationRepository Test
void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late ExplanationRepository repository;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = ExplanationRepository(firestore: fakeFirestore);
  });

  group('ExplanationRepository', () {
    test('getTopicExplanation should return explanation when exists', () async {
      // Arrange
      await fakeFirestore.collection('explanations').add({
        'topic_id': 'topic1',
        'lesson_id': 'lesson1',
        'is_deleted': false,
        'sections': [
          {
            'type': 'text',
            'title': 'Giriş',
            'paragraphs': ['Bu bir test paragrafı'],
          },
          {
            'type': 'bulletList',
            'title': 'Önemli Noktalar',
            'bullets': ['Nokta 1', 'Nokta 2'],
          },
        ],
        'created_at': Timestamp.now(),
        'updated_at': Timestamp.now(),
      });

      // Act
      final explanation = await repository.getTopicExplanation('topic1');

      // Assert
      expect(explanation, isNotNull);
      expect(explanation!.topicId, 'topic1');
      expect(explanation.sections.length, 2);
      expect(explanation.sections[0].title, 'Giriş');
      expect(explanation.sections[0].paragraphs, ['Bu bir test paragrafı']);
      expect(explanation.sections[1].title, 'Önemli Noktalar');
      expect(explanation.sections[1].bullets, ['Nokta 1', 'Nokta 2']);
    });

    test('getTopicExplanation should return null when not exists', () async {
      // Act
      final explanation = await repository.getTopicExplanation('nonexistent');

      // Assert
      expect(explanation, isNull);
    });

    test('getTopicExplanation should skip deleted explanations', () async {
      // Arrange
      await fakeFirestore.collection('explanations').add({
        'topic_id': 'topic2',
        'lesson_id': 'lesson2',
        'is_deleted': true, // deleted!
        'sections': [],
        'created_at': Timestamp.now(),
        'updated_at': Timestamp.now(),
      });

      // Act
      final explanation = await repository.getTopicExplanation('topic2');

      // Assert
      expect(explanation, isNull);
    });

    test('getTopicExplanation should handle tip/warning/example types', () async {
      // Arrange
      await fakeFirestore.collection('explanations').add({
        'topic_id': 'topic3',
        'lesson_id': 'lesson3',
        'is_deleted': false,
        'sections': [
          {
            'type': 'tip',
            'title': 'İpucu',
            'tip': 'Bu bir ipucu',
          },
          {
            'type': 'warning',
            'title': 'Dikkat',
            'tip': 'Bu bir uyarı',
          },
          {
            'type': 'example',
            'title': 'Örnek',
            'tip': 'Bu bir örnek',
          },
        ],
        'created_at': Timestamp.now(),
        'updated_at': Timestamp.now(),
      });

      // Act
      final explanation = await repository.getTopicExplanation('topic3');

      // Assert
      expect(explanation, isNotNull);
      expect(explanation!.sections.length, 3);
      expect(explanation.sections[0].tip, 'Bu bir ipucu');
      expect(explanation.sections[1].tip, 'Bu bir uyarı');
      expect(explanation.sections[2].tip, 'Bu bir örnek');
    });

    test('getTopicExplanation should handle highlighted type', () async {
      // Arrange
      await fakeFirestore.collection('explanations').add({
        'topic_id': 'topic4',
        'lesson_id': 'lesson4',
        'is_deleted': false,
        'sections': [
          {
            'type': 'highlighted',
            'title': 'Önemli',
            'paragraphs': ['Vurgulu metin'],
          },
        ],
        'created_at': Timestamp.now(),
        'updated_at': Timestamp.now(),
      });

      // Act
      final explanation = await repository.getTopicExplanation('topic4');

      // Assert
      expect(explanation, isNotNull);
      expect(explanation!.sections[0].paragraphs, ['Vurgulu metin']);
    });
  });
}

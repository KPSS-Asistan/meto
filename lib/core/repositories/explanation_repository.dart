import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kpss_2026/core/models/topic_explanation_model.dart';
import 'package:kpss_2026/core/utils/app_logger.dart';

class ExplanationRepository {
  final FirebaseFirestore _firestore;

  ExplanationRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  Future<TopicExplanationModel?> getTopicExplanation(String topicId) async {
    try {
      AppLogger.firebase('GET', 'explanations', topicId);
      
      // Önce tam eşleşme dene
      var query = await _firestore
          .collection('explanations')
          .where('topic_id', isEqualTo: topicId)
          .where('is_deleted', isEqualTo: false)
          .limit(1)
          .get();
      
      // Bulamazsa büyük harfle dene
      if (query.docs.isEmpty) {
        query = await _firestore
            .collection('explanations')
            .where('topic_id', isEqualTo: topicId.toUpperCase())
            .where('is_deleted', isEqualTo: false)
            .limit(1)
            .get();
      }
      
      // Bulamazsa küçük harfle dene
      if (query.docs.isEmpty) {
        query = await _firestore
            .collection('explanations')
            .where('topic_id', isEqualTo: topicId.toLowerCase())
            .where('is_deleted', isEqualTo: false)
            .limit(1)
            .get();
      }

      if (query.docs.isEmpty) {
        return null;
      }

      final doc = query.docs.first;
      final data = doc.data();
      
      // Admin panelde sections veya pages List<Map> olarak saklanıyor
      final sectionsData = (data['sections'] ?? data['pages']) as List<dynamic>? ?? [];
      
      // Her section'ı parse et
      final sections = <ExplanationSection>[];
      for (var i = 0; i < sectionsData.length; i++) {
        final section = sectionsData[i];
        
        if (section is! Map<String, dynamic>) continue;
        
        final type = section['type'] as String? ?? 'text';
        final title = section['title'] as String? ?? 'Bölüm ${i + 1}';
        
        // Type'a göre parse et
        SectionType sectionType;
        switch (type) {
          case 'bulletList':
            sectionType = SectionType.bulletList;
            break;
          case 'numbered':
            sectionType = SectionType.numbered;
            break;
          case 'highlighted':
            sectionType = SectionType.highlighted;
            break;
          case 'tip':
            sectionType = SectionType.tip;
            break;
          case 'warning':
            sectionType = SectionType.warning;
            break;
          case 'example':
            sectionType = SectionType.example;
            break;
          default:
            sectionType = SectionType.text;
        }
        
        final paragraphs = (section['paragraphs'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ?? [];
        final bullets = (section['bullets'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ?? [];
        final tip = section['tip'] as String?;
        
        sections.add(ExplanationSection(
          title: title,
          paragraphs: paragraphs,
          bullets: bullets,
          order: i,
          type: sectionType,
          tip: tip,
        ));
      }

      final createdAtField = data['created_at'];
      final updatedAtField = data['updated_at'];

      final createdAt = createdAtField is Timestamp
          ? createdAtField.toDate()
          : null;
      final updatedAt = updatedAtField is Timestamp
          ? updatedAtField.toDate()
          : null;

      final model = TopicExplanationModel(
        id: doc.id,
        topicId: data['topic_id'] as String? ?? topicId,
        lessonId: data['lesson_id'] as String? ?? '',
        sections: sections,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      
      return model;
    } catch (e) {
      AppLogger.error('Get explanation failed', e);
      return null;
    }
  }
}

// Topic Explanation Model
// Konu anlatımı için veri modeli

enum SectionType {
  text,
  bulletList,
  numbered,
  highlighted,
  tip,
  warning,
  example,
  heading,
  table,
}

class ExplanationSection {
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;
  final int order;
  final SectionType type;
  final String? tip;
  final List<int> headingIndexes;

  ExplanationSection({
    required this.title,
    this.paragraphs = const [],
    this.bullets = const [],
    this.order = 0,
    this.type = SectionType.text,
    this.tip,
    this.headingIndexes = const [],
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'paragraphs': paragraphs,
    'bullets': bullets,
    'order': order,
    'type': type.name,
    'tip': tip,
    'heading_indexes': headingIndexes,
  };

  factory ExplanationSection.fromJson(Map<String, dynamic> json) {
    return ExplanationSection(
      title: json['title'] as String? ?? '',
      paragraphs: (json['paragraphs'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      bullets: (json['bullets'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      order: json['order'] as int? ?? 0,
      type: SectionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SectionType.text,
      ),
      tip: json['tip'] as String?,
      headingIndexes: (json['heading_indexes'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          const [],
    );
  }
}

class TopicExplanationModel {
  final String id;
  final String topicId;
  final String lessonId;
  final List<ExplanationSection> sections;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TopicExplanationModel({
    required this.id,
    required this.topicId,
    required this.lessonId,
    required this.sections,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'topic_id': topicId,
    'lesson_id': lessonId,
    'sections': sections.map((s) => s.toJson()).toList(),
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };

  factory TopicExplanationModel.fromJson(Map<String, dynamic> json) {
    return TopicExplanationModel(
      id: json['id'] as String? ?? '',
      topicId: json['topic_id'] as String? ?? '',
      lessonId: json['lesson_id'] as String? ?? '',
      sections: (json['sections'] as List<dynamic>?)
          ?.map((e) => ExplanationSection.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }
}

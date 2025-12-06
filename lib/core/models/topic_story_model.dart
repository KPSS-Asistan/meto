import 'package:cloud_firestore/cloud_firestore.dart';

/// Story Section Model
class StorySection {
  final String title;
  final String content;
  final List<String> keyPoints;
  final int order;

  const StorySection({
    required this.title,
    required this.content,
    required this.keyPoints,
    required this.order,
  });

  factory StorySection.fromMap(Map<String, dynamic> map) {
    return StorySection(
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      keyPoints: (map['key_points'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      order: map['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'key_points': keyPoints,
      'order': order,
    };
  }
}

/// Topic Story Model
class TopicStoryModel {
  final String id;
  final String topicId;
  final String topicName;
  final String lessonId;
  final String lessonName;
  final List<StorySection> sections;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublished;

  const TopicStoryModel({
    required this.id,
    required this.topicId,
    required this.topicName,
    required this.lessonId,
    required this.lessonName,
    required this.sections,
    required this.createdAt,
    required this.updatedAt,
    required this.isPublished,
  });

  factory TopicStoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse sections
    final sectionsData = data['sections'] as List<dynamic>? ?? [];
    final sections = sectionsData
        .map((s) => StorySection.fromMap(s as Map<String, dynamic>))
        .toList();
    
    // Sort by order
    sections.sort((a, b) => a.order.compareTo(b.order));

    return TopicStoryModel(
      id: doc.id,
      topicId: data['topic_id'] as String? ?? '',
      topicName: data['topic_name'] as String? ?? '',
      lessonId: data['lesson_id'] as String? ?? '',
      lessonName: data['lesson_name'] as String? ?? '',
      sections: sections,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPublished: data['is_published'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'topic_id': topicId,
      'topic_name': topicName,
      'lesson_id': lessonId,
      'lesson_name': lessonName,
      'sections': sections.map((s) => s.toMap()).toList(),
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'is_published': isPublished,
    };
  }
}

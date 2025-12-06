// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'topic_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TopicModelImpl _$$TopicModelImplFromJson(Map<String, dynamic> json) =>
    _$TopicModelImpl(
      id: json['id'] as String,
      lessonId: json['lessonId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      questionCount: (json['questionCount'] as num?)?.toInt() ?? 0,
      order: (json['order'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$TopicModelImplToJson(_$TopicModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'lessonId': instance.lessonId,
      'name': instance.name,
      'description': instance.description,
      'questionCount': instance.questionCount,
      'order': instance.order,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

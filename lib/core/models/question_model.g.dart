// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$QuestionModelImpl _$$QuestionModelImplFromJson(Map<String, dynamic> json) =>
    _$QuestionModelImpl(
      id: json['id'] as String,
      lessonId: json['lessonId'] as String,
      topicId: json['topicId'] as String,
      questionText: json['questionText'] as String,
      options: Map<String, String>.from(json['options'] as Map),
      correctAnswer: json['correctAnswer'] as String,
      explanation: json['explanation'] as String?,
      subtopicId: json['subtopicId'] as String?,
      subtopicName: json['subtopicName'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$QuestionModelImplToJson(_$QuestionModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'lessonId': instance.lessonId,
      'topicId': instance.topicId,
      'questionText': instance.questionText,
      'options': instance.options,
      'correctAnswer': instance.correctAnswer,
      'explanation': instance.explanation,
      'subtopicId': instance.subtopicId,
      'subtopicName': instance.subtopicName,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

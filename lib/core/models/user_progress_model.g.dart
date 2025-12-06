// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_progress_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserProgressModelImpl _$$UserProgressModelImplFromJson(
  Map<String, dynamic> json,
) => _$UserProgressModelImpl(
  id: json['id'] as String,
  userId: json['userId'] as String,
  questionId: json['questionId'] as String,
  topicId: json['topicId'] as String,
  isCorrect: json['isCorrect'] as bool,
  timestamp: DateTime.parse(json['timestamp'] as String),
);

Map<String, dynamic> _$$UserProgressModelImplToJson(
  _$UserProgressModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'questionId': instance.questionId,
  'topicId': instance.topicId,
  'isCorrect': instance.isCorrect,
  'timestamp': instance.timestamp.toIso8601String(),
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_flashcard_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserFlashcardProgressImpl _$$UserFlashcardProgressImplFromJson(
  Map<String, dynamic> json,
) => _$UserFlashcardProgressImpl(
  userId: json['userId'] as String,
  flashcardId: json['flashcardId'] as String,
  boxLevel: (json['boxLevel'] as num?)?.toInt() ?? 1,
  nextReviewDate: DateTime.parse(json['nextReviewDate'] as String),
  lastReviewedAt: DateTime.parse(json['lastReviewedAt'] as String),
  totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
  correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
  wrongCount: (json['wrongCount'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$UserFlashcardProgressImplToJson(
  _$UserFlashcardProgressImpl instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'flashcardId': instance.flashcardId,
  'boxLevel': instance.boxLevel,
  'nextReviewDate': instance.nextReviewDate.toIso8601String(),
  'lastReviewedAt': instance.lastReviewedAt.toIso8601String(),
  'totalReviews': instance.totalReviews,
  'correctCount': instance.correctCount,
  'wrongCount': instance.wrongCount,
};

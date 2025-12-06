// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flashcard.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FlashcardImpl _$$FlashcardImplFromJson(Map<String, dynamic> json) =>
    _$FlashcardImpl(
      id: json['id'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String,
      additionalInfo: json['additionalInfo'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );

Map<String, dynamic> _$$FlashcardImplToJson(_$FlashcardImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'question': instance.question,
      'answer': instance.answer,
      'additionalInfo': instance.additionalInfo,
      'imageUrl': instance.imageUrl,
    };

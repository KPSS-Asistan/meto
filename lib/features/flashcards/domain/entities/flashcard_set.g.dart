// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flashcard_set.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FlashcardSetImpl _$$FlashcardSetImplFromJson(Map<String, dynamic> json) =>
    _$FlashcardSetImpl(
      id: json['id'] as String,
      topicId: json['topicId'] as String,
      topicName: json['topicName'] as String,
      cards: (json['cards'] as List<dynamic>)
          .map((e) => Flashcard.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCards: (json['totalCards'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$FlashcardSetImplToJson(_$FlashcardSetImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'topicId': instance.topicId,
      'topicName': instance.topicName,
      'cards': instance.cards,
      'totalCards': instance.totalCards,
    };

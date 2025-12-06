import 'package:freezed_annotation/freezed_annotation.dart';
import 'flashcard.dart';

part 'flashcard_set.freezed.dart';
part 'flashcard_set.g.dart';

@freezed
class FlashcardSet with _$FlashcardSet {
  const factory FlashcardSet({
    required String id,
    required String topicId,
    required String topicName,
    required List<Flashcard> cards,
    @Default(0) int totalCards,
  }) = _FlashcardSet;

  factory FlashcardSet.fromJson(Map<String, dynamic> json) =>
      _$FlashcardSetFromJson(json);
}

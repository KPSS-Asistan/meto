import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/flashcard_set.dart';

part 'flashcard_state.freezed.dart';

@freezed
class FlashcardState with _$FlashcardState {
  const factory FlashcardState.initial() = _Initial;
  const factory FlashcardState.loading() = _Loading;
  const factory FlashcardState.loaded({
    required FlashcardSet flashcardSet,
    @Default(0) int currentIndex,
    @Default(false) bool isFlipped,
  }) = _Loaded;
  const factory FlashcardState.finished({
    required FlashcardSet flashcardSet,
  }) = _Finished;
  const factory FlashcardState.error(String message) = _Error;
}

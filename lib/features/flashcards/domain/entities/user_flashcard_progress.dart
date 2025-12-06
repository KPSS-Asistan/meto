import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_flashcard_progress.freezed.dart';
part 'user_flashcard_progress.g.dart';

/// Leitner System için kullanıcı flashcard ilerlemesi
@freezed
class UserFlashcardProgress with _$UserFlashcardProgress {
  const factory UserFlashcardProgress({
    required String userId,
    required String flashcardId,
    @Default(1) int boxLevel, // Kutu seviyesi (1-4)
    required DateTime nextReviewDate, // Bir sonraki gösterim zamanı
    required DateTime lastReviewedAt, // Son görüntülenme zamanı
    @Default(0) int totalReviews, // Toplam tekrar sayısı
    @Default(0) int correctCount, // Doğru sayısı
    @Default(0) int wrongCount, // Yanlış sayısı
  }) = _UserFlashcardProgress;

  factory UserFlashcardProgress.fromJson(Map<String, dynamic> json) =>
      _$UserFlashcardProgressFromJson(json);
}

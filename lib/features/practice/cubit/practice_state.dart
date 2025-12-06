import 'package:freezed_annotation/freezed_annotation.dart';

part 'practice_state.freezed.dart';

/// Minimal Practice State
/// Sadece ID'leri tutar (soru detayları çekilmez - maliyet sıfır)
@freezed
class PracticeState with _$PracticeState {
  const factory PracticeState({
    /// Favori soru ID'leri (local + Firebase sync)
    @Default({}) Set<String> favoriteIds,
    
    /// Yanlış cevap ID'leri (AI öğrenmesi için)
    @Default({}) Set<String> wrongAnswerIds,
    
    /// Yükleniyor durumu
    @Default(false) bool isLoading,
    
    /// Favori toggle işlemi devam ediyor mu
    @Default(false) bool isTogglingFavorite,
    
    /// Hata mesajı
    String? error,
  }) = _PracticeState;
}

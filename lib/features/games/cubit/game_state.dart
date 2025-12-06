import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_state.freezed.dart';

/// Oyun tipi
enum GameType { matching, memory, wordHunt }

@freezed
class GameState with _$GameState {
  const factory GameState({
    /// Oyun tipi
    @Default(GameType.matching) GameType gameType,
    
    /// Eşleştirme oyunu verileri
    @Default([]) List<Map<String, String>> matchingPairs,
    
    /// Hafıza oyunu verileri
    @Default([]) List<Map<String, String>> memoryPairs,
    
    /// Kelime avı verileri
    @Default({}) Map<String, List<String>> wordHuntData,
    
    /// Seçili soru (matching game)
    String? selectedQuestion,
    
    /// Seçili cevap (matching game)
    String? selectedAnswer,
    
    /// Eşleşmiş çiftler
    @Default({}) Set<String> matchedPairs,
    
    /// Skor
    @Default(0) int score,
    
    /// Maksimum skor
    @Default(0) int maxScore,
    
    /// Oyun bitti mi
    @Default(false) bool isGameOver,
    
    /// Yükleniyor
    @Default(true) bool isLoading,
    
    /// Hata
    String? error,
  }) = _GameState;
}

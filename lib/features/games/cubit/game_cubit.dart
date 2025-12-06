import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kpss_2026/core/utils/app_logger.dart';
import 'package:kpss_2026/features/games/data/games_repository.dart';
import 'game_state.dart';

class GameCubit extends Cubit<GameState> {
  final GamesRepository _repository;

  GameCubit({GamesRepository? repository})
      : _repository = repository ?? GamesRepository(),
        super(const GameState());

  /// Eşleştirme oyununu başlat
  Future<void> loadMatchingGame(String topicId) async {
    try {
      emit(state.copyWith(
        isLoading: true,
        error: null,
        gameType: GameType.matching,
        matchedPairs: {},
        selectedQuestion: null,
        selectedAnswer: null,
        score: 0,
        isGameOver: false,
      ));

      final pairs = await _repository.getMatchingGameData(topicId);
      
      // Maksimum 8 çift gösterilecek
      final maxPairs = pairs.length.clamp(0, 8);

      emit(state.copyWith(
        matchingPairs: pairs,
        maxScore: maxPairs,
        isLoading: false,
      ));

      AppLogger.info('Matching game loaded: ${pairs.length} pairs');
    } catch (e) {
      AppLogger.error('Load matching game failed', e);
      emit(state.copyWith(
        isLoading: false,
        error: 'Oyun verileri yüklenemedi',
      ));
    }
  }

  /// Hafıza oyununu başlat
  Future<void> loadMemoryGame(String topicId) async {
    try {
      emit(state.copyWith(
        isLoading: true,
        error: null,
        gameType: GameType.memory,
        matchedPairs: {},
        score: 0,
        isGameOver: false,
      ));

      final pairs = await _repository.getMemoryGameData(topicId);

      emit(state.copyWith(
        memoryPairs: pairs,
        maxScore: pairs.length,
        isLoading: false,
      ));

      AppLogger.info('Memory game loaded: ${pairs.length} pairs');
    } catch (e) {
      AppLogger.error('Load memory game failed', e);
      emit(state.copyWith(
        isLoading: false,
        error: 'Oyun verileri yüklenemedi',
      ));
    }
  }

  /// Kelime avı oyununu başlat
  Future<void> loadWordHuntGame(String topicId) async {
    try {
      emit(state.copyWith(
        isLoading: true,
        error: null,
        gameType: GameType.wordHunt,
        score: 0,
        isGameOver: false,
      ));

      final data = await _repository.getWordHuntData(topicId);
      final totalWords = data.values.fold(0, (sum, list) => sum + list.length);

      emit(state.copyWith(
        wordHuntData: data,
        maxScore: totalWords,
        isLoading: false,
      ));

      AppLogger.info('Word hunt loaded: ${data.length} categories');
    } catch (e) {
      AppLogger.error('Load word hunt failed', e);
      emit(state.copyWith(
        isLoading: false,
        error: 'Oyun verileri yüklenemedi',
      ));
    }
  }

  /// Soru seç (Matching Game)
  void selectQuestion(String question) {
    if (state.matchedPairs.contains(question)) return;

    emit(state.copyWith(selectedQuestion: question));
    _checkMatch();
  }

  /// Cevap seç (Matching Game)
  void selectAnswer(String answer) {
    if (state.matchedPairs.contains(answer)) return;

    emit(state.copyWith(selectedAnswer: answer));
    _checkMatch();
  }

  /// Eşleşme kontrolü
  void _checkMatch() {
    final question = state.selectedQuestion;
    final answer = state.selectedAnswer;

    if (question == null || answer == null) return;

    // Doğru eşleşmeyi bul
    final isMatch = state.matchingPairs.any(
      (pair) => pair['question'] == question && pair['answer'] == answer,
    );

    if (isMatch) {
      final newMatched = {...state.matchedPairs, question, answer};
      final newScore = state.score + 1;
      final isGameOver = newScore >= state.maxScore;

      emit(state.copyWith(
        matchedPairs: newMatched,
        score: newScore,
        isGameOver: isGameOver,
        selectedQuestion: null,
        selectedAnswer: null,
      ));

      AppLogger.debug('Match found! Score: $newScore/${state.maxScore}');
    } else {
      // Yanlış eşleşme - seçimi temizle
      emit(state.copyWith(
        selectedQuestion: null,
        selectedAnswer: null,
      ));
    }
  }

  /// Skor artır (genel kullanım)
  void incrementScore() {
    final newScore = state.score + 1;
    emit(state.copyWith(
      score: newScore,
      isGameOver: newScore >= state.maxScore,
    ));
  }

  /// Seçimleri temizle (yanlış eşleşme sonrası)
  void clearSelections() {
    emit(state.copyWith(
      selectedQuestion: null,
      selectedAnswer: null,
    ));
  }

  /// Oyunu sıfırla
  void resetGame() {
    emit(state.copyWith(
      matchedPairs: {},
      selectedQuestion: null,
      selectedAnswer: null,
      score: 0,
      isGameOver: false,
    ));
  }

  /// Oyunu bitir
  void endGame() {
    emit(state.copyWith(isGameOver: true));
  }
}

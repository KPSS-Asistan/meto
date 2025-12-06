import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kpss_2026/core/services/user_data_service.dart';
import 'package:kpss_2026/core/utils/app_logger.dart';
import 'practice_state.dart';

/// Minimal Practice Cubit
/// Favoriler ve yanlış cevapları local'de tutar (Firebase sync arka planda)
/// AI öğrenmesi için yanlış cevap ID'leri saklanır
class PracticeCubit extends Cubit<PracticeState> {
  PracticeCubit() : super(const PracticeState());

  /// Tüm verileri yükle (favoriler + yanlışlar)
  Future<void> loadAll() async {
    try {
      emit(state.copyWith(isLoading: true, error: null));

      final results = await Future.wait([
        UserDataService.getFavorites(),
        UserDataService.getWrongAnswers(),
      ]);

      emit(state.copyWith(
        favoriteIds: results[0],
        wrongAnswerIds: results[1],
        isLoading: false,
      ));

      AppLogger.debug('Loaded ${results[0].length} favorites, ${results[1].length} wrong answers');
    } catch (e) {
      AppLogger.error('Failed to load practice data', e);
      emit(state.copyWith(isLoading: false, error: 'Veriler yüklenemedi'));
    }
  }

  /// Favorileri yükle
  Future<void> loadFavorites() async {
    try {
      emit(state.copyWith(isLoading: true, error: null));

      final favoriteIds = await UserDataService.getFavorites();

      emit(state.copyWith(
        favoriteIds: favoriteIds,
        isLoading: false,
      ));

      AppLogger.debug('Loaded ${favoriteIds.length} favorite IDs');
    } catch (e) {
      AppLogger.error('Failed to load favorites', e);
      emit(state.copyWith(
        isLoading: false,
        error: 'Favoriler yüklenemedi',
      ));
    }
  }

  /// Optimistic UI ile favoriye ekleme/çıkarma
  Future<void> toggleFavorite(String questionId) async {
    final oldFavorites = state.favoriteIds;

    // 1. ANINDA UI güncelle (Optimistic)
    final updatedFavorites = oldFavorites.contains(questionId)
        ? oldFavorites.difference({questionId})
        : {...oldFavorites, questionId};

    emit(state.copyWith(
      favoriteIds: updatedFavorites,
      isTogglingFavorite: true,
    ));

    // 2. Arka planda kaydet
    try {
      await UserDataService.toggleFavorite(questionId);

      emit(state.copyWith(isTogglingFavorite: false));
      AppLogger.info('Favorite toggled: $questionId');
    } catch (e) {
      // 3. Hata olursa geri al (ROLLBACK)
      emit(state.copyWith(
        favoriteIds: oldFavorites,
        isTogglingFavorite: false,
        error: 'Favori işlemi başarısız',
      ));
      AppLogger.error('Toggle favorite failed', e);
    }
  }

  /// Yanlış cevap ekle (AI öğrenmesi için)
  Future<void> addWrongAnswer(String questionId) async {
    // Zaten varsa ekleme
    if (state.wrongAnswerIds.contains(questionId)) return;

    final updated = {...state.wrongAnswerIds, questionId};
    emit(state.copyWith(wrongAnswerIds: updated));

    // Arka planda kaydet
    try {
      await UserDataService.addWrongAnswer(questionId);
      AppLogger.debug('Wrong answer added: $questionId');
    } catch (e) {
      AppLogger.error('Failed to save wrong answer', e);
    }
  }

  /// Yanlış cevap ID'lerini getir (AI için)
  Set<String> getWrongAnswerIds() => state.wrongAnswerIds;

  /// Soru favoride mi kontrol et
  bool isFavorite(String questionId) {
    return state.favoriteIds.contains(questionId);
  }

  /// Hatayı temizle
  void clearError() {
    emit(state.copyWith(error: null));
  }
}

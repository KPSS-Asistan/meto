import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kpss_2026/core/models/topic_model.dart';
import 'package:kpss_2026/core/repositories/topic_repository.dart';
import 'package:kpss_2026/core/repositories/cached_explanation_repository.dart';
import 'package:kpss_2026/core/utils/app_logger.dart';
import 'lesson_state.dart';

class LessonCubit extends Cubit<LessonState> {
  final TopicRepository _topicRepository;
  final CachedExplanationRepository _explanationRepository;

  LessonCubit({
    required TopicRepository topicRepository,
    required CachedExplanationRepository explanationRepository,
  })  : _topicRepository = topicRepository,
        _explanationRepository = explanationRepository,
        super(const LessonState());

  /// Cache-first stratejisi ile topic'leri yükle
  Future<void> loadTopics(String lessonId) async {
    // Cache'e bak
    if (state.cachedTopics.containsKey(lessonId)) {
      emit(state.copyWith(
        currentTopics: state.cachedTopics[lessonId]!,
        isLoading: false,
        error: null,
      ));
      AppLogger.debug('Topics loaded from cache for $lessonId');
      return;
    }

    // Cache'te yoksa Firestore'dan çek
    try {
      emit(state.copyWith(isLoading: true, error: null));

      final topics = await _topicRepository.getTopicsByLesson(lessonId);
      
      final updatedCache = {...state.cachedTopics, lessonId: topics};
      emit(state.copyWith(
        cachedTopics: updatedCache,
        currentTopics: topics,
        isLoading: false,
        error: null,
      ));
      AppLogger.info('Loaded ${topics.length} topics for $lessonId');
    } catch (e) {
      AppLogger.error('Failed to load topics', e);
      emit(state.copyWith(
        isLoading: false,
        error: 'Konular yüklenemedi',
      ));
    }
  }

  /// Konu anlatımını yükle (cache-first)
  Future<void> loadExplanation(String topicId) async {
    // Cache'e bak
    if (state.cachedExplanations.containsKey(topicId)) {
      emit(state.copyWith(
        currentExplanation: state.cachedExplanations[topicId],
        isLoading: false,
        error: null,
      ));
      AppLogger.debug('Explanation loaded from cache for $topicId');
      return;
    }

    try {
      emit(state.copyWith(isLoading: true, error: null));

      final explanation = await _explanationRepository.getTopicExplanation(topicId);

      if (explanation != null) {
        final updatedCache = {...state.cachedExplanations, topicId: explanation};
        emit(state.copyWith(
          cachedExplanations: updatedCache,
          currentExplanation: explanation,
          isLoading: false,
          error: null,
        ));
        AppLogger.info('Loaded explanation for $topicId');
      } else {
        emit(state.copyWith(
          currentExplanation: null,
          isLoading: false,
          error: 'Konu anlatımı bulunamadı',
        ));
      }
    } catch (e) {
      AppLogger.error('Failed to load explanation', e);
      emit(state.copyWith(
        isLoading: false,
        error: 'Konu anlatımı yüklenemedi',
      ));
    }
  }

  /// Topic'leri yenile (Pull-to-refresh)
  Future<void> refreshTopics(String lessonId) async {
    try {
      // Repository'den direkt çek
      final topics = await _topicRepository.getTopicsByLesson(lessonId);

      final updatedCache = {...state.cachedTopics, lessonId: topics};
      emit(state.copyWith(
        cachedTopics: updatedCache,
        currentTopics: topics,
        error: null,
      ));

      AppLogger.info('Topics refreshed for $lessonId');
    } catch (e) {
      AppLogger.error('Failed to refresh topics', e);
      // Hata durumunda mevcut veriyi koru
      emit(state.copyWith(error: 'Yenileme başarısız'));
    }
  }

  /// Explanation'ı yenile
  Future<void> refreshExplanation(String topicId) async {
    try {
      final explanation = await _explanationRepository.getTopicExplanation(topicId);

      if (explanation != null) {
        final updatedCache = {...state.cachedExplanations, topicId: explanation};
        emit(state.copyWith(
          cachedExplanations: updatedCache,
          currentExplanation: explanation,
          error: null,
        ));
        AppLogger.info('Explanation refreshed for $topicId');
      }
    } catch (e) {
      AppLogger.error('Failed to refresh explanation', e);
      emit(state.copyWith(error: 'Yenileme başarısız'));
    }
  }

  /// Cache'i temizle
  void clearCache() {
    emit(const LessonState());
    AppLogger.debug('Lesson cache cleared');
  }

  /// Belirli bir dersin cache'ini temizle
  void clearLessonCache(String lessonId) {
    final updatedCache = Map<String, List<TopicModel>>.from(state.cachedTopics);
    updatedCache.remove(lessonId);
    emit(state.copyWith(cachedTopics: updatedCache));
    AppLogger.debug('Cache cleared for lesson $lessonId');
  }
}

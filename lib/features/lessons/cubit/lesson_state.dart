import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kpss_2026/core/models/topic_model.dart';
import 'package:kpss_2026/core/models/topic_explanation_model.dart';

part 'lesson_state.freezed.dart';

@freezed
class LessonState with _$LessonState {
  const factory LessonState({
    /// Ders bazlı topic cache'i
    @Default({}) Map<String, List<TopicModel>> cachedTopics,
    
    /// Topic bazlı explanation cache'i
    @Default({}) Map<String, TopicExplanationModel> cachedExplanations,
    
    /// Şu an görüntülenen topic listesi
    @Default([]) List<TopicModel> currentTopics,
    
    /// Şu an görüntülenen explanation
    TopicExplanationModel? currentExplanation,
    
    /// Yükleniyor durumu
    @Default(false) bool isLoading,
    
    /// Hata mesajı
    String? error,
  }) = _LessonState;
}

import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/models/question_model.dart';

part 'quiz_state.freezed.dart';

@freezed
class QuizState with _$QuizState {
  const factory QuizState.initial() = _Initial;
  
  const factory QuizState.loading() = _Loading;
  
  const factory QuizState.loaded({
    required List<QuestionModel> questions,
    required int currentQuestionIndex,
    @Default({}) Map<int, String> userAnswers, // questionIndex => selectedOption (A-E)
    String? selectedOption,
    @Default(false) bool isAnswered,
    @Default(1200) int remainingSeconds, // 20 dakika = 1200 saniye
    String? topicId,
  }) = _Loaded;
  
  const factory QuizState.finished({
    required List<QuestionModel> questions,
    required Map<int, String> userAnswers,
    required int score,
  }) = _Finished;
  
  const factory QuizState.error(String message) = _Error;
}

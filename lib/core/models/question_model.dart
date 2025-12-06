import 'package:freezed_annotation/freezed_annotation.dart';

part 'question_model.freezed.dart';
part 'question_model.g.dart';

@freezed
class QuestionModel with _$QuestionModel {
  const factory QuestionModel({
    required String id,
    required String lessonId,
    required String topicId,
    required String questionText,
    required Map<String, String> options,
    required String correctAnswer,
    String? explanation,
    /// Alt konu ID'si (örn: 'gokturkler', 'hunlar')
    String? subtopicId,
    /// Alt konu adı (örn: 'Göktürk Devletleri', 'Hun Devleti')
    String? subtopicName,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _QuestionModel;

  factory QuestionModel.fromJson(Map<String, dynamic> json) =>
      _$QuestionModelFromJson(json);
}

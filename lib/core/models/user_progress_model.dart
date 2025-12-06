import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_progress_model.freezed.dart';
part 'user_progress_model.g.dart';

@freezed
class UserProgressModel with _$UserProgressModel {
  const factory UserProgressModel({
    required String id,
    required String userId,
    required String questionId,
    required String topicId,
    required bool isCorrect,
    required DateTime timestamp,
  }) = _UserProgressModel;

  factory UserProgressModel.fromJson(Map<String, dynamic> json) =>
      _$UserProgressModelFromJson(json);
}

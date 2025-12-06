import 'package:freezed_annotation/freezed_annotation.dart';

part 'lesson_model.freezed.dart';
part 'lesson_model.g.dart';

@freezed
class LessonModel with _$LessonModel {
  const factory LessonModel({
    required String id,
    required String name,
    String? description,
    String? iconUrl,
    @Default(0) int topicCount,
    @Default(0) int questionCount,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _LessonModel;

  factory LessonModel.fromJson(Map<String, dynamic> json) =>
      _$LessonModelFromJson(json);
}

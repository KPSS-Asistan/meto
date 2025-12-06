import 'package:freezed_annotation/freezed_annotation.dart';

part 'topic_model.freezed.dart';
part 'topic_model.g.dart';

@freezed
class TopicModel with _$TopicModel {
  const factory TopicModel({
    required String id,
    required String lessonId,
    required String name,
    String? description,
    @Default(0) int questionCount,
    @Default(0) int order,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _TopicModel;

  factory TopicModel.fromJson(Map<String, dynamic> json) =>
      _$TopicModelFromJson(json);
}

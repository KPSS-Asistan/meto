// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'question_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

QuestionModel _$QuestionModelFromJson(Map<String, dynamic> json) {
  return _QuestionModel.fromJson(json);
}

/// @nodoc
mixin _$QuestionModel {
  String get id => throw _privateConstructorUsedError;
  String get lessonId => throw _privateConstructorUsedError;
  String get topicId => throw _privateConstructorUsedError;
  String get questionText => throw _privateConstructorUsedError;
  Map<String, String> get options => throw _privateConstructorUsedError;
  String get correctAnswer => throw _privateConstructorUsedError;
  String? get explanation => throw _privateConstructorUsedError;

  /// Alt konu ID'si (örn: 'gokturkler', 'hunlar')
  String? get subtopicId => throw _privateConstructorUsedError;

  /// Alt konu adı (örn: 'Göktürk Devletleri', 'Hun Devleti')
  String? get subtopicName => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this QuestionModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of QuestionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QuestionModelCopyWith<QuestionModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuestionModelCopyWith<$Res> {
  factory $QuestionModelCopyWith(
    QuestionModel value,
    $Res Function(QuestionModel) then,
  ) = _$QuestionModelCopyWithImpl<$Res, QuestionModel>;
  @useResult
  $Res call({
    String id,
    String lessonId,
    String topicId,
    String questionText,
    Map<String, String> options,
    String correctAnswer,
    String? explanation,
    String? subtopicId,
    String? subtopicName,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$QuestionModelCopyWithImpl<$Res, $Val extends QuestionModel>
    implements $QuestionModelCopyWith<$Res> {
  _$QuestionModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of QuestionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? lessonId = null,
    Object? topicId = null,
    Object? questionText = null,
    Object? options = null,
    Object? correctAnswer = null,
    Object? explanation = freezed,
    Object? subtopicId = freezed,
    Object? subtopicName = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            lessonId: null == lessonId
                ? _value.lessonId
                : lessonId // ignore: cast_nullable_to_non_nullable
                      as String,
            topicId: null == topicId
                ? _value.topicId
                : topicId // ignore: cast_nullable_to_non_nullable
                      as String,
            questionText: null == questionText
                ? _value.questionText
                : questionText // ignore: cast_nullable_to_non_nullable
                      as String,
            options: null == options
                ? _value.options
                : options // ignore: cast_nullable_to_non_nullable
                      as Map<String, String>,
            correctAnswer: null == correctAnswer
                ? _value.correctAnswer
                : correctAnswer // ignore: cast_nullable_to_non_nullable
                      as String,
            explanation: freezed == explanation
                ? _value.explanation
                : explanation // ignore: cast_nullable_to_non_nullable
                      as String?,
            subtopicId: freezed == subtopicId
                ? _value.subtopicId
                : subtopicId // ignore: cast_nullable_to_non_nullable
                      as String?,
            subtopicName: freezed == subtopicName
                ? _value.subtopicName
                : subtopicName // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$QuestionModelImplCopyWith<$Res>
    implements $QuestionModelCopyWith<$Res> {
  factory _$$QuestionModelImplCopyWith(
    _$QuestionModelImpl value,
    $Res Function(_$QuestionModelImpl) then,
  ) = __$$QuestionModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String lessonId,
    String topicId,
    String questionText,
    Map<String, String> options,
    String correctAnswer,
    String? explanation,
    String? subtopicId,
    String? subtopicName,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$QuestionModelImplCopyWithImpl<$Res>
    extends _$QuestionModelCopyWithImpl<$Res, _$QuestionModelImpl>
    implements _$$QuestionModelImplCopyWith<$Res> {
  __$$QuestionModelImplCopyWithImpl(
    _$QuestionModelImpl _value,
    $Res Function(_$QuestionModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of QuestionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? lessonId = null,
    Object? topicId = null,
    Object? questionText = null,
    Object? options = null,
    Object? correctAnswer = null,
    Object? explanation = freezed,
    Object? subtopicId = freezed,
    Object? subtopicName = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$QuestionModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        lessonId: null == lessonId
            ? _value.lessonId
            : lessonId // ignore: cast_nullable_to_non_nullable
                  as String,
        topicId: null == topicId
            ? _value.topicId
            : topicId // ignore: cast_nullable_to_non_nullable
                  as String,
        questionText: null == questionText
            ? _value.questionText
            : questionText // ignore: cast_nullable_to_non_nullable
                  as String,
        options: null == options
            ? _value._options
            : options // ignore: cast_nullable_to_non_nullable
                  as Map<String, String>,
        correctAnswer: null == correctAnswer
            ? _value.correctAnswer
            : correctAnswer // ignore: cast_nullable_to_non_nullable
                  as String,
        explanation: freezed == explanation
            ? _value.explanation
            : explanation // ignore: cast_nullable_to_non_nullable
                  as String?,
        subtopicId: freezed == subtopicId
            ? _value.subtopicId
            : subtopicId // ignore: cast_nullable_to_non_nullable
                  as String?,
        subtopicName: freezed == subtopicName
            ? _value.subtopicName
            : subtopicName // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$QuestionModelImpl implements _QuestionModel {
  const _$QuestionModelImpl({
    required this.id,
    required this.lessonId,
    required this.topicId,
    required this.questionText,
    required final Map<String, String> options,
    required this.correctAnswer,
    this.explanation,
    this.subtopicId,
    this.subtopicName,
    required this.createdAt,
    required this.updatedAt,
  }) : _options = options;

  factory _$QuestionModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$QuestionModelImplFromJson(json);

  @override
  final String id;
  @override
  final String lessonId;
  @override
  final String topicId;
  @override
  final String questionText;
  final Map<String, String> _options;
  @override
  Map<String, String> get options {
    if (_options is EqualUnmodifiableMapView) return _options;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_options);
  }

  @override
  final String correctAnswer;
  @override
  final String? explanation;

  /// Alt konu ID'si (örn: 'gokturkler', 'hunlar')
  @override
  final String? subtopicId;

  /// Alt konu adı (örn: 'Göktürk Devletleri', 'Hun Devleti')
  @override
  final String? subtopicName;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'QuestionModel(id: $id, lessonId: $lessonId, topicId: $topicId, questionText: $questionText, options: $options, correctAnswer: $correctAnswer, explanation: $explanation, subtopicId: $subtopicId, subtopicName: $subtopicName, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuestionModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.lessonId, lessonId) ||
                other.lessonId == lessonId) &&
            (identical(other.topicId, topicId) || other.topicId == topicId) &&
            (identical(other.questionText, questionText) ||
                other.questionText == questionText) &&
            const DeepCollectionEquality().equals(other._options, _options) &&
            (identical(other.correctAnswer, correctAnswer) ||
                other.correctAnswer == correctAnswer) &&
            (identical(other.explanation, explanation) ||
                other.explanation == explanation) &&
            (identical(other.subtopicId, subtopicId) ||
                other.subtopicId == subtopicId) &&
            (identical(other.subtopicName, subtopicName) ||
                other.subtopicName == subtopicName) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    lessonId,
    topicId,
    questionText,
    const DeepCollectionEquality().hash(_options),
    correctAnswer,
    explanation,
    subtopicId,
    subtopicName,
    createdAt,
    updatedAt,
  );

  /// Create a copy of QuestionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QuestionModelImplCopyWith<_$QuestionModelImpl> get copyWith =>
      __$$QuestionModelImplCopyWithImpl<_$QuestionModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QuestionModelImplToJson(this);
  }
}

abstract class _QuestionModel implements QuestionModel {
  const factory _QuestionModel({
    required final String id,
    required final String lessonId,
    required final String topicId,
    required final String questionText,
    required final Map<String, String> options,
    required final String correctAnswer,
    final String? explanation,
    final String? subtopicId,
    final String? subtopicName,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$QuestionModelImpl;

  factory _QuestionModel.fromJson(Map<String, dynamic> json) =
      _$QuestionModelImpl.fromJson;

  @override
  String get id;
  @override
  String get lessonId;
  @override
  String get topicId;
  @override
  String get questionText;
  @override
  Map<String, String> get options;
  @override
  String get correctAnswer;
  @override
  String? get explanation;

  /// Alt konu ID'si (örn: 'gokturkler', 'hunlar')
  @override
  String? get subtopicId;

  /// Alt konu adı (örn: 'Göktürk Devletleri', 'Hun Devleti')
  @override
  String? get subtopicName;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of QuestionModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QuestionModelImplCopyWith<_$QuestionModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

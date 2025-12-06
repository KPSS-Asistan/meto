// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_progress_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

UserProgressModel _$UserProgressModelFromJson(Map<String, dynamic> json) {
  return _UserProgressModel.fromJson(json);
}

/// @nodoc
mixin _$UserProgressModel {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get questionId => throw _privateConstructorUsedError;
  String get topicId => throw _privateConstructorUsedError;
  bool get isCorrect => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;

  /// Serializes this UserProgressModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserProgressModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserProgressModelCopyWith<UserProgressModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserProgressModelCopyWith<$Res> {
  factory $UserProgressModelCopyWith(
    UserProgressModel value,
    $Res Function(UserProgressModel) then,
  ) = _$UserProgressModelCopyWithImpl<$Res, UserProgressModel>;
  @useResult
  $Res call({
    String id,
    String userId,
    String questionId,
    String topicId,
    bool isCorrect,
    DateTime timestamp,
  });
}

/// @nodoc
class _$UserProgressModelCopyWithImpl<$Res, $Val extends UserProgressModel>
    implements $UserProgressModelCopyWith<$Res> {
  _$UserProgressModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserProgressModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? questionId = null,
    Object? topicId = null,
    Object? isCorrect = null,
    Object? timestamp = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            questionId: null == questionId
                ? _value.questionId
                : questionId // ignore: cast_nullable_to_non_nullable
                      as String,
            topicId: null == topicId
                ? _value.topicId
                : topicId // ignore: cast_nullable_to_non_nullable
                      as String,
            isCorrect: null == isCorrect
                ? _value.isCorrect
                : isCorrect // ignore: cast_nullable_to_non_nullable
                      as bool,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserProgressModelImplCopyWith<$Res>
    implements $UserProgressModelCopyWith<$Res> {
  factory _$$UserProgressModelImplCopyWith(
    _$UserProgressModelImpl value,
    $Res Function(_$UserProgressModelImpl) then,
  ) = __$$UserProgressModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String questionId,
    String topicId,
    bool isCorrect,
    DateTime timestamp,
  });
}

/// @nodoc
class __$$UserProgressModelImplCopyWithImpl<$Res>
    extends _$UserProgressModelCopyWithImpl<$Res, _$UserProgressModelImpl>
    implements _$$UserProgressModelImplCopyWith<$Res> {
  __$$UserProgressModelImplCopyWithImpl(
    _$UserProgressModelImpl _value,
    $Res Function(_$UserProgressModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserProgressModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? questionId = null,
    Object? topicId = null,
    Object? isCorrect = null,
    Object? timestamp = null,
  }) {
    return _then(
      _$UserProgressModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        questionId: null == questionId
            ? _value.questionId
            : questionId // ignore: cast_nullable_to_non_nullable
                  as String,
        topicId: null == topicId
            ? _value.topicId
            : topicId // ignore: cast_nullable_to_non_nullable
                  as String,
        isCorrect: null == isCorrect
            ? _value.isCorrect
            : isCorrect // ignore: cast_nullable_to_non_nullable
                  as bool,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserProgressModelImpl implements _UserProgressModel {
  const _$UserProgressModelImpl({
    required this.id,
    required this.userId,
    required this.questionId,
    required this.topicId,
    required this.isCorrect,
    required this.timestamp,
  });

  factory _$UserProgressModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserProgressModelImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String questionId;
  @override
  final String topicId;
  @override
  final bool isCorrect;
  @override
  final DateTime timestamp;

  @override
  String toString() {
    return 'UserProgressModel(id: $id, userId: $userId, questionId: $questionId, topicId: $topicId, isCorrect: $isCorrect, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserProgressModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.questionId, questionId) ||
                other.questionId == questionId) &&
            (identical(other.topicId, topicId) || other.topicId == topicId) &&
            (identical(other.isCorrect, isCorrect) ||
                other.isCorrect == isCorrect) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    questionId,
    topicId,
    isCorrect,
    timestamp,
  );

  /// Create a copy of UserProgressModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserProgressModelImplCopyWith<_$UserProgressModelImpl> get copyWith =>
      __$$UserProgressModelImplCopyWithImpl<_$UserProgressModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$UserProgressModelImplToJson(this);
  }
}

abstract class _UserProgressModel implements UserProgressModel {
  const factory _UserProgressModel({
    required final String id,
    required final String userId,
    required final String questionId,
    required final String topicId,
    required final bool isCorrect,
    required final DateTime timestamp,
  }) = _$UserProgressModelImpl;

  factory _UserProgressModel.fromJson(Map<String, dynamic> json) =
      _$UserProgressModelImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get questionId;
  @override
  String get topicId;
  @override
  bool get isCorrect;
  @override
  DateTime get timestamp;

  /// Create a copy of UserProgressModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserProgressModelImplCopyWith<_$UserProgressModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

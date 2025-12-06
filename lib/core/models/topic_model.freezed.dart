// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'topic_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TopicModel _$TopicModelFromJson(Map<String, dynamic> json) {
  return _TopicModel.fromJson(json);
}

/// @nodoc
mixin _$TopicModel {
  String get id => throw _privateConstructorUsedError;
  String get lessonId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  int get questionCount => throw _privateConstructorUsedError;
  int get order => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this TopicModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TopicModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TopicModelCopyWith<TopicModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TopicModelCopyWith<$Res> {
  factory $TopicModelCopyWith(
    TopicModel value,
    $Res Function(TopicModel) then,
  ) = _$TopicModelCopyWithImpl<$Res, TopicModel>;
  @useResult
  $Res call({
    String id,
    String lessonId,
    String name,
    String? description,
    int questionCount,
    int order,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$TopicModelCopyWithImpl<$Res, $Val extends TopicModel>
    implements $TopicModelCopyWith<$Res> {
  _$TopicModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TopicModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? lessonId = null,
    Object? name = null,
    Object? description = freezed,
    Object? questionCount = null,
    Object? order = null,
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
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            questionCount: null == questionCount
                ? _value.questionCount
                : questionCount // ignore: cast_nullable_to_non_nullable
                      as int,
            order: null == order
                ? _value.order
                : order // ignore: cast_nullable_to_non_nullable
                      as int,
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
abstract class _$$TopicModelImplCopyWith<$Res>
    implements $TopicModelCopyWith<$Res> {
  factory _$$TopicModelImplCopyWith(
    _$TopicModelImpl value,
    $Res Function(_$TopicModelImpl) then,
  ) = __$$TopicModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String lessonId,
    String name,
    String? description,
    int questionCount,
    int order,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$TopicModelImplCopyWithImpl<$Res>
    extends _$TopicModelCopyWithImpl<$Res, _$TopicModelImpl>
    implements _$$TopicModelImplCopyWith<$Res> {
  __$$TopicModelImplCopyWithImpl(
    _$TopicModelImpl _value,
    $Res Function(_$TopicModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TopicModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? lessonId = null,
    Object? name = null,
    Object? description = freezed,
    Object? questionCount = null,
    Object? order = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$TopicModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        lessonId: null == lessonId
            ? _value.lessonId
            : lessonId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        questionCount: null == questionCount
            ? _value.questionCount
            : questionCount // ignore: cast_nullable_to_non_nullable
                  as int,
        order: null == order
            ? _value.order
            : order // ignore: cast_nullable_to_non_nullable
                  as int,
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
class _$TopicModelImpl implements _TopicModel {
  const _$TopicModelImpl({
    required this.id,
    required this.lessonId,
    required this.name,
    this.description,
    this.questionCount = 0,
    this.order = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory _$TopicModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$TopicModelImplFromJson(json);

  @override
  final String id;
  @override
  final String lessonId;
  @override
  final String name;
  @override
  final String? description;
  @override
  @JsonKey()
  final int questionCount;
  @override
  @JsonKey()
  final int order;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'TopicModel(id: $id, lessonId: $lessonId, name: $name, description: $description, questionCount: $questionCount, order: $order, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TopicModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.lessonId, lessonId) ||
                other.lessonId == lessonId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.questionCount, questionCount) ||
                other.questionCount == questionCount) &&
            (identical(other.order, order) || other.order == order) &&
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
    name,
    description,
    questionCount,
    order,
    createdAt,
    updatedAt,
  );

  /// Create a copy of TopicModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TopicModelImplCopyWith<_$TopicModelImpl> get copyWith =>
      __$$TopicModelImplCopyWithImpl<_$TopicModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TopicModelImplToJson(this);
  }
}

abstract class _TopicModel implements TopicModel {
  const factory _TopicModel({
    required final String id,
    required final String lessonId,
    required final String name,
    final String? description,
    final int questionCount,
    final int order,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$TopicModelImpl;

  factory _TopicModel.fromJson(Map<String, dynamic> json) =
      _$TopicModelImpl.fromJson;

  @override
  String get id;
  @override
  String get lessonId;
  @override
  String get name;
  @override
  String? get description;
  @override
  int get questionCount;
  @override
  int get order;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of TopicModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TopicModelImplCopyWith<_$TopicModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

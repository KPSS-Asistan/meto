// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_flashcard_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

UserFlashcardProgress _$UserFlashcardProgressFromJson(
  Map<String, dynamic> json,
) {
  return _UserFlashcardProgress.fromJson(json);
}

/// @nodoc
mixin _$UserFlashcardProgress {
  String get userId => throw _privateConstructorUsedError;
  String get flashcardId => throw _privateConstructorUsedError;
  int get boxLevel => throw _privateConstructorUsedError; // Kutu seviyesi (1-4)
  DateTime get nextReviewDate =>
      throw _privateConstructorUsedError; // Bir sonraki gösterim zamanı
  DateTime get lastReviewedAt =>
      throw _privateConstructorUsedError; // Son görüntülenme zamanı
  int get totalReviews =>
      throw _privateConstructorUsedError; // Toplam tekrar sayısı
  int get correctCount => throw _privateConstructorUsedError; // Doğru sayısı
  int get wrongCount => throw _privateConstructorUsedError;

  /// Serializes this UserFlashcardProgress to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserFlashcardProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserFlashcardProgressCopyWith<UserFlashcardProgress> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserFlashcardProgressCopyWith<$Res> {
  factory $UserFlashcardProgressCopyWith(
    UserFlashcardProgress value,
    $Res Function(UserFlashcardProgress) then,
  ) = _$UserFlashcardProgressCopyWithImpl<$Res, UserFlashcardProgress>;
  @useResult
  $Res call({
    String userId,
    String flashcardId,
    int boxLevel,
    DateTime nextReviewDate,
    DateTime lastReviewedAt,
    int totalReviews,
    int correctCount,
    int wrongCount,
  });
}

/// @nodoc
class _$UserFlashcardProgressCopyWithImpl<
  $Res,
  $Val extends UserFlashcardProgress
>
    implements $UserFlashcardProgressCopyWith<$Res> {
  _$UserFlashcardProgressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserFlashcardProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? flashcardId = null,
    Object? boxLevel = null,
    Object? nextReviewDate = null,
    Object? lastReviewedAt = null,
    Object? totalReviews = null,
    Object? correctCount = null,
    Object? wrongCount = null,
  }) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            flashcardId: null == flashcardId
                ? _value.flashcardId
                : flashcardId // ignore: cast_nullable_to_non_nullable
                      as String,
            boxLevel: null == boxLevel
                ? _value.boxLevel
                : boxLevel // ignore: cast_nullable_to_non_nullable
                      as int,
            nextReviewDate: null == nextReviewDate
                ? _value.nextReviewDate
                : nextReviewDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            lastReviewedAt: null == lastReviewedAt
                ? _value.lastReviewedAt
                : lastReviewedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            totalReviews: null == totalReviews
                ? _value.totalReviews
                : totalReviews // ignore: cast_nullable_to_non_nullable
                      as int,
            correctCount: null == correctCount
                ? _value.correctCount
                : correctCount // ignore: cast_nullable_to_non_nullable
                      as int,
            wrongCount: null == wrongCount
                ? _value.wrongCount
                : wrongCount // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserFlashcardProgressImplCopyWith<$Res>
    implements $UserFlashcardProgressCopyWith<$Res> {
  factory _$$UserFlashcardProgressImplCopyWith(
    _$UserFlashcardProgressImpl value,
    $Res Function(_$UserFlashcardProgressImpl) then,
  ) = __$$UserFlashcardProgressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String userId,
    String flashcardId,
    int boxLevel,
    DateTime nextReviewDate,
    DateTime lastReviewedAt,
    int totalReviews,
    int correctCount,
    int wrongCount,
  });
}

/// @nodoc
class __$$UserFlashcardProgressImplCopyWithImpl<$Res>
    extends
        _$UserFlashcardProgressCopyWithImpl<$Res, _$UserFlashcardProgressImpl>
    implements _$$UserFlashcardProgressImplCopyWith<$Res> {
  __$$UserFlashcardProgressImplCopyWithImpl(
    _$UserFlashcardProgressImpl _value,
    $Res Function(_$UserFlashcardProgressImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserFlashcardProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? flashcardId = null,
    Object? boxLevel = null,
    Object? nextReviewDate = null,
    Object? lastReviewedAt = null,
    Object? totalReviews = null,
    Object? correctCount = null,
    Object? wrongCount = null,
  }) {
    return _then(
      _$UserFlashcardProgressImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        flashcardId: null == flashcardId
            ? _value.flashcardId
            : flashcardId // ignore: cast_nullable_to_non_nullable
                  as String,
        boxLevel: null == boxLevel
            ? _value.boxLevel
            : boxLevel // ignore: cast_nullable_to_non_nullable
                  as int,
        nextReviewDate: null == nextReviewDate
            ? _value.nextReviewDate
            : nextReviewDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        lastReviewedAt: null == lastReviewedAt
            ? _value.lastReviewedAt
            : lastReviewedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        totalReviews: null == totalReviews
            ? _value.totalReviews
            : totalReviews // ignore: cast_nullable_to_non_nullable
                  as int,
        correctCount: null == correctCount
            ? _value.correctCount
            : correctCount // ignore: cast_nullable_to_non_nullable
                  as int,
        wrongCount: null == wrongCount
            ? _value.wrongCount
            : wrongCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserFlashcardProgressImpl implements _UserFlashcardProgress {
  const _$UserFlashcardProgressImpl({
    required this.userId,
    required this.flashcardId,
    this.boxLevel = 1,
    required this.nextReviewDate,
    required this.lastReviewedAt,
    this.totalReviews = 0,
    this.correctCount = 0,
    this.wrongCount = 0,
  });

  factory _$UserFlashcardProgressImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserFlashcardProgressImplFromJson(json);

  @override
  final String userId;
  @override
  final String flashcardId;
  @override
  @JsonKey()
  final int boxLevel;
  // Kutu seviyesi (1-4)
  @override
  final DateTime nextReviewDate;
  // Bir sonraki gösterim zamanı
  @override
  final DateTime lastReviewedAt;
  // Son görüntülenme zamanı
  @override
  @JsonKey()
  final int totalReviews;
  // Toplam tekrar sayısı
  @override
  @JsonKey()
  final int correctCount;
  // Doğru sayısı
  @override
  @JsonKey()
  final int wrongCount;

  @override
  String toString() {
    return 'UserFlashcardProgress(userId: $userId, flashcardId: $flashcardId, boxLevel: $boxLevel, nextReviewDate: $nextReviewDate, lastReviewedAt: $lastReviewedAt, totalReviews: $totalReviews, correctCount: $correctCount, wrongCount: $wrongCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserFlashcardProgressImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.flashcardId, flashcardId) ||
                other.flashcardId == flashcardId) &&
            (identical(other.boxLevel, boxLevel) ||
                other.boxLevel == boxLevel) &&
            (identical(other.nextReviewDate, nextReviewDate) ||
                other.nextReviewDate == nextReviewDate) &&
            (identical(other.lastReviewedAt, lastReviewedAt) ||
                other.lastReviewedAt == lastReviewedAt) &&
            (identical(other.totalReviews, totalReviews) ||
                other.totalReviews == totalReviews) &&
            (identical(other.correctCount, correctCount) ||
                other.correctCount == correctCount) &&
            (identical(other.wrongCount, wrongCount) ||
                other.wrongCount == wrongCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    userId,
    flashcardId,
    boxLevel,
    nextReviewDate,
    lastReviewedAt,
    totalReviews,
    correctCount,
    wrongCount,
  );

  /// Create a copy of UserFlashcardProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserFlashcardProgressImplCopyWith<_$UserFlashcardProgressImpl>
  get copyWith =>
      __$$UserFlashcardProgressImplCopyWithImpl<_$UserFlashcardProgressImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$UserFlashcardProgressImplToJson(this);
  }
}

abstract class _UserFlashcardProgress implements UserFlashcardProgress {
  const factory _UserFlashcardProgress({
    required final String userId,
    required final String flashcardId,
    final int boxLevel,
    required final DateTime nextReviewDate,
    required final DateTime lastReviewedAt,
    final int totalReviews,
    final int correctCount,
    final int wrongCount,
  }) = _$UserFlashcardProgressImpl;

  factory _UserFlashcardProgress.fromJson(Map<String, dynamic> json) =
      _$UserFlashcardProgressImpl.fromJson;

  @override
  String get userId;
  @override
  String get flashcardId;
  @override
  int get boxLevel; // Kutu seviyesi (1-4)
  @override
  DateTime get nextReviewDate; // Bir sonraki gösterim zamanı
  @override
  DateTime get lastReviewedAt; // Son görüntülenme zamanı
  @override
  int get totalReviews; // Toplam tekrar sayısı
  @override
  int get correctCount; // Doğru sayısı
  @override
  int get wrongCount;

  /// Create a copy of UserFlashcardProgress
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserFlashcardProgressImplCopyWith<_$UserFlashcardProgressImpl>
  get copyWith => throw _privateConstructorUsedError;
}

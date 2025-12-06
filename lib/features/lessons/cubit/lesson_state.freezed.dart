// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lesson_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$LessonState {
  /// Ders bazlı topic cache'i
  Map<String, List<TopicModel>> get cachedTopics =>
      throw _privateConstructorUsedError;

  /// Topic bazlı explanation cache'i
  Map<String, TopicExplanationModel> get cachedExplanations =>
      throw _privateConstructorUsedError;

  /// Şu an görüntülenen topic listesi
  List<TopicModel> get currentTopics => throw _privateConstructorUsedError;

  /// Şu an görüntülenen explanation
  TopicExplanationModel? get currentExplanation =>
      throw _privateConstructorUsedError;

  /// Yükleniyor durumu
  bool get isLoading => throw _privateConstructorUsedError;

  /// Hata mesajı
  String? get error => throw _privateConstructorUsedError;

  /// Create a copy of LessonState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LessonStateCopyWith<LessonState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LessonStateCopyWith<$Res> {
  factory $LessonStateCopyWith(
    LessonState value,
    $Res Function(LessonState) then,
  ) = _$LessonStateCopyWithImpl<$Res, LessonState>;
  @useResult
  $Res call({
    Map<String, List<TopicModel>> cachedTopics,
    Map<String, TopicExplanationModel> cachedExplanations,
    List<TopicModel> currentTopics,
    TopicExplanationModel? currentExplanation,
    bool isLoading,
    String? error,
  });
}

/// @nodoc
class _$LessonStateCopyWithImpl<$Res, $Val extends LessonState>
    implements $LessonStateCopyWith<$Res> {
  _$LessonStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LessonState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cachedTopics = null,
    Object? cachedExplanations = null,
    Object? currentTopics = null,
    Object? currentExplanation = freezed,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(
      _value.copyWith(
            cachedTopics: null == cachedTopics
                ? _value.cachedTopics
                : cachedTopics // ignore: cast_nullable_to_non_nullable
                      as Map<String, List<TopicModel>>,
            cachedExplanations: null == cachedExplanations
                ? _value.cachedExplanations
                : cachedExplanations // ignore: cast_nullable_to_non_nullable
                      as Map<String, TopicExplanationModel>,
            currentTopics: null == currentTopics
                ? _value.currentTopics
                : currentTopics // ignore: cast_nullable_to_non_nullable
                      as List<TopicModel>,
            currentExplanation: freezed == currentExplanation
                ? _value.currentExplanation
                : currentExplanation // ignore: cast_nullable_to_non_nullable
                      as TopicExplanationModel?,
            isLoading: null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                      as bool,
            error: freezed == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LessonStateImplCopyWith<$Res>
    implements $LessonStateCopyWith<$Res> {
  factory _$$LessonStateImplCopyWith(
    _$LessonStateImpl value,
    $Res Function(_$LessonStateImpl) then,
  ) = __$$LessonStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    Map<String, List<TopicModel>> cachedTopics,
    Map<String, TopicExplanationModel> cachedExplanations,
    List<TopicModel> currentTopics,
    TopicExplanationModel? currentExplanation,
    bool isLoading,
    String? error,
  });
}

/// @nodoc
class __$$LessonStateImplCopyWithImpl<$Res>
    extends _$LessonStateCopyWithImpl<$Res, _$LessonStateImpl>
    implements _$$LessonStateImplCopyWith<$Res> {
  __$$LessonStateImplCopyWithImpl(
    _$LessonStateImpl _value,
    $Res Function(_$LessonStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LessonState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cachedTopics = null,
    Object? cachedExplanations = null,
    Object? currentTopics = null,
    Object? currentExplanation = freezed,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(
      _$LessonStateImpl(
        cachedTopics: null == cachedTopics
            ? _value._cachedTopics
            : cachedTopics // ignore: cast_nullable_to_non_nullable
                  as Map<String, List<TopicModel>>,
        cachedExplanations: null == cachedExplanations
            ? _value._cachedExplanations
            : cachedExplanations // ignore: cast_nullable_to_non_nullable
                  as Map<String, TopicExplanationModel>,
        currentTopics: null == currentTopics
            ? _value._currentTopics
            : currentTopics // ignore: cast_nullable_to_non_nullable
                  as List<TopicModel>,
        currentExplanation: freezed == currentExplanation
            ? _value.currentExplanation
            : currentExplanation // ignore: cast_nullable_to_non_nullable
                  as TopicExplanationModel?,
        isLoading: null == isLoading
            ? _value.isLoading
            : isLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        error: freezed == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$LessonStateImpl implements _LessonState {
  const _$LessonStateImpl({
    final Map<String, List<TopicModel>> cachedTopics = const {},
    final Map<String, TopicExplanationModel> cachedExplanations = const {},
    final List<TopicModel> currentTopics = const [],
    this.currentExplanation,
    this.isLoading = false,
    this.error,
  }) : _cachedTopics = cachedTopics,
       _cachedExplanations = cachedExplanations,
       _currentTopics = currentTopics;

  /// Ders bazlı topic cache'i
  final Map<String, List<TopicModel>> _cachedTopics;

  /// Ders bazlı topic cache'i
  @override
  @JsonKey()
  Map<String, List<TopicModel>> get cachedTopics {
    if (_cachedTopics is EqualUnmodifiableMapView) return _cachedTopics;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_cachedTopics);
  }

  /// Topic bazlı explanation cache'i
  final Map<String, TopicExplanationModel> _cachedExplanations;

  /// Topic bazlı explanation cache'i
  @override
  @JsonKey()
  Map<String, TopicExplanationModel> get cachedExplanations {
    if (_cachedExplanations is EqualUnmodifiableMapView)
      return _cachedExplanations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_cachedExplanations);
  }

  /// Şu an görüntülenen topic listesi
  final List<TopicModel> _currentTopics;

  /// Şu an görüntülenen topic listesi
  @override
  @JsonKey()
  List<TopicModel> get currentTopics {
    if (_currentTopics is EqualUnmodifiableListView) return _currentTopics;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_currentTopics);
  }

  /// Şu an görüntülenen explanation
  @override
  final TopicExplanationModel? currentExplanation;

  /// Yükleniyor durumu
  @override
  @JsonKey()
  final bool isLoading;

  /// Hata mesajı
  @override
  final String? error;

  @override
  String toString() {
    return 'LessonState(cachedTopics: $cachedTopics, cachedExplanations: $cachedExplanations, currentTopics: $currentTopics, currentExplanation: $currentExplanation, isLoading: $isLoading, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LessonStateImpl &&
            const DeepCollectionEquality().equals(
              other._cachedTopics,
              _cachedTopics,
            ) &&
            const DeepCollectionEquality().equals(
              other._cachedExplanations,
              _cachedExplanations,
            ) &&
            const DeepCollectionEquality().equals(
              other._currentTopics,
              _currentTopics,
            ) &&
            (identical(other.currentExplanation, currentExplanation) ||
                other.currentExplanation == currentExplanation) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_cachedTopics),
    const DeepCollectionEquality().hash(_cachedExplanations),
    const DeepCollectionEquality().hash(_currentTopics),
    currentExplanation,
    isLoading,
    error,
  );

  /// Create a copy of LessonState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LessonStateImplCopyWith<_$LessonStateImpl> get copyWith =>
      __$$LessonStateImplCopyWithImpl<_$LessonStateImpl>(this, _$identity);
}

abstract class _LessonState implements LessonState {
  const factory _LessonState({
    final Map<String, List<TopicModel>> cachedTopics,
    final Map<String, TopicExplanationModel> cachedExplanations,
    final List<TopicModel> currentTopics,
    final TopicExplanationModel? currentExplanation,
    final bool isLoading,
    final String? error,
  }) = _$LessonStateImpl;

  /// Ders bazlı topic cache'i
  @override
  Map<String, List<TopicModel>> get cachedTopics;

  /// Topic bazlı explanation cache'i
  @override
  Map<String, TopicExplanationModel> get cachedExplanations;

  /// Şu an görüntülenen topic listesi
  @override
  List<TopicModel> get currentTopics;

  /// Şu an görüntülenen explanation
  @override
  TopicExplanationModel? get currentExplanation;

  /// Yükleniyor durumu
  @override
  bool get isLoading;

  /// Hata mesajı
  @override
  String? get error;

  /// Create a copy of LessonState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LessonStateImplCopyWith<_$LessonStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

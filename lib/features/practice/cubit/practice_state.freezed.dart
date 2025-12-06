// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'practice_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$PracticeState {
  /// Favori soru ID'leri (local + Firebase sync)
  Set<String> get favoriteIds => throw _privateConstructorUsedError;

  /// Yanlış cevap ID'leri (AI öğrenmesi için)
  Set<String> get wrongAnswerIds => throw _privateConstructorUsedError;

  /// Yükleniyor durumu
  bool get isLoading => throw _privateConstructorUsedError;

  /// Favori toggle işlemi devam ediyor mu
  bool get isTogglingFavorite => throw _privateConstructorUsedError;

  /// Hata mesajı
  String? get error => throw _privateConstructorUsedError;

  /// Create a copy of PracticeState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PracticeStateCopyWith<PracticeState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PracticeStateCopyWith<$Res> {
  factory $PracticeStateCopyWith(
    PracticeState value,
    $Res Function(PracticeState) then,
  ) = _$PracticeStateCopyWithImpl<$Res, PracticeState>;
  @useResult
  $Res call({
    Set<String> favoriteIds,
    Set<String> wrongAnswerIds,
    bool isLoading,
    bool isTogglingFavorite,
    String? error,
  });
}

/// @nodoc
class _$PracticeStateCopyWithImpl<$Res, $Val extends PracticeState>
    implements $PracticeStateCopyWith<$Res> {
  _$PracticeStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PracticeState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? favoriteIds = null,
    Object? wrongAnswerIds = null,
    Object? isLoading = null,
    Object? isTogglingFavorite = null,
    Object? error = freezed,
  }) {
    return _then(
      _value.copyWith(
            favoriteIds: null == favoriteIds
                ? _value.favoriteIds
                : favoriteIds // ignore: cast_nullable_to_non_nullable
                      as Set<String>,
            wrongAnswerIds: null == wrongAnswerIds
                ? _value.wrongAnswerIds
                : wrongAnswerIds // ignore: cast_nullable_to_non_nullable
                      as Set<String>,
            isLoading: null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                      as bool,
            isTogglingFavorite: null == isTogglingFavorite
                ? _value.isTogglingFavorite
                : isTogglingFavorite // ignore: cast_nullable_to_non_nullable
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
abstract class _$$PracticeStateImplCopyWith<$Res>
    implements $PracticeStateCopyWith<$Res> {
  factory _$$PracticeStateImplCopyWith(
    _$PracticeStateImpl value,
    $Res Function(_$PracticeStateImpl) then,
  ) = __$$PracticeStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    Set<String> favoriteIds,
    Set<String> wrongAnswerIds,
    bool isLoading,
    bool isTogglingFavorite,
    String? error,
  });
}

/// @nodoc
class __$$PracticeStateImplCopyWithImpl<$Res>
    extends _$PracticeStateCopyWithImpl<$Res, _$PracticeStateImpl>
    implements _$$PracticeStateImplCopyWith<$Res> {
  __$$PracticeStateImplCopyWithImpl(
    _$PracticeStateImpl _value,
    $Res Function(_$PracticeStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PracticeState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? favoriteIds = null,
    Object? wrongAnswerIds = null,
    Object? isLoading = null,
    Object? isTogglingFavorite = null,
    Object? error = freezed,
  }) {
    return _then(
      _$PracticeStateImpl(
        favoriteIds: null == favoriteIds
            ? _value._favoriteIds
            : favoriteIds // ignore: cast_nullable_to_non_nullable
                  as Set<String>,
        wrongAnswerIds: null == wrongAnswerIds
            ? _value._wrongAnswerIds
            : wrongAnswerIds // ignore: cast_nullable_to_non_nullable
                  as Set<String>,
        isLoading: null == isLoading
            ? _value.isLoading
            : isLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        isTogglingFavorite: null == isTogglingFavorite
            ? _value.isTogglingFavorite
            : isTogglingFavorite // ignore: cast_nullable_to_non_nullable
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

class _$PracticeStateImpl implements _PracticeState {
  const _$PracticeStateImpl({
    final Set<String> favoriteIds = const {},
    final Set<String> wrongAnswerIds = const {},
    this.isLoading = false,
    this.isTogglingFavorite = false,
    this.error,
  }) : _favoriteIds = favoriteIds,
       _wrongAnswerIds = wrongAnswerIds;

  /// Favori soru ID'leri (local + Firebase sync)
  final Set<String> _favoriteIds;

  /// Favori soru ID'leri (local + Firebase sync)
  @override
  @JsonKey()
  Set<String> get favoriteIds {
    if (_favoriteIds is EqualUnmodifiableSetView) return _favoriteIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_favoriteIds);
  }

  /// Yanlış cevap ID'leri (AI öğrenmesi için)
  final Set<String> _wrongAnswerIds;

  /// Yanlış cevap ID'leri (AI öğrenmesi için)
  @override
  @JsonKey()
  Set<String> get wrongAnswerIds {
    if (_wrongAnswerIds is EqualUnmodifiableSetView) return _wrongAnswerIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_wrongAnswerIds);
  }

  /// Yükleniyor durumu
  @override
  @JsonKey()
  final bool isLoading;

  /// Favori toggle işlemi devam ediyor mu
  @override
  @JsonKey()
  final bool isTogglingFavorite;

  /// Hata mesajı
  @override
  final String? error;

  @override
  String toString() {
    return 'PracticeState(favoriteIds: $favoriteIds, wrongAnswerIds: $wrongAnswerIds, isLoading: $isLoading, isTogglingFavorite: $isTogglingFavorite, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PracticeStateImpl &&
            const DeepCollectionEquality().equals(
              other._favoriteIds,
              _favoriteIds,
            ) &&
            const DeepCollectionEquality().equals(
              other._wrongAnswerIds,
              _wrongAnswerIds,
            ) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isTogglingFavorite, isTogglingFavorite) ||
                other.isTogglingFavorite == isTogglingFavorite) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_favoriteIds),
    const DeepCollectionEquality().hash(_wrongAnswerIds),
    isLoading,
    isTogglingFavorite,
    error,
  );

  /// Create a copy of PracticeState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PracticeStateImplCopyWith<_$PracticeStateImpl> get copyWith =>
      __$$PracticeStateImplCopyWithImpl<_$PracticeStateImpl>(this, _$identity);
}

abstract class _PracticeState implements PracticeState {
  const factory _PracticeState({
    final Set<String> favoriteIds,
    final Set<String> wrongAnswerIds,
    final bool isLoading,
    final bool isTogglingFavorite,
    final String? error,
  }) = _$PracticeStateImpl;

  /// Favori soru ID'leri (local + Firebase sync)
  @override
  Set<String> get favoriteIds;

  /// Yanlış cevap ID'leri (AI öğrenmesi için)
  @override
  Set<String> get wrongAnswerIds;

  /// Yükleniyor durumu
  @override
  bool get isLoading;

  /// Favori toggle işlemi devam ediyor mu
  @override
  bool get isTogglingFavorite;

  /// Hata mesajı
  @override
  String? get error;

  /// Create a copy of PracticeState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PracticeStateImplCopyWith<_$PracticeStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

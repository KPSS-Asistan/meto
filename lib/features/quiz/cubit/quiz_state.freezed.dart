// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quiz_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$QuizState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<QuestionModel> questions,
      int currentQuestionIndex,
      Map<int, String> userAnswers,
      String? selectedOption,
      bool isAnswered,
      int remainingSeconds,
      String? topicId,
    )
    loaded,
    required TResult Function(
      List<QuestionModel> questions,
      Map<int, String> userAnswers,
      int score,
    )
    finished,
    required TResult Function(String message) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      List<QuestionModel> questions,
      int currentQuestionIndex,
      Map<int, String> userAnswers,
      String? selectedOption,
      bool isAnswered,
      int remainingSeconds,
      String? topicId,
    )?
    loaded,
    TResult? Function(
      List<QuestionModel> questions,
      Map<int, String> userAnswers,
      int score,
    )?
    finished,
    TResult? Function(String message)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      List<QuestionModel> questions,
      int currentQuestionIndex,
      Map<int, String> userAnswers,
      String? selectedOption,
      bool isAnswered,
      int remainingSeconds,
      String? topicId,
    )?
    loaded,
    TResult Function(
      List<QuestionModel> questions,
      Map<int, String> userAnswers,
      int score,
    )?
    finished,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_Finished value) finished,
    required TResult Function(_Error value) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_Finished value)? finished,
    TResult? Function(_Error value)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_Finished value)? finished,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuizStateCopyWith<$Res> {
  factory $QuizStateCopyWith(QuizState value, $Res Function(QuizState) then) =
      _$QuizStateCopyWithImpl<$Res, QuizState>;
}

/// @nodoc
class _$QuizStateCopyWithImpl<$Res, $Val extends QuizState>
    implements $QuizStateCopyWith<$Res> {
  _$QuizStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of QuizState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$InitialImplCopyWith<$Res> {
  factory _$$InitialImplCopyWith(
    _$InitialImpl value,
    $Res Function(_$InitialImpl) then,
  ) = __$$InitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$InitialImplCopyWithImpl<$Res>
    extends _$QuizStateCopyWithImpl<$Res, _$InitialImpl>
    implements _$$InitialImplCopyWith<$Res> {
  __$$InitialImplCopyWithImpl(
    _$InitialImpl _value,
    $Res Function(_$InitialImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of QuizState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$InitialImpl implements _Initial {
  const _$InitialImpl();

  @override
  String toString() {
    return 'QuizState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$InitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<QuestionModel> questions,
      int currentQuestionIndex,
      Map<int, String> userAnswers,
      String? selectedOption,
      bool isAnswered,
      int remainingSeconds,
      String? topicId,
    )
    loaded,
    required TResult Function(
      List<QuestionModel> questions,
      Map<int, String> userAnswers,
      int score,
    )
    finished,
    required TResult Function(String message) error,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      List<QuestionModel> questions,
      int currentQuestionIndex,
      Map<int, String> userAnswers,
      String? selectedOption,
      bool isAnswered,
      int remainingSeconds,
      String? topicId,
    )?
    loaded,
    TResult? Function(
      List<QuestionModel> questions,
      Map<int, String> userAnswers,
      int score,
    )?
    finished,
    TResult? Function(String message)? error,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      List<QuestionModel> questions,
      int currentQuestionIndex,
      Map<int, String> userAnswers,
      String? selectedOption,
      bool isAnswered,
      int remainingSeconds,
      String? topicId,
    )?
    loaded,
    TResult Function(
      List<QuestionModel> questions,
      Map<int, String> userAnswers,
      int score,
    )?
    finished,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_Finished value) finished,
    required TResult Function(_Error value) error,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_Finished value)? finished,
    TResult? Function(_Error value)? error,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_Finished value)? finished,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class _Initial implements QuizState {
  const factory _Initial() = _$InitialImpl;
}

/// @nodoc
abstract class _$$LoadingImplCopyWith<$Res> {
  factory _$$LoadingImplCopyWith(
    _$LoadingImpl value,
    $Res Function(_$LoadingImpl) then,
  ) = __$$LoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LoadingImplCopyWithImpl<$Res>
    extends _$QuizStateCopyWithImpl<$Res, _$LoadingImpl>
    implements _$$LoadingImplCopyWith<$Res> {
  __$$LoadingImplCopyWithImpl(
    _$LoadingImpl _value,
    $Res Function(_$LoadingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of QuizState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$LoadingImpl implements _Loading {
  const _$LoadingImpl();

  @override
  String toString() {
    return 'QuizState.loading()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$LoadingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<QuestionModel> questions,
      int currentQuestionIndex,
      Map<int, String> userAnswers,
      String? selectedOption,
      bool isAnswered,
      int remainingSeconds,
      String? topicId,
    )
    loaded,
    required TResult Function(
      List<QuestionModel> questions,
      Map<int, String> userAnswers,
      int score,
    )
    finished,
    required TResult Function(String message) error,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      List<QuestionModel> questions,
      int currentQuestionIndex,
      Map<int, String> userAnswers,
      String? selectedOption,
      bool isAnswered,
      int remainingSeconds,
      String? topicId,
    )?
    loaded,
    TResult? Function(
      List<QuestionModel> questions,
      Map<int, String> userAnswers,
      int score,
    )?
    finished,
    TResult? Function(String message)? error,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      List<QuestionModel> questions,
      int currentQuestionIndex,
      Map<int, String> userAnswers,
      String? selectedOption,
      bool isAnswered,
      int remainingSeconds,
      String? topicId,
    )?
    loaded,
    TResult Function(
      List<QuestionModel> questions,
      Map<int, String> userAnswers,
      int score,
    )?
    finished,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_Finished value) finished,
    required TResult Function(_Error value) error,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_Finished value)? finished,
    TResult? Function(_Error value)? error,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_Finished value)? finished,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class _Loading implements QuizState {
  const factory _Loading() = _$LoadingImpl;
}

/// @nodoc
abstract class _$$LoadedImplCopyWith<$Res> {
  factory _$$LoadedImplCopyWith(
    _$LoadedImpl value,
    $Res Function(_$LoadedImpl) then,
  ) = __$$LoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({
    List<QuestionModel> questions,
    int currentQuestionIndex,
    Map<int, String> userAnswers,
    String? selectedOption,
    bool isAnswered,
    int remainingSeconds,
    String? topicId,
  });
}

/// @nodoc
class __$$LoadedImplCopyWithImpl<$Res>
    extends _$QuizStateCopyWithImpl<$Res, _$LoadedImpl>
    implements _$$LoadedImplCopyWith<$Res> {
  __$$LoadedImplCopyWithImpl(
    _$LoadedImpl _value,
    $Res Function(_$LoadedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of QuizState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? questions = null,
    Object? currentQuestionIndex = null,
    Object? userAnswers = null,
    Object? selectedOption = freezed,
    Object? isAnswered = null,
    Object? remainingSeconds = null,
    Object? topicId = freezed,
  }) {
    return _then(
      _$LoadedImpl(
        questions: null == questions
            ? _value._questions
            : questions // ignore: cast_nullable_to_non_nullable
                  as List<QuestionModel>,
        currentQuestionIndex: null == currentQuestionIndex
            ? _value.currentQuestionIndex
            : currentQuestionIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        userAnswers: null == userAnswers
            ? _value._userAnswers
            : userAnswers // ignore: cast_nullable_to_non_nullable
                  as Map<int, String>,
        selectedOption: freezed == selectedOption
            ? _value.selectedOption
            : selectedOption // ignore: cast_nullable_to_non_nullable
                  as String?,
        isAnswered: null == isAnswered
            ? _value.isAnswered
            : isAnswered // ignore: cast_nullable_to_non_nullable
                  as bool,
        remainingSeconds: null == remainingSeconds
            ? _value.remainingSeconds
            : remainingSeconds // ignore: cast_nullable_to_non_nullable
                  as int,
        topicId: freezed == topicId
            ? _value.topicId
            : topicId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$LoadedImpl implements _Loaded {
  const _$LoadedImpl({
    required final List<QuestionModel> questions,
    required this.currentQuestionIndex,
    final Map<int, String> userAnswers = const {},
    this.selectedOption,
    this.isAnswered = false,
    this.remainingSeconds = 1200,
    this.topicId,
  }) : _questions = questions,
       _userAnswers = userAnswers;

  final List<QuestionModel> _questions;
  @override
  List<QuestionModel> get questions {
    if (_questions is EqualUnmodifiableListView) return _questions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_questions);
  }

  @override
  final int currentQuestionIndex;
  final Map<int, String> _userAnswers;
  @override
  @JsonKey()
  Map<int, String> get userAnswers {
    if (_userAnswers is EqualUnmodifiableMapView) return _userAnswers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_userAnswers);
  }

  // questionIndex => selectedOption (A-E)
  @override
  final String? selectedOption;
  @override
  @JsonKey()
  final bool isAnswered;
  @override
  @JsonKey()
  final int remainingSeconds;
  // 20 dakika = 1200 saniye
  @override
  final String? topicId;

  @override
  String toString() {
    return 'QuizState.loaded(questions: $questions, currentQuestionIndex: $currentQuestionIndex, userAnswers: $userAnswers, selectedOption: $selectedOption, isAnswered: $isAnswered, remainingSeconds: $remainingSeconds, topicId: $topicId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoadedImpl &&
            const DeepCollectionEquality().equals(
              other._questions,
              _questions,
            ) &&
            (identical(other.currentQuestionIndex, currentQuestionIndex) ||
                other.currentQuestionIndex == currentQuestionIndex) &&
            const DeepCollectionEquality().equals(
              other._userAnswers,
              _userAnswers,
            ) &&
            (identical(other.selectedOption, selectedOption) ||
                other.selectedOption == selectedOption) &&
            (identical(other.isAnswered, isAnswered) ||
                other.isAnswered == isAnswered) &&
            (identical(other.remainingSeconds, remainingSeconds) ||
                other.remainingSeconds == remainingSeconds) &&
            (identical(other.topicId, topicId) || other.topicId == topicId));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_questions),
    currentQuestionIndex,
    const DeepCollectionEquality().hash(_userAnswers),
    selectedOption,
    isAnswered,
    remainingSeconds,
    topicId,
  );

  /// Create a copy of QuizState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LoadedImplCopyWith<_$LoadedImpl> get copyWith =>
      __$$LoadedImplCopyWithImpl<_$LoadedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<QuestionModel> questions,
      int currentQuestionIndex,
      Map<int, String> userAnswers,
      String? selectedOption,
      bool isAnswered,
      int remainingSeconds,
      String? topicId,
    )
    loaded,
    required TResult Function(
      List<QuestionModel> questions,
      Map<int, String> userAnswers,
      int score,
    )
    finished,
    required TResult Function(String message) error,
  }) {
    return loaded(
      questions,
      currentQuestionIndex,
      userAnswers,
      selectedOption,
      isAnswered,
      remainingSeconds,
      topicId,
    );
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      List<QuestionModel> questions,
      int currentQuestionIndex,
      Map<int, String> userAnswers,
      String? selectedOption,
      bool isAnswered,
      int remainingSeconds,
      String? topicId,
    )?
    loaded,
    TResult? Function(
      List<QuestionModel> questions,
      Map<int, String> userAnswers,
      int score,
    )?
    finished,
    TResult? Function(String message)? error,
  }) {
    return loaded?.call(
      questions,
      currentQuestionIndex,
      userAnswers,
      selectedOption,
      isAnswered,
      remainingSeconds,
      topicId,
    );
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      List<QuestionModel> questions,
      int currentQuestionIndex,
      Map<int, String> userAnswers,
      String? selectedOption,
      bool isAnswered,
      int remainingSeconds,
      String? topicId,
    )?
    loaded,
    TResult Function(
      List<QuestionModel> questions,
      Map<int, String> userAnswers,
      int score,
    )?
    finished,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(
        questions,
        currentQuestionIndex,
        userAnswers,
        selectedOption,
        isAnswered,
        remainingSeconds,
        topicId,
      );
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_Finished value) finished,
    required TResult Function(_Error value) error,
  }) {
    return loaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_Finished value)? finished,
    TResult? Function(_Error value)? error,
  }) {
    return loaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_Finished value)? finished,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(this);
    }
    return orElse();
  }
}

abstract class _Loaded implements QuizState {
  const factory _Loaded({
    required final List<QuestionModel> questions,
    required final int currentQuestionIndex,
    final Map<int, String> userAnswers,
    final String? selectedOption,
    final bool isAnswered,
    final int remainingSeconds,
    final String? topicId,
  }) = _$LoadedImpl;

  List<QuestionModel> get questions;
  int get currentQuestionIndex;
  Map<int, String> get userAnswers; // questionIndex => selectedOption (A-E)
  String? get selectedOption;
  bool get isAnswered;
  int get remainingSeconds; // 20 dakika = 1200 saniye
  String? get topicId;

  /// Create a copy of QuizState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LoadedImplCopyWith<_$LoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$FinishedImplCopyWith<$Res> {
  factory _$$FinishedImplCopyWith(
    _$FinishedImpl value,
    $Res Function(_$FinishedImpl) then,
  ) = __$$FinishedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({
    List<QuestionModel> questions,
    Map<int, String> userAnswers,
    int score,
  });
}

/// @nodoc
class __$$FinishedImplCopyWithImpl<$Res>
    extends _$QuizStateCopyWithImpl<$Res, _$FinishedImpl>
    implements _$$FinishedImplCopyWith<$Res> {
  __$$FinishedImplCopyWithImpl(
    _$FinishedImpl _value,
    $Res Function(_$FinishedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of QuizState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? questions = null,
    Object? userAnswers = null,
    Object? score = null,
  }) {
    return _then(
      _$FinishedImpl(
        questions: null == questions
            ? _value._questions
            : questions // ignore: cast_nullable_to_non_nullable
                  as List<QuestionModel>,
        userAnswers: null == userAnswers
            ? _value._userAnswers
            : userAnswers // ignore: cast_nullable_to_non_nullable
                  as Map<int, String>,
        score: null == score
            ? _value.score
            : score // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$FinishedImpl implements _Finished {
  const _$FinishedImpl({
    required final List<QuestionModel> questions,
    required final Map<int, String> userAnswers,
    required this.score,
  }) : _questions = questions,
       _userAnswers = userAnswers;

  final List<QuestionModel> _questions;
  @override
  List<QuestionModel> get questions {
    if (_questions is EqualUnmodifiableListView) return _questions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_questions);
  }

  final Map<int, String> _userAnswers;
  @override
  Map<int, String> get userAnswers {
    if (_userAnswers is EqualUnmodifiableMapView) return _userAnswers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_userAnswers);
  }

  @override
  final int score;

  @override
  String toString() {
    return 'QuizState.finished(questions: $questions, userAnswers: $userAnswers, score: $score)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FinishedImpl &&
            const DeepCollectionEquality().equals(
              other._questions,
              _questions,
            ) &&
            const DeepCollectionEquality().equals(
              other._userAnswers,
              _userAnswers,
            ) &&
            (identical(other.score, score) || other.score == score));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_questions),
    const DeepCollectionEquality().hash(_userAnswers),
    score,
  );

  /// Create a copy of QuizState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FinishedImplCopyWith<_$FinishedImpl> get copyWith =>
      __$$FinishedImplCopyWithImpl<_$FinishedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<QuestionModel> questions,
      int currentQuestionIndex,
      Map<int, String> userAnswers,
      String? selectedOption,
      bool isAnswered,
      int remainingSeconds,
      String? topicId,
    )
    loaded,
    required TResult Function(
      List<QuestionModel> questions,
      Map<int, String> userAnswers,
      int score,
    )
    finished,
    required TResult Function(String message) error,
  }) {
    return finished(questions, userAnswers, score);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      List<QuestionModel> questions,
      int currentQuestionIndex,
      Map<int, String> userAnswers,
      String? selectedOption,
      bool isAnswered,
      int remainingSeconds,
      String? topicId,
    )?
    loaded,
    TResult? Function(
      List<QuestionModel> questions,
      Map<int, String> userAnswers,
      int score,
    )?
    finished,
    TResult? Function(String message)? error,
  }) {
    return finished?.call(questions, userAnswers, score);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      List<QuestionModel> questions,
      int currentQuestionIndex,
      Map<int, String> userAnswers,
      String? selectedOption,
      bool isAnswered,
      int remainingSeconds,
      String? topicId,
    )?
    loaded,
    TResult Function(
      List<QuestionModel> questions,
      Map<int, String> userAnswers,
      int score,
    )?
    finished,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (finished != null) {
      return finished(questions, userAnswers, score);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_Finished value) finished,
    required TResult Function(_Error value) error,
  }) {
    return finished(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_Finished value)? finished,
    TResult? Function(_Error value)? error,
  }) {
    return finished?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_Finished value)? finished,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (finished != null) {
      return finished(this);
    }
    return orElse();
  }
}

abstract class _Finished implements QuizState {
  const factory _Finished({
    required final List<QuestionModel> questions,
    required final Map<int, String> userAnswers,
    required final int score,
  }) = _$FinishedImpl;

  List<QuestionModel> get questions;
  Map<int, String> get userAnswers;
  int get score;

  /// Create a copy of QuizState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FinishedImplCopyWith<_$FinishedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ErrorImplCopyWith<$Res> {
  factory _$$ErrorImplCopyWith(
    _$ErrorImpl value,
    $Res Function(_$ErrorImpl) then,
  ) = __$$ErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$ErrorImplCopyWithImpl<$Res>
    extends _$QuizStateCopyWithImpl<$Res, _$ErrorImpl>
    implements _$$ErrorImplCopyWith<$Res> {
  __$$ErrorImplCopyWithImpl(
    _$ErrorImpl _value,
    $Res Function(_$ErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of QuizState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$ErrorImpl(
        null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$ErrorImpl implements _Error {
  const _$ErrorImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'QuizState.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of QuizState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      __$$ErrorImplCopyWithImpl<_$ErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<QuestionModel> questions,
      int currentQuestionIndex,
      Map<int, String> userAnswers,
      String? selectedOption,
      bool isAnswered,
      int remainingSeconds,
      String? topicId,
    )
    loaded,
    required TResult Function(
      List<QuestionModel> questions,
      Map<int, String> userAnswers,
      int score,
    )
    finished,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      List<QuestionModel> questions,
      int currentQuestionIndex,
      Map<int, String> userAnswers,
      String? selectedOption,
      bool isAnswered,
      int remainingSeconds,
      String? topicId,
    )?
    loaded,
    TResult? Function(
      List<QuestionModel> questions,
      Map<int, String> userAnswers,
      int score,
    )?
    finished,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      List<QuestionModel> questions,
      int currentQuestionIndex,
      Map<int, String> userAnswers,
      String? selectedOption,
      bool isAnswered,
      int remainingSeconds,
      String? topicId,
    )?
    loaded,
    TResult Function(
      List<QuestionModel> questions,
      Map<int, String> userAnswers,
      int score,
    )?
    finished,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_Finished value) finished,
    required TResult Function(_Error value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_Finished value)? finished,
    TResult? Function(_Error value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_Finished value)? finished,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class _Error implements QuizState {
  const factory _Error(final String message) = _$ErrorImpl;

  String get message;

  /// Create a copy of QuizState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

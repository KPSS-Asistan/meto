// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$GameState {
  /// Oyun tipi
  GameType get gameType => throw _privateConstructorUsedError;

  /// Eşleştirme oyunu verileri
  List<Map<String, String>> get matchingPairs =>
      throw _privateConstructorUsedError;

  /// Hafıza oyunu verileri
  List<Map<String, String>> get memoryPairs =>
      throw _privateConstructorUsedError;

  /// Kelime avı verileri
  Map<String, List<String>> get wordHuntData =>
      throw _privateConstructorUsedError;

  /// Seçili soru (matching game)
  String? get selectedQuestion => throw _privateConstructorUsedError;

  /// Seçili cevap (matching game)
  String? get selectedAnswer => throw _privateConstructorUsedError;

  /// Eşleşmiş çiftler
  Set<String> get matchedPairs => throw _privateConstructorUsedError;

  /// Skor
  int get score => throw _privateConstructorUsedError;

  /// Maksimum skor
  int get maxScore => throw _privateConstructorUsedError;

  /// Oyun bitti mi
  bool get isGameOver => throw _privateConstructorUsedError;

  /// Yükleniyor
  bool get isLoading => throw _privateConstructorUsedError;

  /// Hata
  String? get error => throw _privateConstructorUsedError;

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GameStateCopyWith<GameState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameStateCopyWith<$Res> {
  factory $GameStateCopyWith(GameState value, $Res Function(GameState) then) =
      _$GameStateCopyWithImpl<$Res, GameState>;
  @useResult
  $Res call({
    GameType gameType,
    List<Map<String, String>> matchingPairs,
    List<Map<String, String>> memoryPairs,
    Map<String, List<String>> wordHuntData,
    String? selectedQuestion,
    String? selectedAnswer,
    Set<String> matchedPairs,
    int score,
    int maxScore,
    bool isGameOver,
    bool isLoading,
    String? error,
  });
}

/// @nodoc
class _$GameStateCopyWithImpl<$Res, $Val extends GameState>
    implements $GameStateCopyWith<$Res> {
  _$GameStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameType = null,
    Object? matchingPairs = null,
    Object? memoryPairs = null,
    Object? wordHuntData = null,
    Object? selectedQuestion = freezed,
    Object? selectedAnswer = freezed,
    Object? matchedPairs = null,
    Object? score = null,
    Object? maxScore = null,
    Object? isGameOver = null,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(
      _value.copyWith(
            gameType: null == gameType
                ? _value.gameType
                : gameType // ignore: cast_nullable_to_non_nullable
                      as GameType,
            matchingPairs: null == matchingPairs
                ? _value.matchingPairs
                : matchingPairs // ignore: cast_nullable_to_non_nullable
                      as List<Map<String, String>>,
            memoryPairs: null == memoryPairs
                ? _value.memoryPairs
                : memoryPairs // ignore: cast_nullable_to_non_nullable
                      as List<Map<String, String>>,
            wordHuntData: null == wordHuntData
                ? _value.wordHuntData
                : wordHuntData // ignore: cast_nullable_to_non_nullable
                      as Map<String, List<String>>,
            selectedQuestion: freezed == selectedQuestion
                ? _value.selectedQuestion
                : selectedQuestion // ignore: cast_nullable_to_non_nullable
                      as String?,
            selectedAnswer: freezed == selectedAnswer
                ? _value.selectedAnswer
                : selectedAnswer // ignore: cast_nullable_to_non_nullable
                      as String?,
            matchedPairs: null == matchedPairs
                ? _value.matchedPairs
                : matchedPairs // ignore: cast_nullable_to_non_nullable
                      as Set<String>,
            score: null == score
                ? _value.score
                : score // ignore: cast_nullable_to_non_nullable
                      as int,
            maxScore: null == maxScore
                ? _value.maxScore
                : maxScore // ignore: cast_nullable_to_non_nullable
                      as int,
            isGameOver: null == isGameOver
                ? _value.isGameOver
                : isGameOver // ignore: cast_nullable_to_non_nullable
                      as bool,
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
abstract class _$$GameStateImplCopyWith<$Res>
    implements $GameStateCopyWith<$Res> {
  factory _$$GameStateImplCopyWith(
    _$GameStateImpl value,
    $Res Function(_$GameStateImpl) then,
  ) = __$$GameStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    GameType gameType,
    List<Map<String, String>> matchingPairs,
    List<Map<String, String>> memoryPairs,
    Map<String, List<String>> wordHuntData,
    String? selectedQuestion,
    String? selectedAnswer,
    Set<String> matchedPairs,
    int score,
    int maxScore,
    bool isGameOver,
    bool isLoading,
    String? error,
  });
}

/// @nodoc
class __$$GameStateImplCopyWithImpl<$Res>
    extends _$GameStateCopyWithImpl<$Res, _$GameStateImpl>
    implements _$$GameStateImplCopyWith<$Res> {
  __$$GameStateImplCopyWithImpl(
    _$GameStateImpl _value,
    $Res Function(_$GameStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameType = null,
    Object? matchingPairs = null,
    Object? memoryPairs = null,
    Object? wordHuntData = null,
    Object? selectedQuestion = freezed,
    Object? selectedAnswer = freezed,
    Object? matchedPairs = null,
    Object? score = null,
    Object? maxScore = null,
    Object? isGameOver = null,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(
      _$GameStateImpl(
        gameType: null == gameType
            ? _value.gameType
            : gameType // ignore: cast_nullable_to_non_nullable
                  as GameType,
        matchingPairs: null == matchingPairs
            ? _value._matchingPairs
            : matchingPairs // ignore: cast_nullable_to_non_nullable
                  as List<Map<String, String>>,
        memoryPairs: null == memoryPairs
            ? _value._memoryPairs
            : memoryPairs // ignore: cast_nullable_to_non_nullable
                  as List<Map<String, String>>,
        wordHuntData: null == wordHuntData
            ? _value._wordHuntData
            : wordHuntData // ignore: cast_nullable_to_non_nullable
                  as Map<String, List<String>>,
        selectedQuestion: freezed == selectedQuestion
            ? _value.selectedQuestion
            : selectedQuestion // ignore: cast_nullable_to_non_nullable
                  as String?,
        selectedAnswer: freezed == selectedAnswer
            ? _value.selectedAnswer
            : selectedAnswer // ignore: cast_nullable_to_non_nullable
                  as String?,
        matchedPairs: null == matchedPairs
            ? _value._matchedPairs
            : matchedPairs // ignore: cast_nullable_to_non_nullable
                  as Set<String>,
        score: null == score
            ? _value.score
            : score // ignore: cast_nullable_to_non_nullable
                  as int,
        maxScore: null == maxScore
            ? _value.maxScore
            : maxScore // ignore: cast_nullable_to_non_nullable
                  as int,
        isGameOver: null == isGameOver
            ? _value.isGameOver
            : isGameOver // ignore: cast_nullable_to_non_nullable
                  as bool,
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

class _$GameStateImpl implements _GameState {
  const _$GameStateImpl({
    this.gameType = GameType.matching,
    final List<Map<String, String>> matchingPairs = const [],
    final List<Map<String, String>> memoryPairs = const [],
    final Map<String, List<String>> wordHuntData = const {},
    this.selectedQuestion,
    this.selectedAnswer,
    final Set<String> matchedPairs = const {},
    this.score = 0,
    this.maxScore = 0,
    this.isGameOver = false,
    this.isLoading = true,
    this.error,
  }) : _matchingPairs = matchingPairs,
       _memoryPairs = memoryPairs,
       _wordHuntData = wordHuntData,
       _matchedPairs = matchedPairs;

  /// Oyun tipi
  @override
  @JsonKey()
  final GameType gameType;

  /// Eşleştirme oyunu verileri
  final List<Map<String, String>> _matchingPairs;

  /// Eşleştirme oyunu verileri
  @override
  @JsonKey()
  List<Map<String, String>> get matchingPairs {
    if (_matchingPairs is EqualUnmodifiableListView) return _matchingPairs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_matchingPairs);
  }

  /// Hafıza oyunu verileri
  final List<Map<String, String>> _memoryPairs;

  /// Hafıza oyunu verileri
  @override
  @JsonKey()
  List<Map<String, String>> get memoryPairs {
    if (_memoryPairs is EqualUnmodifiableListView) return _memoryPairs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_memoryPairs);
  }

  /// Kelime avı verileri
  final Map<String, List<String>> _wordHuntData;

  /// Kelime avı verileri
  @override
  @JsonKey()
  Map<String, List<String>> get wordHuntData {
    if (_wordHuntData is EqualUnmodifiableMapView) return _wordHuntData;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_wordHuntData);
  }

  /// Seçili soru (matching game)
  @override
  final String? selectedQuestion;

  /// Seçili cevap (matching game)
  @override
  final String? selectedAnswer;

  /// Eşleşmiş çiftler
  final Set<String> _matchedPairs;

  /// Eşleşmiş çiftler
  @override
  @JsonKey()
  Set<String> get matchedPairs {
    if (_matchedPairs is EqualUnmodifiableSetView) return _matchedPairs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_matchedPairs);
  }

  /// Skor
  @override
  @JsonKey()
  final int score;

  /// Maksimum skor
  @override
  @JsonKey()
  final int maxScore;

  /// Oyun bitti mi
  @override
  @JsonKey()
  final bool isGameOver;

  /// Yükleniyor
  @override
  @JsonKey()
  final bool isLoading;

  /// Hata
  @override
  final String? error;

  @override
  String toString() {
    return 'GameState(gameType: $gameType, matchingPairs: $matchingPairs, memoryPairs: $memoryPairs, wordHuntData: $wordHuntData, selectedQuestion: $selectedQuestion, selectedAnswer: $selectedAnswer, matchedPairs: $matchedPairs, score: $score, maxScore: $maxScore, isGameOver: $isGameOver, isLoading: $isLoading, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameStateImpl &&
            (identical(other.gameType, gameType) ||
                other.gameType == gameType) &&
            const DeepCollectionEquality().equals(
              other._matchingPairs,
              _matchingPairs,
            ) &&
            const DeepCollectionEquality().equals(
              other._memoryPairs,
              _memoryPairs,
            ) &&
            const DeepCollectionEquality().equals(
              other._wordHuntData,
              _wordHuntData,
            ) &&
            (identical(other.selectedQuestion, selectedQuestion) ||
                other.selectedQuestion == selectedQuestion) &&
            (identical(other.selectedAnswer, selectedAnswer) ||
                other.selectedAnswer == selectedAnswer) &&
            const DeepCollectionEquality().equals(
              other._matchedPairs,
              _matchedPairs,
            ) &&
            (identical(other.score, score) || other.score == score) &&
            (identical(other.maxScore, maxScore) ||
                other.maxScore == maxScore) &&
            (identical(other.isGameOver, isGameOver) ||
                other.isGameOver == isGameOver) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    gameType,
    const DeepCollectionEquality().hash(_matchingPairs),
    const DeepCollectionEquality().hash(_memoryPairs),
    const DeepCollectionEquality().hash(_wordHuntData),
    selectedQuestion,
    selectedAnswer,
    const DeepCollectionEquality().hash(_matchedPairs),
    score,
    maxScore,
    isGameOver,
    isLoading,
    error,
  );

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GameStateImplCopyWith<_$GameStateImpl> get copyWith =>
      __$$GameStateImplCopyWithImpl<_$GameStateImpl>(this, _$identity);
}

abstract class _GameState implements GameState {
  const factory _GameState({
    final GameType gameType,
    final List<Map<String, String>> matchingPairs,
    final List<Map<String, String>> memoryPairs,
    final Map<String, List<String>> wordHuntData,
    final String? selectedQuestion,
    final String? selectedAnswer,
    final Set<String> matchedPairs,
    final int score,
    final int maxScore,
    final bool isGameOver,
    final bool isLoading,
    final String? error,
  }) = _$GameStateImpl;

  /// Oyun tipi
  @override
  GameType get gameType;

  /// Eşleştirme oyunu verileri
  @override
  List<Map<String, String>> get matchingPairs;

  /// Hafıza oyunu verileri
  @override
  List<Map<String, String>> get memoryPairs;

  /// Kelime avı verileri
  @override
  Map<String, List<String>> get wordHuntData;

  /// Seçili soru (matching game)
  @override
  String? get selectedQuestion;

  /// Seçili cevap (matching game)
  @override
  String? get selectedAnswer;

  /// Eşleşmiş çiftler
  @override
  Set<String> get matchedPairs;

  /// Skor
  @override
  int get score;

  /// Maksimum skor
  @override
  int get maxScore;

  /// Oyun bitti mi
  @override
  bool get isGameOver;

  /// Yükleniyor
  @override
  bool get isLoading;

  /// Hata
  @override
  String? get error;

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameStateImplCopyWith<_$GameStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

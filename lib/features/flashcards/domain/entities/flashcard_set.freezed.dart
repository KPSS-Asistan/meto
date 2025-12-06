// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'flashcard_set.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

FlashcardSet _$FlashcardSetFromJson(Map<String, dynamic> json) {
  return _FlashcardSet.fromJson(json);
}

/// @nodoc
mixin _$FlashcardSet {
  String get id => throw _privateConstructorUsedError;
  String get topicId => throw _privateConstructorUsedError;
  String get topicName => throw _privateConstructorUsedError;
  List<Flashcard> get cards => throw _privateConstructorUsedError;
  int get totalCards => throw _privateConstructorUsedError;

  /// Serializes this FlashcardSet to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FlashcardSet
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FlashcardSetCopyWith<FlashcardSet> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FlashcardSetCopyWith<$Res> {
  factory $FlashcardSetCopyWith(
    FlashcardSet value,
    $Res Function(FlashcardSet) then,
  ) = _$FlashcardSetCopyWithImpl<$Res, FlashcardSet>;
  @useResult
  $Res call({
    String id,
    String topicId,
    String topicName,
    List<Flashcard> cards,
    int totalCards,
  });
}

/// @nodoc
class _$FlashcardSetCopyWithImpl<$Res, $Val extends FlashcardSet>
    implements $FlashcardSetCopyWith<$Res> {
  _$FlashcardSetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FlashcardSet
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? topicId = null,
    Object? topicName = null,
    Object? cards = null,
    Object? totalCards = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            topicId: null == topicId
                ? _value.topicId
                : topicId // ignore: cast_nullable_to_non_nullable
                      as String,
            topicName: null == topicName
                ? _value.topicName
                : topicName // ignore: cast_nullable_to_non_nullable
                      as String,
            cards: null == cards
                ? _value.cards
                : cards // ignore: cast_nullable_to_non_nullable
                      as List<Flashcard>,
            totalCards: null == totalCards
                ? _value.totalCards
                : totalCards // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FlashcardSetImplCopyWith<$Res>
    implements $FlashcardSetCopyWith<$Res> {
  factory _$$FlashcardSetImplCopyWith(
    _$FlashcardSetImpl value,
    $Res Function(_$FlashcardSetImpl) then,
  ) = __$$FlashcardSetImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String topicId,
    String topicName,
    List<Flashcard> cards,
    int totalCards,
  });
}

/// @nodoc
class __$$FlashcardSetImplCopyWithImpl<$Res>
    extends _$FlashcardSetCopyWithImpl<$Res, _$FlashcardSetImpl>
    implements _$$FlashcardSetImplCopyWith<$Res> {
  __$$FlashcardSetImplCopyWithImpl(
    _$FlashcardSetImpl _value,
    $Res Function(_$FlashcardSetImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FlashcardSet
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? topicId = null,
    Object? topicName = null,
    Object? cards = null,
    Object? totalCards = null,
  }) {
    return _then(
      _$FlashcardSetImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        topicId: null == topicId
            ? _value.topicId
            : topicId // ignore: cast_nullable_to_non_nullable
                  as String,
        topicName: null == topicName
            ? _value.topicName
            : topicName // ignore: cast_nullable_to_non_nullable
                  as String,
        cards: null == cards
            ? _value._cards
            : cards // ignore: cast_nullable_to_non_nullable
                  as List<Flashcard>,
        totalCards: null == totalCards
            ? _value.totalCards
            : totalCards // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FlashcardSetImpl implements _FlashcardSet {
  const _$FlashcardSetImpl({
    required this.id,
    required this.topicId,
    required this.topicName,
    required final List<Flashcard> cards,
    this.totalCards = 0,
  }) : _cards = cards;

  factory _$FlashcardSetImpl.fromJson(Map<String, dynamic> json) =>
      _$$FlashcardSetImplFromJson(json);

  @override
  final String id;
  @override
  final String topicId;
  @override
  final String topicName;
  final List<Flashcard> _cards;
  @override
  List<Flashcard> get cards {
    if (_cards is EqualUnmodifiableListView) return _cards;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_cards);
  }

  @override
  @JsonKey()
  final int totalCards;

  @override
  String toString() {
    return 'FlashcardSet(id: $id, topicId: $topicId, topicName: $topicName, cards: $cards, totalCards: $totalCards)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FlashcardSetImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.topicId, topicId) || other.topicId == topicId) &&
            (identical(other.topicName, topicName) ||
                other.topicName == topicName) &&
            const DeepCollectionEquality().equals(other._cards, _cards) &&
            (identical(other.totalCards, totalCards) ||
                other.totalCards == totalCards));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    topicId,
    topicName,
    const DeepCollectionEquality().hash(_cards),
    totalCards,
  );

  /// Create a copy of FlashcardSet
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FlashcardSetImplCopyWith<_$FlashcardSetImpl> get copyWith =>
      __$$FlashcardSetImplCopyWithImpl<_$FlashcardSetImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FlashcardSetImplToJson(this);
  }
}

abstract class _FlashcardSet implements FlashcardSet {
  const factory _FlashcardSet({
    required final String id,
    required final String topicId,
    required final String topicName,
    required final List<Flashcard> cards,
    final int totalCards,
  }) = _$FlashcardSetImpl;

  factory _FlashcardSet.fromJson(Map<String, dynamic> json) =
      _$FlashcardSetImpl.fromJson;

  @override
  String get id;
  @override
  String get topicId;
  @override
  String get topicName;
  @override
  List<Flashcard> get cards;
  @override
  int get totalCards;

  /// Create a copy of FlashcardSet
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FlashcardSetImplCopyWith<_$FlashcardSetImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

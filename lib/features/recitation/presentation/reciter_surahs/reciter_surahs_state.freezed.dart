// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reciter_surahs_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReciterSurahsState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is ReciterSurahsState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'ReciterSurahsState()';
  }
}

/// @nodoc
class $ReciterSurahsStateCopyWith<$Res> {
  $ReciterSurahsStateCopyWith(
      ReciterSurahsState _, $Res Function(ReciterSurahsState) __);
}

/// Adds pattern-matching-related methods to [ReciterSurahsState].
extension ReciterSurahsStatePatterns on ReciterSurahsState {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ReciterSurahsLoading value)? loading,
    TResult Function(ReciterSurahsReady value)? ready,
    TResult Function(ReciterSurahsFailed value)? failed,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case ReciterSurahsLoading() when loading != null:
        return loading(_that);
      case ReciterSurahsReady() when ready != null:
        return ready(_that);
      case ReciterSurahsFailed() when failed != null:
        return failed(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ReciterSurahsLoading value) loading,
    required TResult Function(ReciterSurahsReady value) ready,
    required TResult Function(ReciterSurahsFailed value) failed,
  }) {
    final _that = this;
    switch (_that) {
      case ReciterSurahsLoading():
        return loading(_that);
      case ReciterSurahsReady():
        return ready(_that);
      case ReciterSurahsFailed():
        return failed(_that);
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ReciterSurahsLoading value)? loading,
    TResult? Function(ReciterSurahsReady value)? ready,
    TResult? Function(ReciterSurahsFailed value)? failed,
  }) {
    final _that = this;
    switch (_that) {
      case ReciterSurahsLoading() when loading != null:
        return loading(_that);
      case ReciterSurahsReady() when ready != null:
        return ready(_that);
      case ReciterSurahsFailed() when failed != null:
        return failed(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(ReciterInfo row, List<int> surahNumbers,
            Map<int, String> names, Map<int, String> previews)?
        ready,
    TResult Function()? failed,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case ReciterSurahsLoading() when loading != null:
        return loading();
      case ReciterSurahsReady() when ready != null:
        return ready(
            _that.row, _that.surahNumbers, _that.names, _that.previews);
      case ReciterSurahsFailed() when failed != null:
        return failed();
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loading,
    required TResult Function(ReciterInfo row, List<int> surahNumbers,
            Map<int, String> names, Map<int, String> previews)
        ready,
    required TResult Function() failed,
  }) {
    final _that = this;
    switch (_that) {
      case ReciterSurahsLoading():
        return loading();
      case ReciterSurahsReady():
        return ready(
            _that.row, _that.surahNumbers, _that.names, _that.previews);
      case ReciterSurahsFailed():
        return failed();
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loading,
    TResult? Function(ReciterInfo row, List<int> surahNumbers,
            Map<int, String> names, Map<int, String> previews)?
        ready,
    TResult? Function()? failed,
  }) {
    final _that = this;
    switch (_that) {
      case ReciterSurahsLoading() when loading != null:
        return loading();
      case ReciterSurahsReady() when ready != null:
        return ready(
            _that.row, _that.surahNumbers, _that.names, _that.previews);
      case ReciterSurahsFailed() when failed != null:
        return failed();
      case _:
        return null;
    }
  }
}

/// @nodoc

class ReciterSurahsLoading implements ReciterSurahsState {
  const ReciterSurahsLoading();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is ReciterSurahsLoading);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'ReciterSurahsState.loading()';
  }
}

/// @nodoc

class ReciterSurahsReady implements ReciterSurahsState {
  const ReciterSurahsReady(
      {required this.row,
      List<int> surahNumbers = const <int>[],
      Map<int, String> names = const <int, String>{},
      Map<int, String> previews = const <int, String>{}})
      : _surahNumbers = surahNumbers,
        _names = names,
        _previews = previews;

  final ReciterInfo row;
  final List<int> _surahNumbers;
  @JsonKey()
  List<int> get surahNumbers {
    if (_surahNumbers is EqualUnmodifiableListView) return _surahNumbers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_surahNumbers);
  }

  final Map<int, String> _names;
  @JsonKey()
  Map<int, String> get names {
    if (_names is EqualUnmodifiableMapView) return _names;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_names);
  }

  final Map<int, String> _previews;
  @JsonKey()
  Map<int, String> get previews {
    if (_previews is EqualUnmodifiableMapView) return _previews;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_previews);
  }

  /// Create a copy of ReciterSurahsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ReciterSurahsReadyCopyWith<ReciterSurahsReady> get copyWith =>
      _$ReciterSurahsReadyCopyWithImpl<ReciterSurahsReady>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ReciterSurahsReady &&
            (identical(other.row, row) || other.row == row) &&
            const DeepCollectionEquality()
                .equals(other.surahNumbers, _surahNumbers) &&
            const DeepCollectionEquality().equals(other.names, _names) &&
            const DeepCollectionEquality().equals(other.previews, _previews));
  }

  @override
  int get hashCode {
    return Object.hash(
        runtimeType,
        row,
        const DeepCollectionEquality().hash(_surahNumbers),
        const DeepCollectionEquality().hash(_names),
        const DeepCollectionEquality().hash(_previews));
  }

  @override
  String toString() {
    return 'ReciterSurahsState.ready(row: $row, surahNumbers: $surahNumbers, names: $names, previews: $previews)';
  }
}

/// @nodoc
abstract mixin class $ReciterSurahsReadyCopyWith<$Res>
    implements $ReciterSurahsStateCopyWith<$Res> {
  factory $ReciterSurahsReadyCopyWith(
          ReciterSurahsReady value, $Res Function(ReciterSurahsReady) _then) =
      _$ReciterSurahsReadyCopyWithImpl;
  @useResult
  $Res call(
      {ReciterInfo row,
      List<int> surahNumbers,
      Map<int, String> names,
      Map<int, String> previews});
}

/// @nodoc
class _$ReciterSurahsReadyCopyWithImpl<$Res>
    implements $ReciterSurahsReadyCopyWith<$Res> {
  _$ReciterSurahsReadyCopyWithImpl(this._self, this._then);

  final ReciterSurahsReady _self;
  final $Res Function(ReciterSurahsReady) _then;

  /// Create a copy of ReciterSurahsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? row = null,
    Object? surahNumbers = null,
    Object? names = null,
    Object? previews = null,
  }) {
    return _then(ReciterSurahsReady(
      row: null == row
          ? _self.row
          : row // ignore: cast_nullable_to_non_nullable
              as ReciterInfo,
      surahNumbers: null == surahNumbers
          ? _self._surahNumbers
          : surahNumbers // ignore: cast_nullable_to_non_nullable
              as List<int>,
      names: null == names
          ? _self._names
          : names // ignore: cast_nullable_to_non_nullable
              as Map<int, String>,
      previews: null == previews
          ? _self._previews
          : previews // ignore: cast_nullable_to_non_nullable
              as Map<int, String>,
    ));
  }
}

/// @nodoc

class ReciterSurahsFailed implements ReciterSurahsState {
  const ReciterSurahsFailed();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is ReciterSurahsFailed);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'ReciterSurahsState.failed()';
  }
}

// dart format on

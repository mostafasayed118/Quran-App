// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'surah_index_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SurahIndexState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is SurahIndexState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'SurahIndexState()';
  }
}

/// @nodoc
class $SurahIndexStateCopyWith<$Res> {
  $SurahIndexStateCopyWith(
      SurahIndexState _, $Res Function(SurahIndexState) __);
}

/// Adds pattern-matching-related methods to [SurahIndexState].
extension SurahIndexStatePatterns on SurahIndexState {
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
    TResult Function(SurahIndexLoading value)? loading,
    TResult Function(SurahIndexReady value)? ready,
    TResult Function(SurahIndexFailed value)? failed,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case SurahIndexLoading() when loading != null:
        return loading(_that);
      case SurahIndexReady() when ready != null:
        return ready(_that);
      case SurahIndexFailed() when failed != null:
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
    required TResult Function(SurahIndexLoading value) loading,
    required TResult Function(SurahIndexReady value) ready,
    required TResult Function(SurahIndexFailed value) failed,
  }) {
    final _that = this;
    switch (_that) {
      case SurahIndexLoading():
        return loading(_that);
      case SurahIndexReady():
        return ready(_that);
      case SurahIndexFailed():
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
    TResult? Function(SurahIndexLoading value)? loading,
    TResult? Function(SurahIndexReady value)? ready,
    TResult? Function(SurahIndexFailed value)? failed,
  }) {
    final _that = this;
    switch (_that) {
      case SurahIndexLoading() when loading != null:
        return loading(_that);
      case SurahIndexReady() when ready != null:
        return ready(_that);
      case SurahIndexFailed() when failed != null:
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
    TResult Function(List<SurahSummary> surahs, String query)? ready,
    TResult Function()? failed,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case SurahIndexLoading() when loading != null:
        return loading();
      case SurahIndexReady() when ready != null:
        return ready(_that.surahs, _that.query);
      case SurahIndexFailed() when failed != null:
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
    required TResult Function(List<SurahSummary> surahs, String query) ready,
    required TResult Function() failed,
  }) {
    final _that = this;
    switch (_that) {
      case SurahIndexLoading():
        return loading();
      case SurahIndexReady():
        return ready(_that.surahs, _that.query);
      case SurahIndexFailed():
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
    TResult? Function(List<SurahSummary> surahs, String query)? ready,
    TResult? Function()? failed,
  }) {
    final _that = this;
    switch (_that) {
      case SurahIndexLoading() when loading != null:
        return loading();
      case SurahIndexReady() when ready != null:
        return ready(_that.surahs, _that.query);
      case SurahIndexFailed() when failed != null:
        return failed();
      case _:
        return null;
    }
  }
}

/// @nodoc

class SurahIndexLoading implements SurahIndexState {
  const SurahIndexLoading();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is SurahIndexLoading);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'SurahIndexState.loading()';
  }
}

/// @nodoc

class SurahIndexReady implements SurahIndexState {
  const SurahIndexReady(
      {List<SurahSummary> surahs = const <SurahSummary>[], this.query = ''})
      : _surahs = surahs;

  final List<SurahSummary> _surahs;
  @JsonKey()
  List<SurahSummary> get surahs {
    if (_surahs is EqualUnmodifiableListView) return _surahs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_surahs);
  }

  @JsonKey()
  final String query;

  /// Create a copy of SurahIndexState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SurahIndexReadyCopyWith<SurahIndexReady> get copyWith =>
      _$SurahIndexReadyCopyWithImpl<SurahIndexReady>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SurahIndexReady &&
            const DeepCollectionEquality().equals(other.surahs, _surahs) &&
            (identical(other.query, query) || other.query == query));
  }

  @override
  int get hashCode {
    return Object.hash(
        runtimeType, const DeepCollectionEquality().hash(_surahs), query);
  }

  @override
  String toString() {
    return 'SurahIndexState.ready(surahs: $surahs, query: $query)';
  }
}

/// @nodoc
abstract mixin class $SurahIndexReadyCopyWith<$Res>
    implements $SurahIndexStateCopyWith<$Res> {
  factory $SurahIndexReadyCopyWith(
          SurahIndexReady value, $Res Function(SurahIndexReady) _then) =
      _$SurahIndexReadyCopyWithImpl;
  @useResult
  $Res call({List<SurahSummary> surahs, String query});
}

/// @nodoc
class _$SurahIndexReadyCopyWithImpl<$Res>
    implements $SurahIndexReadyCopyWith<$Res> {
  _$SurahIndexReadyCopyWithImpl(this._self, this._then);

  final SurahIndexReady _self;
  final $Res Function(SurahIndexReady) _then;

  /// Create a copy of SurahIndexState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? surahs = null,
    Object? query = null,
  }) {
    return _then(SurahIndexReady(
      surahs: null == surahs
          ? _self._surahs
          : surahs // ignore: cast_nullable_to_non_nullable
              as List<SurahSummary>,
      query: null == query
          ? _self.query
          : query // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class SurahIndexFailed implements SurahIndexState {
  const SurahIndexFailed();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is SurahIndexFailed);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'SurahIndexState.failed()';
  }
}

// dart format on

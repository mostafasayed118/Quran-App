// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'juz_index_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JuzIndexState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is JuzIndexState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'JuzIndexState()';
  }
}

/// @nodoc
class $JuzIndexStateCopyWith<$Res> {
  $JuzIndexStateCopyWith(JuzIndexState _, $Res Function(JuzIndexState) __);
}

/// Adds pattern-matching-related methods to [JuzIndexState].
extension JuzIndexStatePatterns on JuzIndexState {
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
    TResult Function(JuzIndexLoading value)? loading,
    TResult Function(JuzIndexFailed value)? failed,
    TResult Function(JuzIndexReady value)? ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case JuzIndexLoading() when loading != null:
        return loading(_that);
      case JuzIndexFailed() when failed != null:
        return failed(_that);
      case JuzIndexReady() when ready != null:
        return ready(_that);
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
    required TResult Function(JuzIndexLoading value) loading,
    required TResult Function(JuzIndexFailed value) failed,
    required TResult Function(JuzIndexReady value) ready,
  }) {
    final _that = this;
    switch (_that) {
      case JuzIndexLoading():
        return loading(_that);
      case JuzIndexFailed():
        return failed(_that);
      case JuzIndexReady():
        return ready(_that);
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
    TResult? Function(JuzIndexLoading value)? loading,
    TResult? Function(JuzIndexFailed value)? failed,
    TResult? Function(JuzIndexReady value)? ready,
  }) {
    final _that = this;
    switch (_that) {
      case JuzIndexLoading() when loading != null:
        return loading(_that);
      case JuzIndexFailed() when failed != null:
        return failed(_that);
      case JuzIndexReady() when ready != null:
        return ready(_that);
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
    TResult Function()? failed,
    TResult Function(List<JuzSummary> juz)? ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case JuzIndexLoading() when loading != null:
        return loading();
      case JuzIndexFailed() when failed != null:
        return failed();
      case JuzIndexReady() when ready != null:
        return ready(_that.juz);
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
    required TResult Function() failed,
    required TResult Function(List<JuzSummary> juz) ready,
  }) {
    final _that = this;
    switch (_that) {
      case JuzIndexLoading():
        return loading();
      case JuzIndexFailed():
        return failed();
      case JuzIndexReady():
        return ready(_that.juz);
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
    TResult? Function()? failed,
    TResult? Function(List<JuzSummary> juz)? ready,
  }) {
    final _that = this;
    switch (_that) {
      case JuzIndexLoading() when loading != null:
        return loading();
      case JuzIndexFailed() when failed != null:
        return failed();
      case JuzIndexReady() when ready != null:
        return ready(_that.juz);
      case _:
        return null;
    }
  }
}

/// @nodoc

class JuzIndexLoading implements JuzIndexState {
  const JuzIndexLoading();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is JuzIndexLoading);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'JuzIndexState.loading()';
  }
}

/// @nodoc

class JuzIndexFailed implements JuzIndexState {
  const JuzIndexFailed();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is JuzIndexFailed);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'JuzIndexState.failed()';
  }
}

/// @nodoc

class JuzIndexReady implements JuzIndexState {
  const JuzIndexReady(List<JuzSummary> juz) : _juz = juz;

  final List<JuzSummary> _juz;
  List<JuzSummary> get juz {
    if (_juz is EqualUnmodifiableListView) return _juz;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_juz);
  }

  /// Create a copy of JuzIndexState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JuzIndexReadyCopyWith<JuzIndexReady> get copyWith =>
      _$JuzIndexReadyCopyWithImpl<JuzIndexReady>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JuzIndexReady &&
            const DeepCollectionEquality().equals(other.juz, _juz));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, const DeepCollectionEquality().hash(_juz));
  }

  @override
  String toString() {
    return 'JuzIndexState.ready(juz: $juz)';
  }
}

/// @nodoc
abstract mixin class $JuzIndexReadyCopyWith<$Res>
    implements $JuzIndexStateCopyWith<$Res> {
  factory $JuzIndexReadyCopyWith(
          JuzIndexReady value, $Res Function(JuzIndexReady) _then) =
      _$JuzIndexReadyCopyWithImpl;
  @useResult
  $Res call({List<JuzSummary> juz});
}

/// @nodoc
class _$JuzIndexReadyCopyWithImpl<$Res>
    implements $JuzIndexReadyCopyWith<$Res> {
  _$JuzIndexReadyCopyWithImpl(this._self, this._then);

  final JuzIndexReady _self;
  final $Res Function(JuzIndexReady) _then;

  /// Create a copy of JuzIndexState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? juz = null,
  }) {
    return _then(JuzIndexReady(
      null == juz
          ? _self._juz
          : juz // ignore: cast_nullable_to_non_nullable
              as List<JuzSummary>,
    ));
  }
}

// dart format on

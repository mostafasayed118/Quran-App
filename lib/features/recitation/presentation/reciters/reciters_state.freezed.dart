// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reciters_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RecitersState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is RecitersState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'RecitersState()';
  }
}

/// @nodoc
class $RecitersStateCopyWith<$Res> {
  $RecitersStateCopyWith(RecitersState _, $Res Function(RecitersState) __);
}

/// Adds pattern-matching-related methods to [RecitersState].
extension RecitersStatePatterns on RecitersState {
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
    TResult Function(RecitersLoading value)? loading,
    TResult Function(RecitersReady value)? ready,
    TResult Function(RecitersError value)? error,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case RecitersLoading() when loading != null:
        return loading(_that);
      case RecitersReady() when ready != null:
        return ready(_that);
      case RecitersError() when error != null:
        return error(_that);
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
    required TResult Function(RecitersLoading value) loading,
    required TResult Function(RecitersReady value) ready,
    required TResult Function(RecitersError value) error,
  }) {
    final _that = this;
    switch (_that) {
      case RecitersLoading():
        return loading(_that);
      case RecitersReady():
        return ready(_that);
      case RecitersError():
        return error(_that);
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
    TResult? Function(RecitersLoading value)? loading,
    TResult? Function(RecitersReady value)? ready,
    TResult? Function(RecitersError value)? error,
  }) {
    final _that = this;
    switch (_that) {
      case RecitersLoading() when loading != null:
        return loading(_that);
      case RecitersReady() when ready != null:
        return ready(_that);
      case RecitersError() when error != null:
        return error(_that);
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
    TResult Function(List<ReciterRow> reciters, String query, bool dataError)?
        ready,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case RecitersLoading() when loading != null:
        return loading();
      case RecitersReady() when ready != null:
        return ready(_that.reciters, _that.query, _that.dataError);
      case RecitersError() when error != null:
        return error(_that.message);
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
    required TResult Function(
            List<ReciterRow> reciters, String query, bool dataError)
        ready,
    required TResult Function(String message) error,
  }) {
    final _that = this;
    switch (_that) {
      case RecitersLoading():
        return loading();
      case RecitersReady():
        return ready(_that.reciters, _that.query, _that.dataError);
      case RecitersError():
        return error(_that.message);
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
    TResult? Function(List<ReciterRow> reciters, String query, bool dataError)?
        ready,
    TResult? Function(String message)? error,
  }) {
    final _that = this;
    switch (_that) {
      case RecitersLoading() when loading != null:
        return loading();
      case RecitersReady() when ready != null:
        return ready(_that.reciters, _that.query, _that.dataError);
      case RecitersError() when error != null:
        return error(_that.message);
      case _:
        return null;
    }
  }
}

/// @nodoc

class RecitersLoading implements RecitersState {
  const RecitersLoading();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is RecitersLoading);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'RecitersState.loading()';
  }
}

/// @nodoc

class RecitersReady implements RecitersState {
  const RecitersReady(
      {List<ReciterRow> reciters = const <ReciterRow>[],
      this.query = '',
      this.dataError = false})
      : _reciters = reciters;

  final List<ReciterRow> _reciters;
  @JsonKey()
  List<ReciterRow> get reciters {
    if (_reciters is EqualUnmodifiableListView) return _reciters;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_reciters);
  }

  @JsonKey()
  final String query;
  @JsonKey()
  final bool dataError;

  /// Create a copy of RecitersState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RecitersReadyCopyWith<RecitersReady> get copyWith =>
      _$RecitersReadyCopyWithImpl<RecitersReady>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RecitersReady &&
            const DeepCollectionEquality().equals(other.reciters, _reciters) &&
            (identical(other.query, query) || other.query == query) &&
            (identical(other.dataError, dataError) ||
                other.dataError == dataError));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType,
        const DeepCollectionEquality().hash(_reciters), query, dataError);
  }

  @override
  String toString() {
    return 'RecitersState.ready(reciters: $reciters, query: $query, dataError: $dataError)';
  }
}

/// @nodoc
abstract mixin class $RecitersReadyCopyWith<$Res>
    implements $RecitersStateCopyWith<$Res> {
  factory $RecitersReadyCopyWith(
          RecitersReady value, $Res Function(RecitersReady) _then) =
      _$RecitersReadyCopyWithImpl;
  @useResult
  $Res call({List<ReciterRow> reciters, String query, bool dataError});
}

/// @nodoc
class _$RecitersReadyCopyWithImpl<$Res>
    implements $RecitersReadyCopyWith<$Res> {
  _$RecitersReadyCopyWithImpl(this._self, this._then);

  final RecitersReady _self;
  final $Res Function(RecitersReady) _then;

  /// Create a copy of RecitersState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? reciters = null,
    Object? query = null,
    Object? dataError = null,
  }) {
    return _then(RecitersReady(
      reciters: null == reciters
          ? _self._reciters
          : reciters // ignore: cast_nullable_to_non_nullable
              as List<ReciterRow>,
      query: null == query
          ? _self.query
          : query // ignore: cast_nullable_to_non_nullable
              as String,
      dataError: null == dataError
          ? _self.dataError
          : dataError // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class RecitersError implements RecitersState {
  const RecitersError({required this.message});

  final String message;

  /// Create a copy of RecitersState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RecitersErrorCopyWith<RecitersError> get copyWith =>
      _$RecitersErrorCopyWithImpl<RecitersError>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RecitersError &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, message);
  }

  @override
  String toString() {
    return 'RecitersState.error(message: $message)';
  }
}

/// @nodoc
abstract mixin class $RecitersErrorCopyWith<$Res>
    implements $RecitersStateCopyWith<$Res> {
  factory $RecitersErrorCopyWith(
          RecitersError value, $Res Function(RecitersError) _then) =
      _$RecitersErrorCopyWithImpl;
  @useResult
  $Res call({String message});
}

/// @nodoc
class _$RecitersErrorCopyWithImpl<$Res>
    implements $RecitersErrorCopyWith<$Res> {
  _$RecitersErrorCopyWithImpl(this._self, this._then);

  final RecitersError _self;
  final $Res Function(RecitersError) _then;

  /// Create a copy of RecitersState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? message = null,
  }) {
    return _then(RecitersError(
      message: null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on

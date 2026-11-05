// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'qada_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$QadaState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is QadaState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'QadaState()';
  }
}

/// @nodoc
class $QadaStateCopyWith<$Res> {
  $QadaStateCopyWith(QadaState _, $Res Function(QadaState) __);
}

/// Adds pattern-matching-related methods to [QadaState].
extension QadaStatePatterns on QadaState {
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
    TResult Function(QadaLoading value)? loading,
    TResult Function(QadaFailed value)? failed,
    TResult Function(QadaReady value)? ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case QadaLoading() when loading != null:
        return loading(_that);
      case QadaFailed() when failed != null:
        return failed(_that);
      case QadaReady() when ready != null:
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
    required TResult Function(QadaLoading value) loading,
    required TResult Function(QadaFailed value) failed,
    required TResult Function(QadaReady value) ready,
  }) {
    final _that = this;
    switch (_that) {
      case QadaLoading():
        return loading(_that);
      case QadaFailed():
        return failed(_that);
      case QadaReady():
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
    TResult? Function(QadaLoading value)? loading,
    TResult? Function(QadaFailed value)? failed,
    TResult? Function(QadaReady value)? ready,
  }) {
    final _that = this;
    switch (_that) {
      case QadaLoading() when loading != null:
        return loading(_that);
      case QadaFailed() when failed != null:
        return failed(_that);
      case QadaReady() when ready != null:
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
    TResult Function(List<DateTime> dates)? ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case QadaLoading() when loading != null:
        return loading();
      case QadaFailed() when failed != null:
        return failed();
      case QadaReady() when ready != null:
        return ready(_that.dates);
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
    required TResult Function(List<DateTime> dates) ready,
  }) {
    final _that = this;
    switch (_that) {
      case QadaLoading():
        return loading();
      case QadaFailed():
        return failed();
      case QadaReady():
        return ready(_that.dates);
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
    TResult? Function(List<DateTime> dates)? ready,
  }) {
    final _that = this;
    switch (_that) {
      case QadaLoading() when loading != null:
        return loading();
      case QadaFailed() when failed != null:
        return failed();
      case QadaReady() when ready != null:
        return ready(_that.dates);
      case _:
        return null;
    }
  }
}

/// @nodoc

class QadaLoading implements QadaState {
  const QadaLoading();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is QadaLoading);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'QadaState.loading()';
  }
}

/// @nodoc

class QadaFailed implements QadaState {
  const QadaFailed();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is QadaFailed);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'QadaState.failed()';
  }
}

/// @nodoc

class QadaReady implements QadaState {
  const QadaReady({List<DateTime> dates = const <DateTime>[]}) : _dates = dates;

  final List<DateTime> _dates;
  @JsonKey()
  List<DateTime> get dates {
    if (_dates is EqualUnmodifiableListView) return _dates;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_dates);
  }

  /// Create a copy of QadaState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $QadaReadyCopyWith<QadaReady> get copyWith =>
      _$QadaReadyCopyWithImpl<QadaReady>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is QadaReady &&
            const DeepCollectionEquality().equals(other.dates, _dates));
  }

  @override
  int get hashCode {
    return Object.hash(
        runtimeType, const DeepCollectionEquality().hash(_dates));
  }

  @override
  String toString() {
    return 'QadaState.ready(dates: $dates)';
  }
}

/// @nodoc
abstract mixin class $QadaReadyCopyWith<$Res>
    implements $QadaStateCopyWith<$Res> {
  factory $QadaReadyCopyWith(QadaReady value, $Res Function(QadaReady) _then) =
      _$QadaReadyCopyWithImpl;
  @useResult
  $Res call({List<DateTime> dates});
}

/// @nodoc
class _$QadaReadyCopyWithImpl<$Res> implements $QadaReadyCopyWith<$Res> {
  _$QadaReadyCopyWithImpl(this._self, this._then);

  final QadaReady _self;
  final $Res Function(QadaReady) _then;

  /// Create a copy of QadaState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? dates = null,
  }) {
    return _then(QadaReady(
      dates: null == dates
          ? _self._dates
          : dates // ignore: cast_nullable_to_non_nullable
              as List<DateTime>,
    ));
  }
}

// dart format on

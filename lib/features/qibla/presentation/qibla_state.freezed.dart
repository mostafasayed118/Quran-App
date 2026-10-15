// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'qibla_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$QiblaState {
  City? get city;
  double? get bearing;

  /// Create a copy of QiblaState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $QiblaStateCopyWith<QiblaState> get copyWith =>
      _$QiblaStateCopyWithImpl<QiblaState>(this as QiblaState, _$identity);

  @override
  bool operator ==(Object other) {
    final _this = this as QiblaState;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is QiblaState &&
            (identical(other.city, _this.city) || other.city == _this.city) &&
            (identical(other.bearing, _this.bearing) ||
                other.bearing == _this.bearing));
  }

  @override
  int get hashCode {
    final _this = this as QiblaState;
    return Object.hash(runtimeType, _this.city, _this.bearing);
  }

  @override
  String toString() {
    final _this = this as QiblaState;
    return 'QiblaState(city: ${_this.city}, bearing: ${_this.bearing})';
  }
}

/// @nodoc
abstract mixin class $QiblaStateCopyWith<$Res> {
  factory $QiblaStateCopyWith(
          QiblaState value, $Res Function(QiblaState) _then) =
      _$QiblaStateCopyWithImpl;
  @useResult
  $Res call({City? city, double? bearing});
}

/// @nodoc
class _$QiblaStateCopyWithImpl<$Res> implements $QiblaStateCopyWith<$Res> {
  _$QiblaStateCopyWithImpl(this._self, this._then);

  final QiblaState _self;
  final $Res Function(QiblaState) _then;

  /// Create a copy of QiblaState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? city = freezed,
    Object? bearing = freezed,
  }) {
    return _then(QiblaState.ready(
      city: freezed == city
          ? _self.city
          : city // ignore: cast_nullable_to_non_nullable
              as City?,
      bearing: freezed == bearing
          ? _self.bearing
          : bearing // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// Adds pattern-matching-related methods to [QiblaState].
extension QiblaStatePatterns on QiblaState {
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
    TResult Function(QiblaReady value)? ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case QiblaReady() when ready != null:
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
    required TResult Function(QiblaReady value) ready,
  }) {
    final _that = this;
    switch (_that) {
      case QiblaReady():
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
    TResult? Function(QiblaReady value)? ready,
  }) {
    final _that = this;
    switch (_that) {
      case QiblaReady() when ready != null:
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
    TResult Function(City? city, double? bearing)? ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case QiblaReady() when ready != null:
        return ready(_that.city, _that.bearing);
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
    required TResult Function(City? city, double? bearing) ready,
  }) {
    final _that = this;
    switch (_that) {
      case QiblaReady():
        return ready(_that.city, _that.bearing);
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
    TResult? Function(City? city, double? bearing)? ready,
  }) {
    final _that = this;
    switch (_that) {
      case QiblaReady() when ready != null:
        return ready(_that.city, _that.bearing);
      case _:
        return null;
    }
  }
}

/// @nodoc

class QiblaReady implements QiblaState {
  const QiblaReady({this.city = null, this.bearing = null});

  @override
  @JsonKey()
  final City? city;
  @override
  @JsonKey()
  final double? bearing;

  /// Create a copy of QiblaState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $QiblaReadyCopyWith<QiblaReady> get copyWith =>
      _$QiblaReadyCopyWithImpl<QiblaReady>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is QiblaReady &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.bearing, bearing) || other.bearing == bearing));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, city, bearing);
  }

  @override
  String toString() {
    return 'QiblaState.ready(city: $city, bearing: $bearing)';
  }
}

/// @nodoc
abstract mixin class $QiblaReadyCopyWith<$Res>
    implements $QiblaStateCopyWith<$Res> {
  factory $QiblaReadyCopyWith(
          QiblaReady value, $Res Function(QiblaReady) _then) =
      _$QiblaReadyCopyWithImpl;
  @override
  @useResult
  $Res call({City? city, double? bearing});
}

/// @nodoc
class _$QiblaReadyCopyWithImpl<$Res> implements $QiblaReadyCopyWith<$Res> {
  _$QiblaReadyCopyWithImpl(this._self, this._then);

  final QiblaReady _self;
  final $Res Function(QiblaReady) _then;

  /// Create a copy of QiblaState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? city = freezed,
    Object? bearing = freezed,
  }) {
    return _then(QiblaReady(
      city: freezed == city
          ? _self.city
          : city // ignore: cast_nullable_to_non_nullable
              as City?,
      bearing: freezed == bearing
          ? _self.bearing
          : bearing // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

// dart format on

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
  double? get heading;
  bool get compassUnavailable;

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
                other.bearing == _this.bearing) &&
            (identical(other.heading, _this.heading) ||
                other.heading == _this.heading) &&
            (identical(other.compassUnavailable, _this.compassUnavailable) ||
                other.compassUnavailable == _this.compassUnavailable));
  }

  @override
  int get hashCode {
    final _this = this as QiblaState;
    return Object.hash(runtimeType, _this.city, _this.bearing, _this.heading,
        _this.compassUnavailable);
  }

  @override
  String toString() {
    final _this = this as QiblaState;
    return 'QiblaState(city: ${_this.city}, bearing: ${_this.bearing}, heading: ${_this.heading}, compassUnavailable: ${_this.compassUnavailable})';
  }
}

/// @nodoc
abstract mixin class $QiblaStateCopyWith<$Res> {
  factory $QiblaStateCopyWith(
          QiblaState value, $Res Function(QiblaState) _then) =
      _$QiblaStateCopyWithImpl;
  @useResult
  $Res call(
      {City? city, double? bearing, double? heading, bool compassUnavailable});
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
    Object? heading = freezed,
    Object? compassUnavailable = null,
  }) {
    return _then(_self.copyWith(
      city: freezed == city
          ? _self.city
          : city // ignore: cast_nullable_to_non_nullable
              as City?,
      bearing: freezed == bearing
          ? _self.bearing
          : bearing // ignore: cast_nullable_to_non_nullable
              as double?,
      heading: freezed == heading
          ? _self.heading
          : heading // ignore: cast_nullable_to_non_nullable
              as double?,
      compassUnavailable: null == compassUnavailable
          ? _self.compassUnavailable
          : compassUnavailable // ignore: cast_nullable_to_non_nullable
              as bool,
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
    TResult Function(QiblaFailed value)? failed,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case QiblaReady() when ready != null:
        return ready(_that);
      case QiblaFailed() when failed != null:
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
    required TResult Function(QiblaReady value) ready,
    required TResult Function(QiblaFailed value) failed,
  }) {
    final _that = this;
    switch (_that) {
      case QiblaReady():
        return ready(_that);
      case QiblaFailed():
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
    TResult? Function(QiblaReady value)? ready,
    TResult? Function(QiblaFailed value)? failed,
  }) {
    final _that = this;
    switch (_that) {
      case QiblaReady() when ready != null:
        return ready(_that);
      case QiblaFailed() when failed != null:
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
    TResult Function(City? city, double? bearing, double? heading,
            bool compassUnavailable)?
        ready,
    TResult Function(City? city, double? bearing, double? heading,
            bool compassUnavailable)?
        failed,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case QiblaReady() when ready != null:
        return ready(
            _that.city, _that.bearing, _that.heading, _that.compassUnavailable);
      case QiblaFailed() when failed != null:
        return failed(
            _that.city, _that.bearing, _that.heading, _that.compassUnavailable);
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
    required TResult Function(City? city, double? bearing, double? heading,
            bool compassUnavailable)
        ready,
    required TResult Function(City? city, double? bearing, double? heading,
            bool compassUnavailable)
        failed,
  }) {
    final _that = this;
    switch (_that) {
      case QiblaReady():
        return ready(
            _that.city, _that.bearing, _that.heading, _that.compassUnavailable);
      case QiblaFailed():
        return failed(
            _that.city, _that.bearing, _that.heading, _that.compassUnavailable);
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
    TResult? Function(City? city, double? bearing, double? heading,
            bool compassUnavailable)?
        ready,
    TResult? Function(City? city, double? bearing, double? heading,
            bool compassUnavailable)?
        failed,
  }) {
    final _that = this;
    switch (_that) {
      case QiblaReady() when ready != null:
        return ready(
            _that.city, _that.bearing, _that.heading, _that.compassUnavailable);
      case QiblaFailed() when failed != null:
        return failed(
            _that.city, _that.bearing, _that.heading, _that.compassUnavailable);
      case _:
        return null;
    }
  }
}

/// @nodoc

class QiblaReady implements QiblaState {
  const QiblaReady(
      {this.city = null,
      this.bearing = null,
      this.heading = null,
      this.compassUnavailable = false});

  @override
  @JsonKey()
  final City? city;
  @override
  @JsonKey()
  final double? bearing;
  @override
  @JsonKey()
  final double? heading;
  @override
  @JsonKey()
  final bool compassUnavailable;

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
            (identical(other.bearing, bearing) || other.bearing == bearing) &&
            (identical(other.heading, heading) || other.heading == heading) &&
            (identical(other.compassUnavailable, compassUnavailable) ||
                other.compassUnavailable == compassUnavailable));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, city, bearing, heading, compassUnavailable);
  }

  @override
  String toString() {
    return 'QiblaState.ready(city: $city, bearing: $bearing, heading: $heading, compassUnavailable: $compassUnavailable)';
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
  $Res call(
      {City? city, double? bearing, double? heading, bool compassUnavailable});
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
    Object? heading = freezed,
    Object? compassUnavailable = null,
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
      heading: freezed == heading
          ? _self.heading
          : heading // ignore: cast_nullable_to_non_nullable
              as double?,
      compassUnavailable: null == compassUnavailable
          ? _self.compassUnavailable
          : compassUnavailable // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class QiblaFailed implements QiblaState {
  const QiblaFailed(
      {this.city = null,
      this.bearing = null,
      this.heading = null,
      this.compassUnavailable = false});

  @override
  @JsonKey()
  final City? city;
  @override
  @JsonKey()
  final double? bearing;
  @override
  @JsonKey()
  final double? heading;
  @override
  @JsonKey()
  final bool compassUnavailable;

  /// Create a copy of QiblaState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $QiblaFailedCopyWith<QiblaFailed> get copyWith =>
      _$QiblaFailedCopyWithImpl<QiblaFailed>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is QiblaFailed &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.bearing, bearing) || other.bearing == bearing) &&
            (identical(other.heading, heading) || other.heading == heading) &&
            (identical(other.compassUnavailable, compassUnavailable) ||
                other.compassUnavailable == compassUnavailable));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, city, bearing, heading, compassUnavailable);
  }

  @override
  String toString() {
    return 'QiblaState.failed(city: $city, bearing: $bearing, heading: $heading, compassUnavailable: $compassUnavailable)';
  }
}

/// @nodoc
abstract mixin class $QiblaFailedCopyWith<$Res>
    implements $QiblaStateCopyWith<$Res> {
  factory $QiblaFailedCopyWith(
          QiblaFailed value, $Res Function(QiblaFailed) _then) =
      _$QiblaFailedCopyWithImpl;
  @override
  @useResult
  $Res call(
      {City? city, double? bearing, double? heading, bool compassUnavailable});
}

/// @nodoc
class _$QiblaFailedCopyWithImpl<$Res> implements $QiblaFailedCopyWith<$Res> {
  _$QiblaFailedCopyWithImpl(this._self, this._then);

  final QiblaFailed _self;
  final $Res Function(QiblaFailed) _then;

  /// Create a copy of QiblaState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? city = freezed,
    Object? bearing = freezed,
    Object? heading = freezed,
    Object? compassUnavailable = null,
  }) {
    return _then(QiblaFailed(
      city: freezed == city
          ? _self.city
          : city // ignore: cast_nullable_to_non_nullable
              as City?,
      bearing: freezed == bearing
          ? _self.bearing
          : bearing // ignore: cast_nullable_to_non_nullable
              as double?,
      heading: freezed == heading
          ? _self.heading
          : heading // ignore: cast_nullable_to_non_nullable
              as double?,
      compassUnavailable: null == compassUnavailable
          ? _self.compassUnavailable
          : compassUnavailable // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on

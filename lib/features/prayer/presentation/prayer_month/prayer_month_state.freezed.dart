// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'prayer_month_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PrayerMonthState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is PrayerMonthState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'PrayerMonthState()';
  }
}

/// @nodoc
class $PrayerMonthStateCopyWith<$Res> {
  $PrayerMonthStateCopyWith(
      PrayerMonthState _, $Res Function(PrayerMonthState) __);
}

/// Adds pattern-matching-related methods to [PrayerMonthState].
extension PrayerMonthStatePatterns on PrayerMonthState {
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
    TResult Function(PrayerMonthLoading value)? loading,
    TResult Function(PrayerMonthFailed value)? failed,
    TResult Function(PrayerMonthReady value)? ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case PrayerMonthLoading() when loading != null:
        return loading(_that);
      case PrayerMonthFailed() when failed != null:
        return failed(_that);
      case PrayerMonthReady() when ready != null:
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
    required TResult Function(PrayerMonthLoading value) loading,
    required TResult Function(PrayerMonthFailed value) failed,
    required TResult Function(PrayerMonthReady value) ready,
  }) {
    final _that = this;
    switch (_that) {
      case PrayerMonthLoading():
        return loading(_that);
      case PrayerMonthFailed():
        return failed(_that);
      case PrayerMonthReady():
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
    TResult? Function(PrayerMonthLoading value)? loading,
    TResult? Function(PrayerMonthFailed value)? failed,
    TResult? Function(PrayerMonthReady value)? ready,
  }) {
    final _that = this;
    switch (_that) {
      case PrayerMonthLoading() when loading != null:
        return loading(_that);
      case PrayerMonthFailed() when failed != null:
        return failed(_that);
      case PrayerMonthReady() when ready != null:
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
    TResult Function(
            City? city, int year, int month, List<PrayerMonthDay> days)?
        ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case PrayerMonthLoading() when loading != null:
        return loading();
      case PrayerMonthFailed() when failed != null:
        return failed();
      case PrayerMonthReady() when ready != null:
        return ready(_that.city, _that.year, _that.month, _that.days);
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
    required TResult Function(
            City? city, int year, int month, List<PrayerMonthDay> days)
        ready,
  }) {
    final _that = this;
    switch (_that) {
      case PrayerMonthLoading():
        return loading();
      case PrayerMonthFailed():
        return failed();
      case PrayerMonthReady():
        return ready(_that.city, _that.year, _that.month, _that.days);
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
    TResult? Function(
            City? city, int year, int month, List<PrayerMonthDay> days)?
        ready,
  }) {
    final _that = this;
    switch (_that) {
      case PrayerMonthLoading() when loading != null:
        return loading();
      case PrayerMonthFailed() when failed != null:
        return failed();
      case PrayerMonthReady() when ready != null:
        return ready(_that.city, _that.year, _that.month, _that.days);
      case _:
        return null;
    }
  }
}

/// @nodoc

class PrayerMonthLoading implements PrayerMonthState {
  const PrayerMonthLoading();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is PrayerMonthLoading);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'PrayerMonthState.loading()';
  }
}

/// @nodoc

class PrayerMonthFailed implements PrayerMonthState {
  const PrayerMonthFailed();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is PrayerMonthFailed);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'PrayerMonthState.failed()';
  }
}

/// @nodoc

class PrayerMonthReady implements PrayerMonthState {
  const PrayerMonthReady(
      {this.city = null,
      required this.year,
      required this.month,
      List<PrayerMonthDay> days = const <PrayerMonthDay>[]})
      : _days = days;

  @JsonKey()
  final City? city;
  final int year;
  final int month;
  final List<PrayerMonthDay> _days;
  @JsonKey()
  List<PrayerMonthDay> get days {
    if (_days is EqualUnmodifiableListView) return _days;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_days);
  }

  /// Create a copy of PrayerMonthState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PrayerMonthReadyCopyWith<PrayerMonthReady> get copyWith =>
      _$PrayerMonthReadyCopyWithImpl<PrayerMonthReady>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PrayerMonthReady &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.month, month) || other.month == month) &&
            const DeepCollectionEquality().equals(other.days, _days));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, city, year, month,
        const DeepCollectionEquality().hash(_days));
  }

  @override
  String toString() {
    return 'PrayerMonthState.ready(city: $city, year: $year, month: $month, days: $days)';
  }
}

/// @nodoc
abstract mixin class $PrayerMonthReadyCopyWith<$Res>
    implements $PrayerMonthStateCopyWith<$Res> {
  factory $PrayerMonthReadyCopyWith(
          PrayerMonthReady value, $Res Function(PrayerMonthReady) _then) =
      _$PrayerMonthReadyCopyWithImpl;
  @useResult
  $Res call({City? city, int year, int month, List<PrayerMonthDay> days});
}

/// @nodoc
class _$PrayerMonthReadyCopyWithImpl<$Res>
    implements $PrayerMonthReadyCopyWith<$Res> {
  _$PrayerMonthReadyCopyWithImpl(this._self, this._then);

  final PrayerMonthReady _self;
  final $Res Function(PrayerMonthReady) _then;

  /// Create a copy of PrayerMonthState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? city = freezed,
    Object? year = null,
    Object? month = null,
    Object? days = null,
  }) {
    return _then(PrayerMonthReady(
      city: freezed == city
          ? _self.city
          : city // ignore: cast_nullable_to_non_nullable
              as City?,
      year: null == year
          ? _self.year
          : year // ignore: cast_nullable_to_non_nullable
              as int,
      month: null == month
          ? _self.month
          : month // ignore: cast_nullable_to_non_nullable
              as int,
      days: null == days
          ? _self._days
          : days // ignore: cast_nullable_to_non_nullable
              as List<PrayerMonthDay>,
    ));
  }
}

// dart format on

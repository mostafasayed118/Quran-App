// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ramadan_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RamadanState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is RamadanState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'RamadanState()';
  }
}

/// @nodoc
class $RamadanStateCopyWith<$Res> {
  $RamadanStateCopyWith(RamadanState _, $Res Function(RamadanState) __);
}

/// Adds pattern-matching-related methods to [RamadanState].
extension RamadanStatePatterns on RamadanState {
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
    TResult Function(RamadanLoading value)? loading,
    TResult Function(RamadanFailed value)? failed,
    TResult Function(RamadanReady value)? ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case RamadanLoading() when loading != null:
        return loading(_that);
      case RamadanFailed() when failed != null:
        return failed(_that);
      case RamadanReady() when ready != null:
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
    required TResult Function(RamadanLoading value) loading,
    required TResult Function(RamadanFailed value) failed,
    required TResult Function(RamadanReady value) ready,
  }) {
    final _that = this;
    switch (_that) {
      case RamadanLoading():
        return loading(_that);
      case RamadanFailed():
        return failed(_that);
      case RamadanReady():
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
    TResult? Function(RamadanLoading value)? loading,
    TResult? Function(RamadanFailed value)? failed,
    TResult? Function(RamadanReady value)? ready,
  }) {
    final _that = this;
    switch (_that) {
      case RamadanLoading() when loading != null:
        return loading(_that);
      case RamadanFailed() when failed != null:
        return failed(_that);
      case RamadanReady() when ready != null:
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
    TResult Function(int hijriYear, String monthName, List<RamadanDay> days,
            RamadanDay? today)?
        ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case RamadanLoading() when loading != null:
        return loading();
      case RamadanFailed() when failed != null:
        return failed();
      case RamadanReady() when ready != null:
        return ready(_that.hijriYear, _that.monthName, _that.days, _that.today);
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
    required TResult Function(int hijriYear, String monthName,
            List<RamadanDay> days, RamadanDay? today)
        ready,
  }) {
    final _that = this;
    switch (_that) {
      case RamadanLoading():
        return loading();
      case RamadanFailed():
        return failed();
      case RamadanReady():
        return ready(_that.hijriYear, _that.monthName, _that.days, _that.today);
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
    TResult? Function(int hijriYear, String monthName, List<RamadanDay> days,
            RamadanDay? today)?
        ready,
  }) {
    final _that = this;
    switch (_that) {
      case RamadanLoading() when loading != null:
        return loading();
      case RamadanFailed() when failed != null:
        return failed();
      case RamadanReady() when ready != null:
        return ready(_that.hijriYear, _that.monthName, _that.days, _that.today);
      case _:
        return null;
    }
  }
}

/// @nodoc

class RamadanLoading implements RamadanState {
  const RamadanLoading();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is RamadanLoading);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'RamadanState.loading()';
  }
}

/// @nodoc

class RamadanFailed implements RamadanState {
  const RamadanFailed();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is RamadanFailed);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'RamadanState.failed()';
  }
}

/// @nodoc

class RamadanReady implements RamadanState {
  const RamadanReady(
      {required this.hijriYear,
      required this.monthName,
      required List<RamadanDay> days,
      this.today = null})
      : _days = days;

  final int hijriYear;
  final String monthName;
  final List<RamadanDay> _days;
  List<RamadanDay> get days {
    if (_days is EqualUnmodifiableListView) return _days;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_days);
  }

  @JsonKey()
  final RamadanDay? today;

  /// Create a copy of RamadanState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RamadanReadyCopyWith<RamadanReady> get copyWith =>
      _$RamadanReadyCopyWithImpl<RamadanReady>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RamadanReady &&
            (identical(other.hijriYear, hijriYear) ||
                other.hijriYear == hijriYear) &&
            (identical(other.monthName, monthName) ||
                other.monthName == monthName) &&
            const DeepCollectionEquality().equals(other.days, _days) &&
            (identical(other.today, today) || other.today == today));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, hijriYear, monthName,
        const DeepCollectionEquality().hash(_days), today);
  }

  @override
  String toString() {
    return 'RamadanState.ready(hijriYear: $hijriYear, monthName: $monthName, days: $days, today: $today)';
  }
}

/// @nodoc
abstract mixin class $RamadanReadyCopyWith<$Res>
    implements $RamadanStateCopyWith<$Res> {
  factory $RamadanReadyCopyWith(
          RamadanReady value, $Res Function(RamadanReady) _then) =
      _$RamadanReadyCopyWithImpl;
  @useResult
  $Res call(
      {int hijriYear,
      String monthName,
      List<RamadanDay> days,
      RamadanDay? today});
}

/// @nodoc
class _$RamadanReadyCopyWithImpl<$Res> implements $RamadanReadyCopyWith<$Res> {
  _$RamadanReadyCopyWithImpl(this._self, this._then);

  final RamadanReady _self;
  final $Res Function(RamadanReady) _then;

  /// Create a copy of RamadanState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? hijriYear = null,
    Object? monthName = null,
    Object? days = null,
    Object? today = freezed,
  }) {
    return _then(RamadanReady(
      hijriYear: null == hijriYear
          ? _self.hijriYear
          : hijriYear // ignore: cast_nullable_to_non_nullable
              as int,
      monthName: null == monthName
          ? _self.monthName
          : monthName // ignore: cast_nullable_to_non_nullable
              as String,
      days: null == days
          ? _self._days
          : days // ignore: cast_nullable_to_non_nullable
              as List<RamadanDay>,
      today: freezed == today
          ? _self.today
          : today // ignore: cast_nullable_to_non_nullable
              as RamadanDay?,
    ));
  }
}

// dart format on

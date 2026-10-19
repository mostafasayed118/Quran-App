// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tracker_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TrackerState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is TrackerState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'TrackerState()';
  }
}

/// @nodoc
class $TrackerStateCopyWith<$Res> {
  $TrackerStateCopyWith(TrackerState _, $Res Function(TrackerState) __);
}

/// Adds pattern-matching-related methods to [TrackerState].
extension TrackerStatePatterns on TrackerState {
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
    TResult Function(TrackerLoading value)? loading,
    TResult Function(TrackerFailed value)? failed,
    TResult Function(TrackerReady value)? ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case TrackerLoading() when loading != null:
        return loading(_that);
      case TrackerFailed() when failed != null:
        return failed(_that);
      case TrackerReady() when ready != null:
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
    required TResult Function(TrackerLoading value) loading,
    required TResult Function(TrackerFailed value) failed,
    required TResult Function(TrackerReady value) ready,
  }) {
    final _that = this;
    switch (_that) {
      case TrackerLoading():
        return loading(_that);
      case TrackerFailed():
        return failed(_that);
      case TrackerReady():
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
    TResult? Function(TrackerLoading value)? loading,
    TResult? Function(TrackerFailed value)? failed,
    TResult? Function(TrackerReady value)? ready,
  }) {
    final _that = this;
    switch (_that) {
      case TrackerLoading() when loading != null:
        return loading(_that);
      case TrackerFailed() when failed != null:
        return failed(_that);
      case TrackerReady() when ready != null:
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
    TResult Function(TrackerDay today, int streakDays, List<bool> last7,
            bool khatmaAvailable, KhatmaProgress? khatma)?
        ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case TrackerLoading() when loading != null:
        return loading();
      case TrackerFailed() when failed != null:
        return failed();
      case TrackerReady() when ready != null:
        return ready(_that.today, _that.streakDays, _that.last7,
            _that.khatmaAvailable, _that.khatma);
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
    required TResult Function(TrackerDay today, int streakDays,
            List<bool> last7, bool khatmaAvailable, KhatmaProgress? khatma)
        ready,
  }) {
    final _that = this;
    switch (_that) {
      case TrackerLoading():
        return loading();
      case TrackerFailed():
        return failed();
      case TrackerReady():
        return ready(_that.today, _that.streakDays, _that.last7,
            _that.khatmaAvailable, _that.khatma);
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
    TResult? Function(TrackerDay today, int streakDays, List<bool> last7,
            bool khatmaAvailable, KhatmaProgress? khatma)?
        ready,
  }) {
    final _that = this;
    switch (_that) {
      case TrackerLoading() when loading != null:
        return loading();
      case TrackerFailed() when failed != null:
        return failed();
      case TrackerReady() when ready != null:
        return ready(_that.today, _that.streakDays, _that.last7,
            _that.khatmaAvailable, _that.khatma);
      case _:
        return null;
    }
  }
}

/// @nodoc

class TrackerLoading implements TrackerState {
  const TrackerLoading();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is TrackerLoading);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'TrackerState.loading()';
  }
}

/// @nodoc

class TrackerFailed implements TrackerState {
  const TrackerFailed();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is TrackerFailed);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'TrackerState.failed()';
  }
}

/// @nodoc

class TrackerReady implements TrackerState {
  const TrackerReady(
      {required this.today,
      this.streakDays = 0,
      List<bool> last7 = const <bool>[],
      this.khatmaAvailable = false,
      this.khatma = null})
      : _last7 = last7;

  final TrackerDay today;
  @JsonKey()
  final int streakDays;
  final List<bool> _last7;
  @JsonKey()
  List<bool> get last7 {
    if (_last7 is EqualUnmodifiableListView) return _last7;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_last7);
  }

  @JsonKey()
  final bool khatmaAvailable;
  @JsonKey()
  final KhatmaProgress? khatma;

  /// Create a copy of TrackerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TrackerReadyCopyWith<TrackerReady> get copyWith =>
      _$TrackerReadyCopyWithImpl<TrackerReady>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TrackerReady &&
            (identical(other.today, today) || other.today == today) &&
            (identical(other.streakDays, streakDays) ||
                other.streakDays == streakDays) &&
            const DeepCollectionEquality().equals(other.last7, _last7) &&
            (identical(other.khatmaAvailable, khatmaAvailable) ||
                other.khatmaAvailable == khatmaAvailable) &&
            (identical(other.khatma, khatma) || other.khatma == khatma));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, today, streakDays,
        const DeepCollectionEquality().hash(_last7), khatmaAvailable, khatma);
  }

  @override
  String toString() {
    return 'TrackerState.ready(today: $today, streakDays: $streakDays, last7: $last7, khatmaAvailable: $khatmaAvailable, khatma: $khatma)';
  }
}

/// @nodoc
abstract mixin class $TrackerReadyCopyWith<$Res>
    implements $TrackerStateCopyWith<$Res> {
  factory $TrackerReadyCopyWith(
          TrackerReady value, $Res Function(TrackerReady) _then) =
      _$TrackerReadyCopyWithImpl;
  @useResult
  $Res call(
      {TrackerDay today,
      int streakDays,
      List<bool> last7,
      bool khatmaAvailable,
      KhatmaProgress? khatma});
}

/// @nodoc
class _$TrackerReadyCopyWithImpl<$Res> implements $TrackerReadyCopyWith<$Res> {
  _$TrackerReadyCopyWithImpl(this._self, this._then);

  final TrackerReady _self;
  final $Res Function(TrackerReady) _then;

  /// Create a copy of TrackerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? today = null,
    Object? streakDays = null,
    Object? last7 = null,
    Object? khatmaAvailable = null,
    Object? khatma = freezed,
  }) {
    return _then(TrackerReady(
      today: null == today
          ? _self.today
          : today // ignore: cast_nullable_to_non_nullable
              as TrackerDay,
      streakDays: null == streakDays
          ? _self.streakDays
          : streakDays // ignore: cast_nullable_to_non_nullable
              as int,
      last7: null == last7
          ? _self._last7
          : last7 // ignore: cast_nullable_to_non_nullable
              as List<bool>,
      khatmaAvailable: null == khatmaAvailable
          ? _self.khatmaAvailable
          : khatmaAvailable // ignore: cast_nullable_to_non_nullable
              as bool,
      khatma: freezed == khatma
          ? _self.khatma
          : khatma // ignore: cast_nullable_to_non_nullable
              as KhatmaProgress?,
    ));
  }
}

// dart format on

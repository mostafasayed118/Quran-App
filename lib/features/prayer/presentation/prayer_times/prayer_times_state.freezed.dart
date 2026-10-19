// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'prayer_times_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PrayerTimesState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is PrayerTimesState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'PrayerTimesState()';
  }
}

/// @nodoc
class $PrayerTimesStateCopyWith<$Res> {
  $PrayerTimesStateCopyWith(
      PrayerTimesState _, $Res Function(PrayerTimesState) __);
}

/// Adds pattern-matching-related methods to [PrayerTimesState].
extension PrayerTimesStatePatterns on PrayerTimesState {
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
    TResult Function(PrayerTimesLoading value)? loading,
    TResult Function(PrayerTimesFailed value)? failed,
    TResult Function(PrayerTimesReady value)? ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case PrayerTimesLoading() when loading != null:
        return loading(_that);
      case PrayerTimesFailed() when failed != null:
        return failed(_that);
      case PrayerTimesReady() when ready != null:
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
    required TResult Function(PrayerTimesLoading value) loading,
    required TResult Function(PrayerTimesFailed value) failed,
    required TResult Function(PrayerTimesReady value) ready,
  }) {
    final _that = this;
    switch (_that) {
      case PrayerTimesLoading():
        return loading(_that);
      case PrayerTimesFailed():
        return failed(_that);
      case PrayerTimesReady():
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
    TResult? Function(PrayerTimesLoading value)? loading,
    TResult? Function(PrayerTimesFailed value)? failed,
    TResult? Function(PrayerTimesReady value)? ready,
  }) {
    final _that = this;
    switch (_that) {
      case PrayerTimesLoading() when loading != null:
        return loading(_that);
      case PrayerTimesFailed() when failed != null:
        return failed(_that);
      case PrayerTimesReady() when ready != null:
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
            City? city, List<PrayerEntry> entries, Duration? remaining)?
        ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case PrayerTimesLoading() when loading != null:
        return loading();
      case PrayerTimesFailed() when failed != null:
        return failed();
      case PrayerTimesReady() when ready != null:
        return ready(_that.city, _that.entries, _that.remaining);
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
            City? city, List<PrayerEntry> entries, Duration? remaining)
        ready,
  }) {
    final _that = this;
    switch (_that) {
      case PrayerTimesLoading():
        return loading();
      case PrayerTimesFailed():
        return failed();
      case PrayerTimesReady():
        return ready(_that.city, _that.entries, _that.remaining);
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
            City? city, List<PrayerEntry> entries, Duration? remaining)?
        ready,
  }) {
    final _that = this;
    switch (_that) {
      case PrayerTimesLoading() when loading != null:
        return loading();
      case PrayerTimesFailed() when failed != null:
        return failed();
      case PrayerTimesReady() when ready != null:
        return ready(_that.city, _that.entries, _that.remaining);
      case _:
        return null;
    }
  }
}

/// @nodoc

class PrayerTimesLoading implements PrayerTimesState {
  const PrayerTimesLoading();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is PrayerTimesLoading);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'PrayerTimesState.loading()';
  }
}

/// @nodoc

class PrayerTimesFailed implements PrayerTimesState {
  const PrayerTimesFailed();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is PrayerTimesFailed);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'PrayerTimesState.failed()';
  }
}

/// @nodoc

class PrayerTimesReady implements PrayerTimesState {
  const PrayerTimesReady(
      {this.city,
      List<PrayerEntry> entries = const <PrayerEntry>[],
      this.remaining = null})
      : _entries = entries;

  final City? city;
  final List<PrayerEntry> _entries;
  @JsonKey()
  List<PrayerEntry> get entries {
    if (_entries is EqualUnmodifiableListView) return _entries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_entries);
  }

  @JsonKey()
  final Duration? remaining;

  /// Create a copy of PrayerTimesState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PrayerTimesReadyCopyWith<PrayerTimesReady> get copyWith =>
      _$PrayerTimesReadyCopyWithImpl<PrayerTimesReady>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PrayerTimesReady &&
            (identical(other.city, city) || other.city == city) &&
            const DeepCollectionEquality().equals(other.entries, _entries) &&
            (identical(other.remaining, remaining) ||
                other.remaining == remaining));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, city,
        const DeepCollectionEquality().hash(_entries), remaining);
  }

  @override
  String toString() {
    return 'PrayerTimesState.ready(city: $city, entries: $entries, remaining: $remaining)';
  }
}

/// @nodoc
abstract mixin class $PrayerTimesReadyCopyWith<$Res>
    implements $PrayerTimesStateCopyWith<$Res> {
  factory $PrayerTimesReadyCopyWith(
          PrayerTimesReady value, $Res Function(PrayerTimesReady) _then) =
      _$PrayerTimesReadyCopyWithImpl;
  @useResult
  $Res call({City? city, List<PrayerEntry> entries, Duration? remaining});
}

/// @nodoc
class _$PrayerTimesReadyCopyWithImpl<$Res>
    implements $PrayerTimesReadyCopyWith<$Res> {
  _$PrayerTimesReadyCopyWithImpl(this._self, this._then);

  final PrayerTimesReady _self;
  final $Res Function(PrayerTimesReady) _then;

  /// Create a copy of PrayerTimesState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? city = freezed,
    Object? entries = null,
    Object? remaining = freezed,
  }) {
    return _then(PrayerTimesReady(
      city: freezed == city
          ? _self.city
          : city // ignore: cast_nullable_to_non_nullable
              as City?,
      entries: null == entries
          ? _self._entries
          : entries // ignore: cast_nullable_to_non_nullable
              as List<PrayerEntry>,
      remaining: freezed == remaining
          ? _self.remaining
          : remaining // ignore: cast_nullable_to_non_nullable
              as Duration?,
    ));
  }
}

// dart format on

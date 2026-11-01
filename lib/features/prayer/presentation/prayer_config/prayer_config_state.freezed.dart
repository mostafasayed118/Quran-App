// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'prayer_config_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PrayerConfigState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is PrayerConfigState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'PrayerConfigState()';
  }
}

/// @nodoc
class $PrayerConfigStateCopyWith<$Res> {
  $PrayerConfigStateCopyWith(
      PrayerConfigState _, $Res Function(PrayerConfigState) __);
}

/// Adds pattern-matching-related methods to [PrayerConfigState].
extension PrayerConfigStatePatterns on PrayerConfigState {
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
    TResult Function(PrayerConfigLoading value)? loading,
    TResult Function(PrayerConfigFailed value)? failed,
    TResult Function(PrayerConfigReady value)? ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case PrayerConfigLoading() when loading != null:
        return loading(_that);
      case PrayerConfigFailed() when failed != null:
        return failed(_that);
      case PrayerConfigReady() when ready != null:
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
    required TResult Function(PrayerConfigLoading value) loading,
    required TResult Function(PrayerConfigFailed value) failed,
    required TResult Function(PrayerConfigReady value) ready,
  }) {
    final _that = this;
    switch (_that) {
      case PrayerConfigLoading():
        return loading(_that);
      case PrayerConfigFailed():
        return failed(_that);
      case PrayerConfigReady():
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
    TResult? Function(PrayerConfigLoading value)? loading,
    TResult? Function(PrayerConfigFailed value)? failed,
    TResult? Function(PrayerConfigReady value)? ready,
  }) {
    final _that = this;
    switch (_that) {
      case PrayerConfigLoading() when loading != null:
        return loading(_that);
      case PrayerConfigFailed() when failed != null:
        return failed(_that);
      case PrayerConfigReady() when ready != null:
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
    TResult Function(PrayerConfig config)? ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case PrayerConfigLoading() when loading != null:
        return loading();
      case PrayerConfigFailed() when failed != null:
        return failed();
      case PrayerConfigReady() when ready != null:
        return ready(_that.config);
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
    required TResult Function(PrayerConfig config) ready,
  }) {
    final _that = this;
    switch (_that) {
      case PrayerConfigLoading():
        return loading();
      case PrayerConfigFailed():
        return failed();
      case PrayerConfigReady():
        return ready(_that.config);
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
    TResult? Function(PrayerConfig config)? ready,
  }) {
    final _that = this;
    switch (_that) {
      case PrayerConfigLoading() when loading != null:
        return loading();
      case PrayerConfigFailed() when failed != null:
        return failed();
      case PrayerConfigReady() when ready != null:
        return ready(_that.config);
      case _:
        return null;
    }
  }
}

/// @nodoc

class PrayerConfigLoading implements PrayerConfigState {
  const PrayerConfigLoading();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is PrayerConfigLoading);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'PrayerConfigState.loading()';
  }
}

/// @nodoc

class PrayerConfigFailed implements PrayerConfigState {
  const PrayerConfigFailed();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is PrayerConfigFailed);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'PrayerConfigState.failed()';
  }
}

/// @nodoc

class PrayerConfigReady implements PrayerConfigState {
  const PrayerConfigReady(this.config);

  final PrayerConfig config;

  /// Create a copy of PrayerConfigState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PrayerConfigReadyCopyWith<PrayerConfigReady> get copyWith =>
      _$PrayerConfigReadyCopyWithImpl<PrayerConfigReady>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PrayerConfigReady &&
            const DeepCollectionEquality().equals(other.config, config));
  }

  @override
  int get hashCode {
    return Object.hash(
        runtimeType, const DeepCollectionEquality().hash(config));
  }

  @override
  String toString() {
    return 'PrayerConfigState.ready(config: $config)';
  }
}

/// @nodoc
abstract mixin class $PrayerConfigReadyCopyWith<$Res>
    implements $PrayerConfigStateCopyWith<$Res> {
  factory $PrayerConfigReadyCopyWith(
          PrayerConfigReady value, $Res Function(PrayerConfigReady) _then) =
      _$PrayerConfigReadyCopyWithImpl;
  @useResult
  $Res call({PrayerConfig config});
}

/// @nodoc
class _$PrayerConfigReadyCopyWithImpl<$Res>
    implements $PrayerConfigReadyCopyWith<$Res> {
  _$PrayerConfigReadyCopyWithImpl(this._self, this._then);

  final PrayerConfigReady _self;
  final $Res Function(PrayerConfigReady) _then;

  /// Create a copy of PrayerConfigState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? config = freezed,
  }) {
    return _then(PrayerConfigReady(
      freezed == config
          ? _self.config
          : config // ignore: cast_nullable_to_non_nullable
              as PrayerConfig,
    ));
  }
}

// dart format on

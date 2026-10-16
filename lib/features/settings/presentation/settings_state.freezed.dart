// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SettingsState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is SettingsState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'SettingsState()';
  }
}

/// @nodoc
class $SettingsStateCopyWith<$Res> {
  $SettingsStateCopyWith(SettingsState _, $Res Function(SettingsState) __);
}

/// Adds pattern-matching-related methods to [SettingsState].
extension SettingsStatePatterns on SettingsState {
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
    TResult Function(SettingsLoading value)? loading,
    TResult Function(SettingsReady value)? ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case SettingsLoading() when loading != null:
        return loading(_that);
      case SettingsReady() when ready != null:
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
    required TResult Function(SettingsLoading value) loading,
    required TResult Function(SettingsReady value) ready,
  }) {
    final _that = this;
    switch (_that) {
      case SettingsLoading():
        return loading(_that);
      case SettingsReady():
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
    TResult? Function(SettingsLoading value)? loading,
    TResult? Function(SettingsReady value)? ready,
  }) {
    final _that = this;
    switch (_that) {
      case SettingsLoading() when loading != null:
        return loading(_that);
      case SettingsReady() when ready != null:
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
    TResult Function(
            bool azkarEnabled, String azkarTimeHm, bool permissionDenied)?
        ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case SettingsLoading() when loading != null:
        return loading();
      case SettingsReady() when ready != null:
        return ready(
            _that.azkarEnabled, _that.azkarTimeHm, _that.permissionDenied);
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
            bool azkarEnabled, String azkarTimeHm, bool permissionDenied)
        ready,
  }) {
    final _that = this;
    switch (_that) {
      case SettingsLoading():
        return loading();
      case SettingsReady():
        return ready(
            _that.azkarEnabled, _that.azkarTimeHm, _that.permissionDenied);
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
    TResult? Function(
            bool azkarEnabled, String azkarTimeHm, bool permissionDenied)?
        ready,
  }) {
    final _that = this;
    switch (_that) {
      case SettingsLoading() when loading != null:
        return loading();
      case SettingsReady() when ready != null:
        return ready(
            _that.azkarEnabled, _that.azkarTimeHm, _that.permissionDenied);
      case _:
        return null;
    }
  }
}

/// @nodoc

class SettingsLoading implements SettingsState {
  const SettingsLoading();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is SettingsLoading);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'SettingsState.loading()';
  }
}

/// @nodoc

class SettingsReady implements SettingsState {
  const SettingsReady(
      {this.azkarEnabled = false,
      this.azkarTimeHm = defaultAzkarTimeHm,
      this.permissionDenied = false});

  @JsonKey()
  final bool azkarEnabled;
  @JsonKey()
  final String azkarTimeHm;
  @JsonKey()
  final bool permissionDenied;

  /// Create a copy of SettingsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SettingsReadyCopyWith<SettingsReady> get copyWith =>
      _$SettingsReadyCopyWithImpl<SettingsReady>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SettingsReady &&
            (identical(other.azkarEnabled, azkarEnabled) ||
                other.azkarEnabled == azkarEnabled) &&
            (identical(other.azkarTimeHm, azkarTimeHm) ||
                other.azkarTimeHm == azkarTimeHm) &&
            (identical(other.permissionDenied, permissionDenied) ||
                other.permissionDenied == permissionDenied));
  }

  @override
  int get hashCode {
    return Object.hash(
        runtimeType, azkarEnabled, azkarTimeHm, permissionDenied);
  }

  @override
  String toString() {
    return 'SettingsState.ready(azkarEnabled: $azkarEnabled, azkarTimeHm: $azkarTimeHm, permissionDenied: $permissionDenied)';
  }
}

/// @nodoc
abstract mixin class $SettingsReadyCopyWith<$Res>
    implements $SettingsStateCopyWith<$Res> {
  factory $SettingsReadyCopyWith(
          SettingsReady value, $Res Function(SettingsReady) _then) =
      _$SettingsReadyCopyWithImpl;
  @useResult
  $Res call({bool azkarEnabled, String azkarTimeHm, bool permissionDenied});
}

/// @nodoc
class _$SettingsReadyCopyWithImpl<$Res>
    implements $SettingsReadyCopyWith<$Res> {
  _$SettingsReadyCopyWithImpl(this._self, this._then);

  final SettingsReady _self;
  final $Res Function(SettingsReady) _then;

  /// Create a copy of SettingsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? azkarEnabled = null,
    Object? azkarTimeHm = null,
    Object? permissionDenied = null,
  }) {
    return _then(SettingsReady(
      azkarEnabled: null == azkarEnabled
          ? _self.azkarEnabled
          : azkarEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      azkarTimeHm: null == azkarTimeHm
          ? _self.azkarTimeHm
          : azkarTimeHm // ignore: cast_nullable_to_non_nullable
              as String,
      permissionDenied: null == permissionDenied
          ? _self.permissionDenied
          : permissionDenied // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on

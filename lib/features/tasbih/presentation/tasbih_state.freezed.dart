// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tasbih_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TasbihState {
  int get count;
  int get target;
  bool get reachedTarget;

  /// Create a copy of TasbihState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TasbihStateCopyWith<TasbihState> get copyWith =>
      _$TasbihStateCopyWithImpl<TasbihState>(this as TasbihState, _$identity);

  @override
  bool operator ==(Object other) {
    final _this = this as TasbihState;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TasbihState &&
            (identical(other.count, _this.count) ||
                other.count == _this.count) &&
            (identical(other.target, _this.target) ||
                other.target == _this.target) &&
            (identical(other.reachedTarget, _this.reachedTarget) ||
                other.reachedTarget == _this.reachedTarget));
  }

  @override
  int get hashCode {
    final _this = this as TasbihState;
    return Object.hash(
        runtimeType, _this.count, _this.target, _this.reachedTarget);
  }

  @override
  String toString() {
    final _this = this as TasbihState;
    return 'TasbihState(count: ${_this.count}, target: ${_this.target}, reachedTarget: ${_this.reachedTarget})';
  }
}

/// @nodoc
abstract mixin class $TasbihStateCopyWith<$Res> {
  factory $TasbihStateCopyWith(
          TasbihState value, $Res Function(TasbihState) _then) =
      _$TasbihStateCopyWithImpl;
  @useResult
  $Res call({int count, int target, bool reachedTarget});
}

/// @nodoc
class _$TasbihStateCopyWithImpl<$Res> implements $TasbihStateCopyWith<$Res> {
  _$TasbihStateCopyWithImpl(this._self, this._then);

  final TasbihState _self;
  final $Res Function(TasbihState) _then;

  /// Create a copy of TasbihState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? count = null,
    Object? target = null,
    Object? reachedTarget = null,
  }) {
    return _then(TasbihState.ready(
      count: null == count
          ? _self.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
      target: null == target
          ? _self.target
          : target // ignore: cast_nullable_to_non_nullable
              as int,
      reachedTarget: null == reachedTarget
          ? _self.reachedTarget
          : reachedTarget // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [TasbihState].
extension TasbihStatePatterns on TasbihState {
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
    TResult Function(TasbihReady value)? ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case TasbihReady() when ready != null:
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
    required TResult Function(TasbihReady value) ready,
  }) {
    final _that = this;
    switch (_that) {
      case TasbihReady():
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
    TResult? Function(TasbihReady value)? ready,
  }) {
    final _that = this;
    switch (_that) {
      case TasbihReady() when ready != null:
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
    TResult Function(int count, int target, bool reachedTarget)? ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case TasbihReady() when ready != null:
        return ready(_that.count, _that.target, _that.reachedTarget);
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
    required TResult Function(int count, int target, bool reachedTarget) ready,
  }) {
    final _that = this;
    switch (_that) {
      case TasbihReady():
        return ready(_that.count, _that.target, _that.reachedTarget);
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
    TResult? Function(int count, int target, bool reachedTarget)? ready,
  }) {
    final _that = this;
    switch (_that) {
      case TasbihReady() when ready != null:
        return ready(_that.count, _that.target, _that.reachedTarget);
      case _:
        return null;
    }
  }
}

/// @nodoc

class TasbihReady implements TasbihState {
  const TasbihReady(
      {this.count = 0, this.target = 33, this.reachedTarget = false});

  @override
  @JsonKey()
  final int count;
  @override
  @JsonKey()
  final int target;
  @override
  @JsonKey()
  final bool reachedTarget;

  /// Create a copy of TasbihState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TasbihReadyCopyWith<TasbihReady> get copyWith =>
      _$TasbihReadyCopyWithImpl<TasbihReady>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TasbihReady &&
            (identical(other.count, count) || other.count == count) &&
            (identical(other.target, target) || other.target == target) &&
            (identical(other.reachedTarget, reachedTarget) ||
                other.reachedTarget == reachedTarget));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, count, target, reachedTarget);
  }

  @override
  String toString() {
    return 'TasbihState.ready(count: $count, target: $target, reachedTarget: $reachedTarget)';
  }
}

/// @nodoc
abstract mixin class $TasbihReadyCopyWith<$Res>
    implements $TasbihStateCopyWith<$Res> {
  factory $TasbihReadyCopyWith(
          TasbihReady value, $Res Function(TasbihReady) _then) =
      _$TasbihReadyCopyWithImpl;
  @override
  @useResult
  $Res call({int count, int target, bool reachedTarget});
}

/// @nodoc
class _$TasbihReadyCopyWithImpl<$Res> implements $TasbihReadyCopyWith<$Res> {
  _$TasbihReadyCopyWithImpl(this._self, this._then);

  final TasbihReady _self;
  final $Res Function(TasbihReady) _then;

  /// Create a copy of TasbihState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? count = null,
    Object? target = null,
    Object? reachedTarget = null,
  }) {
    return _then(TasbihReady(
      count: null == count
          ? _self.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
      target: null == target
          ? _self.target
          : target // ignore: cast_nullable_to_non_nullable
              as int,
      reachedTarget: null == reachedTarget
          ? _self.reachedTarget
          : reachedTarget // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on

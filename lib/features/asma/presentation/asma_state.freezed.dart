// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'asma_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AsmaState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is AsmaState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'AsmaState()';
  }
}

/// @nodoc
class $AsmaStateCopyWith<$Res> {
  $AsmaStateCopyWith(AsmaState _, $Res Function(AsmaState) __);
}

/// Adds pattern-matching-related methods to [AsmaState].
extension AsmaStatePatterns on AsmaState {
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
    TResult Function(AsmaLoading value)? loading,
    TResult Function(AsmaFailed value)? failed,
    TResult Function(AsmaReady value)? ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case AsmaLoading() when loading != null:
        return loading(_that);
      case AsmaFailed() when failed != null:
        return failed(_that);
      case AsmaReady() when ready != null:
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
    required TResult Function(AsmaLoading value) loading,
    required TResult Function(AsmaFailed value) failed,
    required TResult Function(AsmaReady value) ready,
  }) {
    final _that = this;
    switch (_that) {
      case AsmaLoading():
        return loading(_that);
      case AsmaFailed():
        return failed(_that);
      case AsmaReady():
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
    TResult? Function(AsmaLoading value)? loading,
    TResult? Function(AsmaFailed value)? failed,
    TResult? Function(AsmaReady value)? ready,
  }) {
    final _that = this;
    switch (_that) {
      case AsmaLoading() when loading != null:
        return loading(_that);
      case AsmaFailed() when failed != null:
        return failed(_that);
      case AsmaReady() when ready != null:
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
    TResult Function(List<AsmaName> names, AsmaName? selected)? ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case AsmaLoading() when loading != null:
        return loading();
      case AsmaFailed() when failed != null:
        return failed();
      case AsmaReady() when ready != null:
        return ready(_that.names, _that.selected);
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
    required TResult Function(List<AsmaName> names, AsmaName? selected) ready,
  }) {
    final _that = this;
    switch (_that) {
      case AsmaLoading():
        return loading();
      case AsmaFailed():
        return failed();
      case AsmaReady():
        return ready(_that.names, _that.selected);
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
    TResult? Function(List<AsmaName> names, AsmaName? selected)? ready,
  }) {
    final _that = this;
    switch (_that) {
      case AsmaLoading() when loading != null:
        return loading();
      case AsmaFailed() when failed != null:
        return failed();
      case AsmaReady() when ready != null:
        return ready(_that.names, _that.selected);
      case _:
        return null;
    }
  }
}

/// @nodoc

class AsmaLoading implements AsmaState {
  const AsmaLoading();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is AsmaLoading);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'AsmaState.loading()';
  }
}

/// @nodoc

class AsmaFailed implements AsmaState {
  const AsmaFailed();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is AsmaFailed);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'AsmaState.failed()';
  }
}

/// @nodoc

class AsmaReady implements AsmaState {
  const AsmaReady(
      {List<AsmaName> names = const <AsmaName>[], this.selected = null})
      : _names = names;

  final List<AsmaName> _names;
  @JsonKey()
  List<AsmaName> get names {
    if (_names is EqualUnmodifiableListView) return _names;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_names);
  }

  @JsonKey()
  final AsmaName? selected;

  /// Create a copy of AsmaState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AsmaReadyCopyWith<AsmaReady> get copyWith =>
      _$AsmaReadyCopyWithImpl<AsmaReady>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AsmaReady &&
            const DeepCollectionEquality().equals(other.names, _names) &&
            (identical(other.selected, selected) ||
                other.selected == selected));
  }

  @override
  int get hashCode {
    return Object.hash(
        runtimeType, const DeepCollectionEquality().hash(_names), selected);
  }

  @override
  String toString() {
    return 'AsmaState.ready(names: $names, selected: $selected)';
  }
}

/// @nodoc
abstract mixin class $AsmaReadyCopyWith<$Res>
    implements $AsmaStateCopyWith<$Res> {
  factory $AsmaReadyCopyWith(AsmaReady value, $Res Function(AsmaReady) _then) =
      _$AsmaReadyCopyWithImpl;
  @useResult
  $Res call({List<AsmaName> names, AsmaName? selected});
}

/// @nodoc
class _$AsmaReadyCopyWithImpl<$Res> implements $AsmaReadyCopyWith<$Res> {
  _$AsmaReadyCopyWithImpl(this._self, this._then);

  final AsmaReady _self;
  final $Res Function(AsmaReady) _then;

  /// Create a copy of AsmaState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? names = null,
    Object? selected = freezed,
  }) {
    return _then(AsmaReady(
      names: null == names
          ? _self._names
          : names // ignore: cast_nullable_to_non_nullable
              as List<AsmaName>,
      selected: freezed == selected
          ? _self.selected
          : selected // ignore: cast_nullable_to_non_nullable
              as AsmaName?,
    ));
  }
}

// dart format on

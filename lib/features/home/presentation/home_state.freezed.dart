// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HomeState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is HomeState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'HomeState()';
  }
}

/// @nodoc
class $HomeStateCopyWith<$Res> {
  $HomeStateCopyWith(HomeState _, $Res Function(HomeState) __);
}

/// Adds pattern-matching-related methods to [HomeState].
extension HomeStatePatterns on HomeState {
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
    TResult Function(HomeLoading value)? loading,
    TResult Function(HomeFailed value)? failed,
    TResult Function(HomeReady value)? ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case HomeLoading() when loading != null:
        return loading(_that);
      case HomeFailed() when failed != null:
        return failed(_that);
      case HomeReady() when ready != null:
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
    required TResult Function(HomeLoading value) loading,
    required TResult Function(HomeFailed value) failed,
    required TResult Function(HomeReady value) ready,
  }) {
    final _that = this;
    switch (_that) {
      case HomeLoading():
        return loading(_that);
      case HomeFailed():
        return failed(_that);
      case HomeReady():
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
    TResult? Function(HomeLoading value)? loading,
    TResult? Function(HomeFailed value)? failed,
    TResult? Function(HomeReady value)? ready,
  }) {
    final _that = this;
    switch (_that) {
      case HomeLoading() when loading != null:
        return loading(_that);
      case HomeFailed() when failed != null:
        return failed(_that);
      case HomeReady() when ready != null:
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
    TResult Function(LastReadCard? lastRead, NextPrayerCard? nextPrayer)? ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case HomeLoading() when loading != null:
        return loading();
      case HomeFailed() when failed != null:
        return failed();
      case HomeReady() when ready != null:
        return ready(_that.lastRead, _that.nextPrayer);
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
            LastReadCard? lastRead, NextPrayerCard? nextPrayer)
        ready,
  }) {
    final _that = this;
    switch (_that) {
      case HomeLoading():
        return loading();
      case HomeFailed():
        return failed();
      case HomeReady():
        return ready(_that.lastRead, _that.nextPrayer);
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
    TResult? Function(LastReadCard? lastRead, NextPrayerCard? nextPrayer)?
        ready,
  }) {
    final _that = this;
    switch (_that) {
      case HomeLoading() when loading != null:
        return loading();
      case HomeFailed() when failed != null:
        return failed();
      case HomeReady() when ready != null:
        return ready(_that.lastRead, _that.nextPrayer);
      case _:
        return null;
    }
  }
}

/// @nodoc

class HomeLoading implements HomeState {
  const HomeLoading();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is HomeLoading);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'HomeState.loading()';
  }
}

/// @nodoc

class HomeFailed implements HomeState {
  const HomeFailed();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is HomeFailed);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'HomeState.failed()';
  }
}

/// @nodoc

class HomeReady implements HomeState {
  const HomeReady({this.lastRead = null, this.nextPrayer = null});

  @JsonKey()
  final LastReadCard? lastRead;
  @JsonKey()
  final NextPrayerCard? nextPrayer;

  /// Create a copy of HomeState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $HomeReadyCopyWith<HomeReady> get copyWith =>
      _$HomeReadyCopyWithImpl<HomeReady>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is HomeReady &&
            (identical(other.lastRead, lastRead) ||
                other.lastRead == lastRead) &&
            (identical(other.nextPrayer, nextPrayer) ||
                other.nextPrayer == nextPrayer));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, lastRead, nextPrayer);
  }

  @override
  String toString() {
    return 'HomeState.ready(lastRead: $lastRead, nextPrayer: $nextPrayer)';
  }
}

/// @nodoc
abstract mixin class $HomeReadyCopyWith<$Res>
    implements $HomeStateCopyWith<$Res> {
  factory $HomeReadyCopyWith(HomeReady value, $Res Function(HomeReady) _then) =
      _$HomeReadyCopyWithImpl;
  @useResult
  $Res call({LastReadCard? lastRead, NextPrayerCard? nextPrayer});
}

/// @nodoc
class _$HomeReadyCopyWithImpl<$Res> implements $HomeReadyCopyWith<$Res> {
  _$HomeReadyCopyWithImpl(this._self, this._then);

  final HomeReady _self;
  final $Res Function(HomeReady) _then;

  /// Create a copy of HomeState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? lastRead = freezed,
    Object? nextPrayer = freezed,
  }) {
    return _then(HomeReady(
      lastRead: freezed == lastRead
          ? _self.lastRead
          : lastRead // ignore: cast_nullable_to_non_nullable
              as LastReadCard?,
      nextPrayer: freezed == nextPrayer
          ? _self.nextPrayer
          : nextPrayer // ignore: cast_nullable_to_non_nullable
              as NextPrayerCard?,
    ));
  }
}

// dart format on

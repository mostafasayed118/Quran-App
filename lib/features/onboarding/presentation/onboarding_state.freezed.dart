// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'onboarding_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OnboardingState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is OnboardingState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'OnboardingState()';
  }
}

/// @nodoc
class $OnboardingStateCopyWith<$Res> {
  $OnboardingStateCopyWith(
      OnboardingState _, $Res Function(OnboardingState) __);
}

/// Adds pattern-matching-related methods to [OnboardingState].
extension OnboardingStatePatterns on OnboardingState {
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
    TResult Function(OnboardingLoading value)? loading,
    TResult Function(OnboardingReady value)? ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case OnboardingLoading() when loading != null:
        return loading(_that);
      case OnboardingReady() when ready != null:
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
    required TResult Function(OnboardingLoading value) loading,
    required TResult Function(OnboardingReady value) ready,
  }) {
    final _that = this;
    switch (_that) {
      case OnboardingLoading():
        return loading(_that);
      case OnboardingReady():
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
    TResult? Function(OnboardingLoading value)? loading,
    TResult? Function(OnboardingReady value)? ready,
  }) {
    final _that = this;
    switch (_that) {
      case OnboardingLoading() when loading != null:
        return loading(_that);
      case OnboardingReady() when ready != null:
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
    TResult Function(bool citySelected, String? cityName, bool remindersGranted,
            bool completed)?
        ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case OnboardingLoading() when loading != null:
        return loading();
      case OnboardingReady() when ready != null:
        return ready(_that.citySelected, _that.cityName, _that.remindersGranted,
            _that.completed);
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
    required TResult Function(bool citySelected, String? cityName,
            bool remindersGranted, bool completed)
        ready,
  }) {
    final _that = this;
    switch (_that) {
      case OnboardingLoading():
        return loading();
      case OnboardingReady():
        return ready(_that.citySelected, _that.cityName, _that.remindersGranted,
            _that.completed);
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
    TResult? Function(bool citySelected, String? cityName,
            bool remindersGranted, bool completed)?
        ready,
  }) {
    final _that = this;
    switch (_that) {
      case OnboardingLoading() when loading != null:
        return loading();
      case OnboardingReady() when ready != null:
        return ready(_that.citySelected, _that.cityName, _that.remindersGranted,
            _that.completed);
      case _:
        return null;
    }
  }
}

/// @nodoc

class OnboardingLoading implements OnboardingState {
  const OnboardingLoading();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is OnboardingLoading);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'OnboardingState.loading()';
  }
}

/// @nodoc

class OnboardingReady implements OnboardingState {
  const OnboardingReady(
      {this.citySelected = false,
      this.cityName = null,
      this.remindersGranted = false,
      this.completed = false});

  @JsonKey()
  final bool citySelected;
  @JsonKey()
  final String? cityName;
  @JsonKey()
  final bool remindersGranted;
  @JsonKey()
  final bool completed;

  /// Create a copy of OnboardingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $OnboardingReadyCopyWith<OnboardingReady> get copyWith =>
      _$OnboardingReadyCopyWithImpl<OnboardingReady>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is OnboardingReady &&
            (identical(other.citySelected, citySelected) ||
                other.citySelected == citySelected) &&
            (identical(other.cityName, cityName) ||
                other.cityName == cityName) &&
            (identical(other.remindersGranted, remindersGranted) ||
                other.remindersGranted == remindersGranted) &&
            (identical(other.completed, completed) ||
                other.completed == completed));
  }

  @override
  int get hashCode {
    return Object.hash(
        runtimeType, citySelected, cityName, remindersGranted, completed);
  }

  @override
  String toString() {
    return 'OnboardingState.ready(citySelected: $citySelected, cityName: $cityName, remindersGranted: $remindersGranted, completed: $completed)';
  }
}

/// @nodoc
abstract mixin class $OnboardingReadyCopyWith<$Res>
    implements $OnboardingStateCopyWith<$Res> {
  factory $OnboardingReadyCopyWith(
          OnboardingReady value, $Res Function(OnboardingReady) _then) =
      _$OnboardingReadyCopyWithImpl;
  @useResult
  $Res call(
      {bool citySelected,
      String? cityName,
      bool remindersGranted,
      bool completed});
}

/// @nodoc
class _$OnboardingReadyCopyWithImpl<$Res>
    implements $OnboardingReadyCopyWith<$Res> {
  _$OnboardingReadyCopyWithImpl(this._self, this._then);

  final OnboardingReady _self;
  final $Res Function(OnboardingReady) _then;

  /// Create a copy of OnboardingState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? citySelected = null,
    Object? cityName = freezed,
    Object? remindersGranted = null,
    Object? completed = null,
  }) {
    return _then(OnboardingReady(
      citySelected: null == citySelected
          ? _self.citySelected
          : citySelected // ignore: cast_nullable_to_non_nullable
              as bool,
      cityName: freezed == cityName
          ? _self.cityName
          : cityName // ignore: cast_nullable_to_non_nullable
              as String?,
      remindersGranted: null == remindersGranted
          ? _self.remindersGranted
          : remindersGranted // ignore: cast_nullable_to_non_nullable
              as bool,
      completed: null == completed
          ? _self.completed
          : completed // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on

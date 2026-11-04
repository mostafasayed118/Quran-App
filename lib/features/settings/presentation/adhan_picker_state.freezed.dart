// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'adhan_picker_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AdhanPickerState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is AdhanPickerState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'AdhanPickerState()';
  }
}

/// @nodoc
class $AdhanPickerStateCopyWith<$Res> {
  $AdhanPickerStateCopyWith(
      AdhanPickerState _, $Res Function(AdhanPickerState) __);
}

/// Adds pattern-matching-related methods to [AdhanPickerState].
extension AdhanPickerStatePatterns on AdhanPickerState {
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
    TResult Function(AdhanPickerLoading value)? loading,
    TResult Function(AdhanPickerFailed value)? failed,
    TResult Function(AdhanPickerReady value)? ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case AdhanPickerLoading() when loading != null:
        return loading(_that);
      case AdhanPickerFailed() when failed != null:
        return failed(_that);
      case AdhanPickerReady() when ready != null:
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
    required TResult Function(AdhanPickerLoading value) loading,
    required TResult Function(AdhanPickerFailed value) failed,
    required TResult Function(AdhanPickerReady value) ready,
  }) {
    final _that = this;
    switch (_that) {
      case AdhanPickerLoading():
        return loading(_that);
      case AdhanPickerFailed():
        return failed(_that);
      case AdhanPickerReady():
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
    TResult? Function(AdhanPickerLoading value)? loading,
    TResult? Function(AdhanPickerFailed value)? failed,
    TResult? Function(AdhanPickerReady value)? ready,
  }) {
    final _that = this;
    switch (_that) {
      case AdhanPickerLoading() when loading != null:
        return loading(_that);
      case AdhanPickerFailed() when failed != null:
        return failed(_that);
      case AdhanPickerReady() when ready != null:
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
    TResult Function(String adhanId, String? fajrAdhanId, String? previewingId)?
        ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case AdhanPickerLoading() when loading != null:
        return loading();
      case AdhanPickerFailed() when failed != null:
        return failed();
      case AdhanPickerReady() when ready != null:
        return ready(_that.adhanId, _that.fajrAdhanId, _that.previewingId);
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
            String adhanId, String? fajrAdhanId, String? previewingId)
        ready,
  }) {
    final _that = this;
    switch (_that) {
      case AdhanPickerLoading():
        return loading();
      case AdhanPickerFailed():
        return failed();
      case AdhanPickerReady():
        return ready(_that.adhanId, _that.fajrAdhanId, _that.previewingId);
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
            String adhanId, String? fajrAdhanId, String? previewingId)?
        ready,
  }) {
    final _that = this;
    switch (_that) {
      case AdhanPickerLoading() when loading != null:
        return loading();
      case AdhanPickerFailed() when failed != null:
        return failed();
      case AdhanPickerReady() when ready != null:
        return ready(_that.adhanId, _that.fajrAdhanId, _that.previewingId);
      case _:
        return null;
    }
  }
}

/// @nodoc

class AdhanPickerLoading implements AdhanPickerState {
  const AdhanPickerLoading();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is AdhanPickerLoading);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'AdhanPickerState.loading()';
  }
}

/// @nodoc

class AdhanPickerFailed implements AdhanPickerState {
  const AdhanPickerFailed();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is AdhanPickerFailed);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'AdhanPickerState.failed()';
  }
}

/// @nodoc

class AdhanPickerReady implements AdhanPickerState {
  const AdhanPickerReady(
      {this.adhanId = kDefaultAdhanId, this.fajrAdhanId, this.previewingId});

  @JsonKey()
  final String adhanId;
  final String? fajrAdhanId;
  final String? previewingId;

  /// Create a copy of AdhanPickerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AdhanPickerReadyCopyWith<AdhanPickerReady> get copyWith =>
      _$AdhanPickerReadyCopyWithImpl<AdhanPickerReady>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AdhanPickerReady &&
            (identical(other.adhanId, adhanId) || other.adhanId == adhanId) &&
            (identical(other.fajrAdhanId, fajrAdhanId) ||
                other.fajrAdhanId == fajrAdhanId) &&
            (identical(other.previewingId, previewingId) ||
                other.previewingId == previewingId));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, adhanId, fajrAdhanId, previewingId);
  }

  @override
  String toString() {
    return 'AdhanPickerState.ready(adhanId: $adhanId, fajrAdhanId: $fajrAdhanId, previewingId: $previewingId)';
  }
}

/// @nodoc
abstract mixin class $AdhanPickerReadyCopyWith<$Res>
    implements $AdhanPickerStateCopyWith<$Res> {
  factory $AdhanPickerReadyCopyWith(
          AdhanPickerReady value, $Res Function(AdhanPickerReady) _then) =
      _$AdhanPickerReadyCopyWithImpl;
  @useResult
  $Res call({String adhanId, String? fajrAdhanId, String? previewingId});
}

/// @nodoc
class _$AdhanPickerReadyCopyWithImpl<$Res>
    implements $AdhanPickerReadyCopyWith<$Res> {
  _$AdhanPickerReadyCopyWithImpl(this._self, this._then);

  final AdhanPickerReady _self;
  final $Res Function(AdhanPickerReady) _then;

  /// Create a copy of AdhanPickerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? adhanId = null,
    Object? fajrAdhanId = freezed,
    Object? previewingId = freezed,
  }) {
    return _then(AdhanPickerReady(
      adhanId: null == adhanId
          ? _self.adhanId
          : adhanId // ignore: cast_nullable_to_non_nullable
              as String,
      fajrAdhanId: freezed == fajrAdhanId
          ? _self.fajrAdhanId
          : fajrAdhanId // ignore: cast_nullable_to_non_nullable
              as String?,
      previewingId: freezed == previewingId
          ? _self.previewingId
          : previewingId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on

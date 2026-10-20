// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ayah_sheet_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AyahSheetState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is AyahSheetState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'AyahSheetState()';
  }
}

/// @nodoc
class $AyahSheetStateCopyWith<$Res> {
  $AyahSheetStateCopyWith(AyahSheetState _, $Res Function(AyahSheetState) __);
}

/// Adds pattern-matching-related methods to [AyahSheetState].
extension AyahSheetStatePatterns on AyahSheetState {
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
    TResult Function(AyahSheetLoading value)? loading,
    TResult Function(AyahSheetReady value)? ready,
    TResult Function(AyahSheetFailed value)? failed,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case AyahSheetLoading() when loading != null:
        return loading(_that);
      case AyahSheetReady() when ready != null:
        return ready(_that);
      case AyahSheetFailed() when failed != null:
        return failed(_that);
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
    required TResult Function(AyahSheetLoading value) loading,
    required TResult Function(AyahSheetReady value) ready,
    required TResult Function(AyahSheetFailed value) failed,
  }) {
    final _that = this;
    switch (_that) {
      case AyahSheetLoading():
        return loading(_that);
      case AyahSheetReady():
        return ready(_that);
      case AyahSheetFailed():
        return failed(_that);
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
    TResult? Function(AyahSheetLoading value)? loading,
    TResult? Function(AyahSheetReady value)? ready,
    TResult? Function(AyahSheetFailed value)? failed,
  }) {
    final _that = this;
    switch (_that) {
      case AyahSheetLoading() when loading != null:
        return loading(_that);
      case AyahSheetReady() when ready != null:
        return ready(_that);
      case AyahSheetFailed() when failed != null:
        return failed(_that);
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
    TResult Function(List<AyahSheetEntry> tafsirEntries,
            List<AyahSheetEntry> translationEntries)?
        ready,
    TResult Function()? failed,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case AyahSheetLoading() when loading != null:
        return loading();
      case AyahSheetReady() when ready != null:
        return ready(_that.tafsirEntries, _that.translationEntries);
      case AyahSheetFailed() when failed != null:
        return failed();
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
    required TResult Function(List<AyahSheetEntry> tafsirEntries,
            List<AyahSheetEntry> translationEntries)
        ready,
    required TResult Function() failed,
  }) {
    final _that = this;
    switch (_that) {
      case AyahSheetLoading():
        return loading();
      case AyahSheetReady():
        return ready(_that.tafsirEntries, _that.translationEntries);
      case AyahSheetFailed():
        return failed();
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
    TResult? Function(List<AyahSheetEntry> tafsirEntries,
            List<AyahSheetEntry> translationEntries)?
        ready,
    TResult? Function()? failed,
  }) {
    final _that = this;
    switch (_that) {
      case AyahSheetLoading() when loading != null:
        return loading();
      case AyahSheetReady() when ready != null:
        return ready(_that.tafsirEntries, _that.translationEntries);
      case AyahSheetFailed() when failed != null:
        return failed();
      case _:
        return null;
    }
  }
}

/// @nodoc

class AyahSheetLoading implements AyahSheetState {
  const AyahSheetLoading();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is AyahSheetLoading);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'AyahSheetState.loading()';
  }
}

/// @nodoc

class AyahSheetReady implements AyahSheetState {
  const AyahSheetReady(
      {required List<AyahSheetEntry> tafsirEntries,
      required List<AyahSheetEntry> translationEntries})
      : _tafsirEntries = tafsirEntries,
        _translationEntries = translationEntries;

  final List<AyahSheetEntry> _tafsirEntries;
  List<AyahSheetEntry> get tafsirEntries {
    if (_tafsirEntries is EqualUnmodifiableListView) return _tafsirEntries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tafsirEntries);
  }

  final List<AyahSheetEntry> _translationEntries;
  List<AyahSheetEntry> get translationEntries {
    if (_translationEntries is EqualUnmodifiableListView)
      return _translationEntries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_translationEntries);
  }

  /// Create a copy of AyahSheetState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AyahSheetReadyCopyWith<AyahSheetReady> get copyWith =>
      _$AyahSheetReadyCopyWithImpl<AyahSheetReady>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AyahSheetReady &&
            const DeepCollectionEquality()
                .equals(other.tafsirEntries, _tafsirEntries) &&
            const DeepCollectionEquality()
                .equals(other.translationEntries, _translationEntries));
  }

  @override
  int get hashCode {
    return Object.hash(
        runtimeType,
        const DeepCollectionEquality().hash(_tafsirEntries),
        const DeepCollectionEquality().hash(_translationEntries));
  }

  @override
  String toString() {
    return 'AyahSheetState.ready(tafsirEntries: $tafsirEntries, translationEntries: $translationEntries)';
  }
}

/// @nodoc
abstract mixin class $AyahSheetReadyCopyWith<$Res>
    implements $AyahSheetStateCopyWith<$Res> {
  factory $AyahSheetReadyCopyWith(
          AyahSheetReady value, $Res Function(AyahSheetReady) _then) =
      _$AyahSheetReadyCopyWithImpl;
  @useResult
  $Res call(
      {List<AyahSheetEntry> tafsirEntries,
      List<AyahSheetEntry> translationEntries});
}

/// @nodoc
class _$AyahSheetReadyCopyWithImpl<$Res>
    implements $AyahSheetReadyCopyWith<$Res> {
  _$AyahSheetReadyCopyWithImpl(this._self, this._then);

  final AyahSheetReady _self;
  final $Res Function(AyahSheetReady) _then;

  /// Create a copy of AyahSheetState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? tafsirEntries = null,
    Object? translationEntries = null,
  }) {
    return _then(AyahSheetReady(
      tafsirEntries: null == tafsirEntries
          ? _self._tafsirEntries
          : tafsirEntries // ignore: cast_nullable_to_non_nullable
              as List<AyahSheetEntry>,
      translationEntries: null == translationEntries
          ? _self._translationEntries
          : translationEntries // ignore: cast_nullable_to_non_nullable
              as List<AyahSheetEntry>,
    ));
  }
}

/// @nodoc

class AyahSheetFailed implements AyahSheetState {
  const AyahSheetFailed();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is AyahSheetFailed);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'AyahSheetState.failed()';
  }
}

// dart format on

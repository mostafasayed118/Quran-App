// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'library_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LibraryState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is LibraryState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'LibraryState()';
  }
}

/// @nodoc
class $LibraryStateCopyWith<$Res> {
  $LibraryStateCopyWith(LibraryState _, $Res Function(LibraryState) __);
}

/// Adds pattern-matching-related methods to [LibraryState].
extension LibraryStatePatterns on LibraryState {
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
    TResult Function(LibraryLoading value)? loading,
    TResult Function(LibraryReady value)? ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case LibraryLoading() when loading != null:
        return loading(_that);
      case LibraryReady() when ready != null:
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
    required TResult Function(LibraryLoading value) loading,
    required TResult Function(LibraryReady value) ready,
  }) {
    final _that = this;
    switch (_that) {
      case LibraryLoading():
        return loading(_that);
      case LibraryReady():
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
    TResult? Function(LibraryLoading value)? loading,
    TResult? Function(LibraryReady value)? ready,
  }) {
    final _that = this;
    switch (_that) {
      case LibraryLoading() when loading != null:
        return loading(_that);
      case LibraryReady() when ready != null:
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
            List<LibraryPackInfo> packs,
            Set<String> installed,
            Map<
                    String,
                    (
                      int,
                      int,
                    )>
                progress,
            Set<String> failed)?
        ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case LibraryLoading() when loading != null:
        return loading();
      case LibraryReady() when ready != null:
        return ready(
            _that.packs, _that.installed, _that.progress, _that.failed);
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
            List<LibraryPackInfo> packs,
            Set<String> installed,
            Map<
                    String,
                    (
                      int,
                      int,
                    )>
                progress,
            Set<String> failed)
        ready,
  }) {
    final _that = this;
    switch (_that) {
      case LibraryLoading():
        return loading();
      case LibraryReady():
        return ready(
            _that.packs, _that.installed, _that.progress, _that.failed);
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
            List<LibraryPackInfo> packs,
            Set<String> installed,
            Map<
                    String,
                    (
                      int,
                      int,
                    )>
                progress,
            Set<String> failed)?
        ready,
  }) {
    final _that = this;
    switch (_that) {
      case LibraryLoading() when loading != null:
        return loading();
      case LibraryReady() when ready != null:
        return ready(
            _that.packs, _that.installed, _that.progress, _that.failed);
      case _:
        return null;
    }
  }
}

/// @nodoc

class LibraryLoading implements LibraryState {
  const LibraryLoading();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is LibraryLoading);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'LibraryState.loading()';
  }
}

/// @nodoc

class LibraryReady implements LibraryState {
  const LibraryReady(
      {required List<LibraryPackInfo> packs,
      Set<String> installed = const <String>{},
      Map<
              String,
              (
                int,
                int,
              )>
          progress = const <String, (int, int)>{},
      Set<String> failed = const <String>{}})
      : _packs = packs,
        _installed = installed,
        _progress = progress,
        _failed = failed;

  final List<LibraryPackInfo> _packs;
  List<LibraryPackInfo> get packs {
    if (_packs is EqualUnmodifiableListView) return _packs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_packs);
  }

  final Set<String> _installed;
  @JsonKey()
  Set<String> get installed {
    if (_installed is EqualUnmodifiableSetView) return _installed;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_installed);
  }

  /// packId -> (received bytes, expected bytes)
  final Map<
      String,
      (
        int,
        int,
      )> _progress;

  /// packId -> (received bytes, expected bytes)
  @JsonKey()
  Map<
      String,
      (
        int,
        int,
      )> get progress {
    if (_progress is EqualUnmodifiableMapView) return _progress;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_progress);
  }

  final Set<String> _failed;
  @JsonKey()
  Set<String> get failed {
    if (_failed is EqualUnmodifiableSetView) return _failed;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_failed);
  }

  /// Create a copy of LibraryState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LibraryReadyCopyWith<LibraryReady> get copyWith =>
      _$LibraryReadyCopyWithImpl<LibraryReady>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LibraryReady &&
            const DeepCollectionEquality().equals(other.packs, _packs) &&
            const DeepCollectionEquality()
                .equals(other.installed, _installed) &&
            const DeepCollectionEquality().equals(other.progress, _progress) &&
            const DeepCollectionEquality().equals(other.failed, _failed));
  }

  @override
  int get hashCode {
    return Object.hash(
        runtimeType,
        const DeepCollectionEquality().hash(_packs),
        const DeepCollectionEquality().hash(_installed),
        const DeepCollectionEquality().hash(_progress),
        const DeepCollectionEquality().hash(_failed));
  }

  @override
  String toString() {
    return 'LibraryState.ready(packs: $packs, installed: $installed, progress: $progress, failed: $failed)';
  }
}

/// @nodoc
abstract mixin class $LibraryReadyCopyWith<$Res>
    implements $LibraryStateCopyWith<$Res> {
  factory $LibraryReadyCopyWith(
          LibraryReady value, $Res Function(LibraryReady) _then) =
      _$LibraryReadyCopyWithImpl;
  @useResult
  $Res call(
      {List<LibraryPackInfo> packs,
      Set<String> installed,
      Map<
              String,
              (
                int,
                int,
              )>
          progress,
      Set<String> failed});
}

/// @nodoc
class _$LibraryReadyCopyWithImpl<$Res> implements $LibraryReadyCopyWith<$Res> {
  _$LibraryReadyCopyWithImpl(this._self, this._then);

  final LibraryReady _self;
  final $Res Function(LibraryReady) _then;

  /// Create a copy of LibraryState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? packs = null,
    Object? installed = null,
    Object? progress = null,
    Object? failed = null,
  }) {
    return _then(LibraryReady(
      packs: null == packs
          ? _self._packs
          : packs // ignore: cast_nullable_to_non_nullable
              as List<LibraryPackInfo>,
      installed: null == installed
          ? _self._installed
          : installed // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      progress: null == progress
          ? _self._progress
          : progress // ignore: cast_nullable_to_non_nullable
              as Map<
                  String,
                  (
                    int,
                    int,
                  )>,
      failed: null == failed
          ? _self._failed
          : failed // ignore: cast_nullable_to_non_nullable
              as Set<String>,
    ));
  }
}

// dart format on

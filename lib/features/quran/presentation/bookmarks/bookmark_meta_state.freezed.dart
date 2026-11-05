// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bookmark_meta_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BookmarkMetaState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is BookmarkMetaState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'BookmarkMetaState()';
  }
}

/// @nodoc
class $BookmarkMetaStateCopyWith<$Res> {
  $BookmarkMetaStateCopyWith(
      BookmarkMetaState _, $Res Function(BookmarkMetaState) __);
}

/// Adds pattern-matching-related methods to [BookmarkMetaState].
extension BookmarkMetaStatePatterns on BookmarkMetaState {
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
    TResult Function(BookmarkMetaLoading value)? loading,
    TResult Function(BookmarkMetaFailed value)? failed,
    TResult Function(BookmarkMetaReady value)? ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case BookmarkMetaLoading() when loading != null:
        return loading(_that);
      case BookmarkMetaFailed() when failed != null:
        return failed(_that);
      case BookmarkMetaReady() when ready != null:
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
    required TResult Function(BookmarkMetaLoading value) loading,
    required TResult Function(BookmarkMetaFailed value) failed,
    required TResult Function(BookmarkMetaReady value) ready,
  }) {
    final _that = this;
    switch (_that) {
      case BookmarkMetaLoading():
        return loading(_that);
      case BookmarkMetaFailed():
        return failed(_that);
      case BookmarkMetaReady():
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
    TResult? Function(BookmarkMetaLoading value)? loading,
    TResult? Function(BookmarkMetaFailed value)? failed,
    TResult? Function(BookmarkMetaReady value)? ready,
  }) {
    final _that = this;
    switch (_that) {
      case BookmarkMetaLoading() when loading != null:
        return loading(_that);
      case BookmarkMetaFailed() when failed != null:
        return failed(_that);
      case BookmarkMetaReady() when ready != null:
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
    TResult Function(Map<int, BookmarkMetaEntry> entries)? ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case BookmarkMetaLoading() when loading != null:
        return loading();
      case BookmarkMetaFailed() when failed != null:
        return failed();
      case BookmarkMetaReady() when ready != null:
        return ready(_that.entries);
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
    required TResult Function(Map<int, BookmarkMetaEntry> entries) ready,
  }) {
    final _that = this;
    switch (_that) {
      case BookmarkMetaLoading():
        return loading();
      case BookmarkMetaFailed():
        return failed();
      case BookmarkMetaReady():
        return ready(_that.entries);
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
    TResult? Function(Map<int, BookmarkMetaEntry> entries)? ready,
  }) {
    final _that = this;
    switch (_that) {
      case BookmarkMetaLoading() when loading != null:
        return loading();
      case BookmarkMetaFailed() when failed != null:
        return failed();
      case BookmarkMetaReady() when ready != null:
        return ready(_that.entries);
      case _:
        return null;
    }
  }
}

/// @nodoc

class BookmarkMetaLoading implements BookmarkMetaState {
  const BookmarkMetaLoading();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is BookmarkMetaLoading);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'BookmarkMetaState.loading()';
  }
}

/// @nodoc

class BookmarkMetaFailed implements BookmarkMetaState {
  const BookmarkMetaFailed();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is BookmarkMetaFailed);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'BookmarkMetaState.failed()';
  }
}

/// @nodoc

class BookmarkMetaReady implements BookmarkMetaState {
  const BookmarkMetaReady(
      {Map<int, BookmarkMetaEntry> entries = const <int, BookmarkMetaEntry>{}})
      : _entries = entries;

  final Map<int, BookmarkMetaEntry> _entries;
  @JsonKey()
  Map<int, BookmarkMetaEntry> get entries {
    if (_entries is EqualUnmodifiableMapView) return _entries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_entries);
  }

  /// Create a copy of BookmarkMetaState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BookmarkMetaReadyCopyWith<BookmarkMetaReady> get copyWith =>
      _$BookmarkMetaReadyCopyWithImpl<BookmarkMetaReady>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BookmarkMetaReady &&
            const DeepCollectionEquality().equals(other.entries, _entries));
  }

  @override
  int get hashCode {
    return Object.hash(
        runtimeType, const DeepCollectionEquality().hash(_entries));
  }

  @override
  String toString() {
    return 'BookmarkMetaState.ready(entries: $entries)';
  }
}

/// @nodoc
abstract mixin class $BookmarkMetaReadyCopyWith<$Res>
    implements $BookmarkMetaStateCopyWith<$Res> {
  factory $BookmarkMetaReadyCopyWith(
          BookmarkMetaReady value, $Res Function(BookmarkMetaReady) _then) =
      _$BookmarkMetaReadyCopyWithImpl;
  @useResult
  $Res call({Map<int, BookmarkMetaEntry> entries});
}

/// @nodoc
class _$BookmarkMetaReadyCopyWithImpl<$Res>
    implements $BookmarkMetaReadyCopyWith<$Res> {
  _$BookmarkMetaReadyCopyWithImpl(this._self, this._then);

  final BookmarkMetaReady _self;
  final $Res Function(BookmarkMetaReady) _then;

  /// Create a copy of BookmarkMetaState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? entries = null,
  }) {
    return _then(BookmarkMetaReady(
      entries: null == entries
          ? _self._entries
          : entries // ignore: cast_nullable_to_non_nullable
              as Map<int, BookmarkMetaEntry>,
    ));
  }
}

// dart format on

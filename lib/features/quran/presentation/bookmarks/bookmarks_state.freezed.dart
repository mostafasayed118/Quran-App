// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bookmarks_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BookmarksState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is BookmarksState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'BookmarksState()';
  }
}

/// @nodoc
class $BookmarksStateCopyWith<$Res> {
  $BookmarksStateCopyWith(BookmarksState _, $Res Function(BookmarksState) __);
}

/// Adds pattern-matching-related methods to [BookmarksState].
extension BookmarksStatePatterns on BookmarksState {
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
    TResult Function(BookmarksLoading value)? loading,
    TResult Function(BookmarksReady value)? ready,
    TResult Function(BookmarksFailed value)? failed,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case BookmarksLoading() when loading != null:
        return loading(_that);
      case BookmarksReady() when ready != null:
        return ready(_that);
      case BookmarksFailed() when failed != null:
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
    required TResult Function(BookmarksLoading value) loading,
    required TResult Function(BookmarksReady value) ready,
    required TResult Function(BookmarksFailed value) failed,
  }) {
    final _that = this;
    switch (_that) {
      case BookmarksLoading():
        return loading(_that);
      case BookmarksReady():
        return ready(_that);
      case BookmarksFailed():
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
    TResult? Function(BookmarksLoading value)? loading,
    TResult? Function(BookmarksReady value)? ready,
    TResult? Function(BookmarksFailed value)? failed,
  }) {
    final _that = this;
    switch (_that) {
      case BookmarksLoading() when loading != null:
        return loading(_that);
      case BookmarksReady() when ready != null:
        return ready(_that);
      case BookmarksFailed() when failed != null:
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
    TResult Function(List<Verse> entries)? ready,
    TResult Function()? failed,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case BookmarksLoading() when loading != null:
        return loading();
      case BookmarksReady() when ready != null:
        return ready(_that.entries);
      case BookmarksFailed() when failed != null:
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
    required TResult Function(List<Verse> entries) ready,
    required TResult Function() failed,
  }) {
    final _that = this;
    switch (_that) {
      case BookmarksLoading():
        return loading();
      case BookmarksReady():
        return ready(_that.entries);
      case BookmarksFailed():
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
    TResult? Function(List<Verse> entries)? ready,
    TResult? Function()? failed,
  }) {
    final _that = this;
    switch (_that) {
      case BookmarksLoading() when loading != null:
        return loading();
      case BookmarksReady() when ready != null:
        return ready(_that.entries);
      case BookmarksFailed() when failed != null:
        return failed();
      case _:
        return null;
    }
  }
}

/// @nodoc

class BookmarksLoading implements BookmarksState {
  const BookmarksLoading();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is BookmarksLoading);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'BookmarksState.loading()';
  }
}

/// @nodoc

class BookmarksReady implements BookmarksState {
  const BookmarksReady({required List<Verse> entries}) : _entries = entries;

  final List<Verse> _entries;
  List<Verse> get entries {
    if (_entries is EqualUnmodifiableListView) return _entries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_entries);
  }

  /// Create a copy of BookmarksState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BookmarksReadyCopyWith<BookmarksReady> get copyWith =>
      _$BookmarksReadyCopyWithImpl<BookmarksReady>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BookmarksReady &&
            const DeepCollectionEquality().equals(other.entries, _entries));
  }

  @override
  int get hashCode {
    return Object.hash(
        runtimeType, const DeepCollectionEquality().hash(_entries));
  }

  @override
  String toString() {
    return 'BookmarksState.ready(entries: $entries)';
  }
}

/// @nodoc
abstract mixin class $BookmarksReadyCopyWith<$Res>
    implements $BookmarksStateCopyWith<$Res> {
  factory $BookmarksReadyCopyWith(
          BookmarksReady value, $Res Function(BookmarksReady) _then) =
      _$BookmarksReadyCopyWithImpl;
  @useResult
  $Res call({List<Verse> entries});
}

/// @nodoc
class _$BookmarksReadyCopyWithImpl<$Res>
    implements $BookmarksReadyCopyWith<$Res> {
  _$BookmarksReadyCopyWithImpl(this._self, this._then);

  final BookmarksReady _self;
  final $Res Function(BookmarksReady) _then;

  /// Create a copy of BookmarksState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? entries = null,
  }) {
    return _then(BookmarksReady(
      entries: null == entries
          ? _self._entries
          : entries // ignore: cast_nullable_to_non_nullable
              as List<Verse>,
    ));
  }
}

/// @nodoc

class BookmarksFailed implements BookmarksState {
  const BookmarksFailed();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is BookmarksFailed);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'BookmarksState.failed()';
  }
}

// dart format on

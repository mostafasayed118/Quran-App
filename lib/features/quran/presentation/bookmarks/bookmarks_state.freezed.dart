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
    TResult Function(BookmarksError value)? error,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case BookmarksLoading() when loading != null:
        return loading(_that);
      case BookmarksReady() when ready != null:
        return ready(_that);
      case BookmarksError() when error != null:
        return error(_that);
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
    required TResult Function(BookmarksError value) error,
  }) {
    final _that = this;
    switch (_that) {
      case BookmarksLoading():
        return loading(_that);
      case BookmarksReady():
        return ready(_that);
      case BookmarksError():
        return error(_that);
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
    TResult? Function(BookmarksError value)? error,
  }) {
    final _that = this;
    switch (_that) {
      case BookmarksLoading() when loading != null:
        return loading(_that);
      case BookmarksReady() when ready != null:
        return ready(_that);
      case BookmarksError() when error != null:
        return error(_that);
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
    TResult Function(List<BookmarkEntry> entries)? ready,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case BookmarksLoading() when loading != null:
        return loading();
      case BookmarksReady() when ready != null:
        return ready(_that.entries);
      case BookmarksError() when error != null:
        return error(_that.message);
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
    required TResult Function(List<BookmarkEntry> entries) ready,
    required TResult Function(String message) error,
  }) {
    final _that = this;
    switch (_that) {
      case BookmarksLoading():
        return loading();
      case BookmarksReady():
        return ready(_that.entries);
      case BookmarksError():
        return error(_that.message);
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
    TResult? Function(List<BookmarkEntry> entries)? ready,
    TResult? Function(String message)? error,
  }) {
    final _that = this;
    switch (_that) {
      case BookmarksLoading() when loading != null:
        return loading();
      case BookmarksReady() when ready != null:
        return ready(_that.entries);
      case BookmarksError() when error != null:
        return error(_that.message);
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
  const BookmarksReady({required List<BookmarkEntry> entries})
      : _entries = entries;

  final List<BookmarkEntry> _entries;
  List<BookmarkEntry> get entries {
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
  $Res call({List<BookmarkEntry> entries});
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
              as List<BookmarkEntry>,
    ));
  }
}

/// @nodoc

class BookmarksError implements BookmarksState {
  const BookmarksError({required this.message});

  final String message;

  /// Create a copy of BookmarksState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BookmarksErrorCopyWith<BookmarksError> get copyWith =>
      _$BookmarksErrorCopyWithImpl<BookmarksError>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BookmarksError &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, message);
  }

  @override
  String toString() {
    return 'BookmarksState.error(message: $message)';
  }
}

/// @nodoc
abstract mixin class $BookmarksErrorCopyWith<$Res>
    implements $BookmarksStateCopyWith<$Res> {
  factory $BookmarksErrorCopyWith(
          BookmarksError value, $Res Function(BookmarksError) _then) =
      _$BookmarksErrorCopyWithImpl;
  @useResult
  $Res call({String message});
}

/// @nodoc
class _$BookmarksErrorCopyWithImpl<$Res>
    implements $BookmarksErrorCopyWith<$Res> {
  _$BookmarksErrorCopyWithImpl(this._self, this._then);

  final BookmarksError _self;
  final $Res Function(BookmarksError) _then;

  /// Create a copy of BookmarksState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? message = null,
  }) {
    return _then(BookmarksError(
      message: null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on

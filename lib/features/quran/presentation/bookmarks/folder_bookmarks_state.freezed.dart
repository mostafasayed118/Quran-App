// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'folder_bookmarks_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FolderBookmarksState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is FolderBookmarksState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'FolderBookmarksState()';
  }
}

/// @nodoc
class $FolderBookmarksStateCopyWith<$Res> {
  $FolderBookmarksStateCopyWith(
      FolderBookmarksState _, $Res Function(FolderBookmarksState) __);
}

/// Adds pattern-matching-related methods to [FolderBookmarksState].
extension FolderBookmarksStatePatterns on FolderBookmarksState {
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
    TResult Function(FolderBookmarksLoading value)? loading,
    TResult Function(FolderBookmarksFailed value)? failed,
    TResult Function(FolderBookmarksReady value)? ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case FolderBookmarksLoading() when loading != null:
        return loading(_that);
      case FolderBookmarksFailed() when failed != null:
        return failed(_that);
      case FolderBookmarksReady() when ready != null:
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
    required TResult Function(FolderBookmarksLoading value) loading,
    required TResult Function(FolderBookmarksFailed value) failed,
    required TResult Function(FolderBookmarksReady value) ready,
  }) {
    final _that = this;
    switch (_that) {
      case FolderBookmarksLoading():
        return loading(_that);
      case FolderBookmarksFailed():
        return failed(_that);
      case FolderBookmarksReady():
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
    TResult? Function(FolderBookmarksLoading value)? loading,
    TResult? Function(FolderBookmarksFailed value)? failed,
    TResult? Function(FolderBookmarksReady value)? ready,
  }) {
    final _that = this;
    switch (_that) {
      case FolderBookmarksLoading() when loading != null:
        return loading(_that);
      case FolderBookmarksFailed() when failed != null:
        return failed(_that);
      case FolderBookmarksReady() when ready != null:
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
    TResult Function(String folder, List<FolderBookmark> items)? ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case FolderBookmarksLoading() when loading != null:
        return loading();
      case FolderBookmarksFailed() when failed != null:
        return failed();
      case FolderBookmarksReady() when ready != null:
        return ready(_that.folder, _that.items);
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
    required TResult Function(String folder, List<FolderBookmark> items) ready,
  }) {
    final _that = this;
    switch (_that) {
      case FolderBookmarksLoading():
        return loading();
      case FolderBookmarksFailed():
        return failed();
      case FolderBookmarksReady():
        return ready(_that.folder, _that.items);
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
    TResult? Function(String folder, List<FolderBookmark> items)? ready,
  }) {
    final _that = this;
    switch (_that) {
      case FolderBookmarksLoading() when loading != null:
        return loading();
      case FolderBookmarksFailed() when failed != null:
        return failed();
      case FolderBookmarksReady() when ready != null:
        return ready(_that.folder, _that.items);
      case _:
        return null;
    }
  }
}

/// @nodoc

class FolderBookmarksLoading implements FolderBookmarksState {
  const FolderBookmarksLoading();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is FolderBookmarksLoading);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'FolderBookmarksState.loading()';
  }
}

/// @nodoc

class FolderBookmarksFailed implements FolderBookmarksState {
  const FolderBookmarksFailed();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is FolderBookmarksFailed);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'FolderBookmarksState.failed()';
  }
}

/// @nodoc

class FolderBookmarksReady implements FolderBookmarksState {
  const FolderBookmarksReady(
      {required this.folder,
      List<FolderBookmark> items = const <FolderBookmark>[]})
      : _items = items;

  final String folder;
  final List<FolderBookmark> _items;
  @JsonKey()
  List<FolderBookmark> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  /// Create a copy of FolderBookmarksState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FolderBookmarksReadyCopyWith<FolderBookmarksReady> get copyWith =>
      _$FolderBookmarksReadyCopyWithImpl<FolderBookmarksReady>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FolderBookmarksReady &&
            (identical(other.folder, folder) || other.folder == folder) &&
            const DeepCollectionEquality().equals(other.items, _items));
  }

  @override
  int get hashCode {
    return Object.hash(
        runtimeType, folder, const DeepCollectionEquality().hash(_items));
  }

  @override
  String toString() {
    return 'FolderBookmarksState.ready(folder: $folder, items: $items)';
  }
}

/// @nodoc
abstract mixin class $FolderBookmarksReadyCopyWith<$Res>
    implements $FolderBookmarksStateCopyWith<$Res> {
  factory $FolderBookmarksReadyCopyWith(FolderBookmarksReady value,
          $Res Function(FolderBookmarksReady) _then) =
      _$FolderBookmarksReadyCopyWithImpl;
  @useResult
  $Res call({String folder, List<FolderBookmark> items});
}

/// @nodoc
class _$FolderBookmarksReadyCopyWithImpl<$Res>
    implements $FolderBookmarksReadyCopyWith<$Res> {
  _$FolderBookmarksReadyCopyWithImpl(this._self, this._then);

  final FolderBookmarksReady _self;
  final $Res Function(FolderBookmarksReady) _then;

  /// Create a copy of FolderBookmarksState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? folder = null,
    Object? items = null,
  }) {
    return _then(FolderBookmarksReady(
      folder: null == folder
          ? _self.folder
          : folder // ignore: cast_nullable_to_non_nullable
              as String,
      items: null == items
          ? _self._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<FolderBookmark>,
    ));
  }
}

// dart format on

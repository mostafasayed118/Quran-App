// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hadith_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HadithState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is HadithState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'HadithState()';
  }
}

/// @nodoc
class $HadithStateCopyWith<$Res> {
  $HadithStateCopyWith(HadithState _, $Res Function(HadithState) __);
}

/// Adds pattern-matching-related methods to [HadithState].
extension HadithStatePatterns on HadithState {
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
    TResult Function(HadithLoading value)? loading,
    TResult Function(HadithReady value)? ready,
    TResult Function(HadithError value)? error,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case HadithLoading() when loading != null:
        return loading(_that);
      case HadithReady() when ready != null:
        return ready(_that);
      case HadithError() when error != null:
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
    required TResult Function(HadithLoading value) loading,
    required TResult Function(HadithReady value) ready,
    required TResult Function(HadithError value) error,
  }) {
    final _that = this;
    switch (_that) {
      case HadithLoading():
        return loading(_that);
      case HadithReady():
        return ready(_that);
      case HadithError():
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
    TResult? Function(HadithLoading value)? loading,
    TResult? Function(HadithReady value)? ready,
    TResult? Function(HadithError value)? error,
  }) {
    final _that = this;
    switch (_that) {
      case HadithLoading() when loading != null:
        return loading(_that);
      case HadithReady() when ready != null:
        return ready(_that);
      case HadithError() when error != null:
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
    TResult Function(String packTitle, String language, List<HadithItem> items,
            int offset, bool hasMore)?
        ready,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case HadithLoading() when loading != null:
        return loading();
      case HadithReady() when ready != null:
        return ready(_that.packTitle, _that.language, _that.items, _that.offset,
            _that.hasMore);
      case HadithError() when error != null:
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
    required TResult Function(String packTitle, String language,
            List<HadithItem> items, int offset, bool hasMore)
        ready,
    required TResult Function(String message) error,
  }) {
    final _that = this;
    switch (_that) {
      case HadithLoading():
        return loading();
      case HadithReady():
        return ready(_that.packTitle, _that.language, _that.items, _that.offset,
            _that.hasMore);
      case HadithError():
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
    TResult? Function(String packTitle, String language, List<HadithItem> items,
            int offset, bool hasMore)?
        ready,
    TResult? Function(String message)? error,
  }) {
    final _that = this;
    switch (_that) {
      case HadithLoading() when loading != null:
        return loading();
      case HadithReady() when ready != null:
        return ready(_that.packTitle, _that.language, _that.items, _that.offset,
            _that.hasMore);
      case HadithError() when error != null:
        return error(_that.message);
      case _:
        return null;
    }
  }
}

/// @nodoc

class HadithLoading implements HadithState {
  const HadithLoading();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is HadithLoading);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'HadithState.loading()';
  }
}

/// @nodoc

class HadithReady implements HadithState {
  const HadithReady(
      {required this.packTitle,
      required this.language,
      required List<HadithItem> items,
      required this.offset,
      required this.hasMore})
      : _items = items;

  final String packTitle;
  final String language;
  final List<HadithItem> _items;
  List<HadithItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  final int offset;
  final bool hasMore;

  /// Create a copy of HadithState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $HadithReadyCopyWith<HadithReady> get copyWith =>
      _$HadithReadyCopyWithImpl<HadithReady>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is HadithReady &&
            (identical(other.packTitle, packTitle) ||
                other.packTitle == packTitle) &&
            (identical(other.language, language) ||
                other.language == language) &&
            const DeepCollectionEquality().equals(other.items, _items) &&
            (identical(other.offset, offset) || other.offset == offset) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, packTitle, language,
        const DeepCollectionEquality().hash(_items), offset, hasMore);
  }

  @override
  String toString() {
    return 'HadithState.ready(packTitle: $packTitle, language: $language, items: $items, offset: $offset, hasMore: $hasMore)';
  }
}

/// @nodoc
abstract mixin class $HadithReadyCopyWith<$Res>
    implements $HadithStateCopyWith<$Res> {
  factory $HadithReadyCopyWith(
          HadithReady value, $Res Function(HadithReady) _then) =
      _$HadithReadyCopyWithImpl;
  @useResult
  $Res call(
      {String packTitle,
      String language,
      List<HadithItem> items,
      int offset,
      bool hasMore});
}

/// @nodoc
class _$HadithReadyCopyWithImpl<$Res> implements $HadithReadyCopyWith<$Res> {
  _$HadithReadyCopyWithImpl(this._self, this._then);

  final HadithReady _self;
  final $Res Function(HadithReady) _then;

  /// Create a copy of HadithState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? packTitle = null,
    Object? language = null,
    Object? items = null,
    Object? offset = null,
    Object? hasMore = null,
  }) {
    return _then(HadithReady(
      packTitle: null == packTitle
          ? _self.packTitle
          : packTitle // ignore: cast_nullable_to_non_nullable
              as String,
      language: null == language
          ? _self.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      items: null == items
          ? _self._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<HadithItem>,
      offset: null == offset
          ? _self.offset
          : offset // ignore: cast_nullable_to_non_nullable
              as int,
      hasMore: null == hasMore
          ? _self.hasMore
          : hasMore // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class HadithError implements HadithState {
  const HadithError({required this.message});

  final String message;

  /// Create a copy of HadithState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $HadithErrorCopyWith<HadithError> get copyWith =>
      _$HadithErrorCopyWithImpl<HadithError>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is HadithError &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, message);
  }

  @override
  String toString() {
    return 'HadithState.error(message: $message)';
  }
}

/// @nodoc
abstract mixin class $HadithErrorCopyWith<$Res>
    implements $HadithStateCopyWith<$Res> {
  factory $HadithErrorCopyWith(
          HadithError value, $Res Function(HadithError) _then) =
      _$HadithErrorCopyWithImpl;
  @useResult
  $Res call({String message});
}

/// @nodoc
class _$HadithErrorCopyWithImpl<$Res> implements $HadithErrorCopyWith<$Res> {
  _$HadithErrorCopyWithImpl(this._self, this._then);

  final HadithError _self;
  final $Res Function(HadithError) _then;

  /// Create a copy of HadithState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? message = null,
  }) {
    return _then(HadithError(
      message: null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on

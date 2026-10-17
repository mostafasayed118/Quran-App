// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'downloads_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DownloadItem {
  DownloadStatus get status;
  int get received;
  int get total;

  /// Create a copy of DownloadItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DownloadItemCopyWith<DownloadItem> get copyWith =>
      _$DownloadItemCopyWithImpl<DownloadItem>(
          this as DownloadItem, _$identity);

  @override
  bool operator ==(Object other) {
    final _this = this as DownloadItem;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DownloadItem &&
            (identical(other.status, _this.status) ||
                other.status == _this.status) &&
            (identical(other.received, _this.received) ||
                other.received == _this.received) &&
            (identical(other.total, _this.total) ||
                other.total == _this.total));
  }

  @override
  int get hashCode {
    final _this = this as DownloadItem;
    return Object.hash(runtimeType, _this.status, _this.received, _this.total);
  }

  @override
  String toString() {
    final _this = this as DownloadItem;
    return 'DownloadItem(status: ${_this.status}, received: ${_this.received}, total: ${_this.total})';
  }
}

/// @nodoc
abstract mixin class $DownloadItemCopyWith<$Res> {
  factory $DownloadItemCopyWith(
          DownloadItem value, $Res Function(DownloadItem) _then) =
      _$DownloadItemCopyWithImpl;
  @useResult
  $Res call({DownloadStatus status, int received, int total});
}

/// @nodoc
class _$DownloadItemCopyWithImpl<$Res> implements $DownloadItemCopyWith<$Res> {
  _$DownloadItemCopyWithImpl(this._self, this._then);

  final DownloadItem _self;
  final $Res Function(DownloadItem) _then;

  /// Create a copy of DownloadItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? received = null,
    Object? total = null,
  }) {
    return _then(DownloadItem(
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as DownloadStatus,
      received: null == received
          ? _self.received
          : received // ignore: cast_nullable_to_non_nullable
              as int,
      total: null == total
          ? _self.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [DownloadItem].
extension DownloadItemPatterns on DownloadItem {
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
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_DownloadItem value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DownloadItem() when $default != null:
        return $default(_that);
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
  TResult map<TResult extends Object?>(
    TResult Function(_DownloadItem value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DownloadItem():
        return $default(_that);
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
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_DownloadItem value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DownloadItem() when $default != null:
        return $default(_that);
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
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(DownloadStatus status, int received, int total)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DownloadItem() when $default != null:
        return $default(_that.status, _that.received, _that.total);
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
  TResult when<TResult extends Object?>(
    TResult Function(DownloadStatus status, int received, int total) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DownloadItem():
        return $default(_that.status, _that.received, _that.total);
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
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(DownloadStatus status, int received, int total)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DownloadItem() when $default != null:
        return $default(_that.status, _that.received, _that.total);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _DownloadItem implements DownloadItem {
  const _DownloadItem(
      {this.status = DownloadStatus.queued, this.received = 0, this.total = 0});

  @override
  @JsonKey()
  final DownloadStatus status;
  @override
  @JsonKey()
  final int received;
  @override
  @JsonKey()
  final int total;

  /// Create a copy of DownloadItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$DownloadItemCopyWith<_DownloadItem> get copyWith =>
      __$DownloadItemCopyWithImpl<_DownloadItem>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _DownloadItem &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.received, received) ||
                other.received == received) &&
            (identical(other.total, total) || other.total == total));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, status, received, total);
  }

  @override
  String toString() {
    return 'DownloadItem(status: $status, received: $received, total: $total)';
  }
}

/// @nodoc
abstract mixin class _$DownloadItemCopyWith<$Res>
    implements $DownloadItemCopyWith<$Res> {
  factory _$DownloadItemCopyWith(
          _DownloadItem value, $Res Function(_DownloadItem) _then) =
      __$DownloadItemCopyWithImpl;
  @override
  @useResult
  $Res call({DownloadStatus status, int received, int total});
}

/// @nodoc
class __$DownloadItemCopyWithImpl<$Res>
    implements _$DownloadItemCopyWith<$Res> {
  __$DownloadItemCopyWithImpl(this._self, this._then);

  final _DownloadItem _self;
  final $Res Function(_DownloadItem) _then;

  /// Create a copy of DownloadItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? status = null,
    Object? received = null,
    Object? total = null,
  }) {
    return _then(_DownloadItem(
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as DownloadStatus,
      received: null == received
          ? _self.received
          : received // ignore: cast_nullable_to_non_nullable
              as int,
      total: null == total
          ? _self.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
mixin _$DownloadsState {
  Map<String, DownloadItem> get items;

  /// Create a copy of DownloadsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DownloadsStateCopyWith<DownloadsState> get copyWith =>
      _$DownloadsStateCopyWithImpl<DownloadsState>(
          this as DownloadsState, _$identity);

  @override
  bool operator ==(Object other) {
    final _this = this as DownloadsState;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DownloadsState &&
            const DeepCollectionEquality().equals(other.items, _this.items));
  }

  @override
  int get hashCode {
    final _this = this as DownloadsState;
    return Object.hash(
        runtimeType, const DeepCollectionEquality().hash(_this.items));
  }

  @override
  String toString() {
    final _this = this as DownloadsState;
    return 'DownloadsState(items: ${_this.items})';
  }
}

/// @nodoc
abstract mixin class $DownloadsStateCopyWith<$Res> {
  factory $DownloadsStateCopyWith(
          DownloadsState value, $Res Function(DownloadsState) _then) =
      _$DownloadsStateCopyWithImpl;
  @useResult
  $Res call({Map<String, DownloadItem> items});
}

/// @nodoc
class _$DownloadsStateCopyWithImpl<$Res>
    implements $DownloadsStateCopyWith<$Res> {
  _$DownloadsStateCopyWithImpl(this._self, this._then);

  final DownloadsState _self;
  final $Res Function(DownloadsState) _then;

  /// Create a copy of DownloadsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
  }) {
    return _then(DownloadsState(
      items: null == items
          ? _self.items
          : items // ignore: cast_nullable_to_non_nullable
              as Map<String, DownloadItem>,
    ));
  }
}

/// Adds pattern-matching-related methods to [DownloadsState].
extension DownloadsStatePatterns on DownloadsState {
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
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_DownloadsState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DownloadsState() when $default != null:
        return $default(_that);
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
  TResult map<TResult extends Object?>(
    TResult Function(_DownloadsState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DownloadsState():
        return $default(_that);
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
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_DownloadsState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DownloadsState() when $default != null:
        return $default(_that);
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
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(Map<String, DownloadItem> items)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DownloadsState() when $default != null:
        return $default(_that.items);
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
  TResult when<TResult extends Object?>(
    TResult Function(Map<String, DownloadItem> items) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DownloadsState():
        return $default(_that.items);
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
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(Map<String, DownloadItem> items)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DownloadsState() when $default != null:
        return $default(_that.items);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _DownloadsState implements DownloadsState {
  const _DownloadsState(
      {Map<String, DownloadItem> items = const <String, DownloadItem>{}})
      : _items = items;

  final Map<String, DownloadItem> _items;
  @override
  @JsonKey()
  Map<String, DownloadItem> get items {
    if (_items is EqualUnmodifiableMapView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_items);
  }

  /// Create a copy of DownloadsState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$DownloadsStateCopyWith<_DownloadsState> get copyWith =>
      __$DownloadsStateCopyWithImpl<_DownloadsState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _DownloadsState &&
            const DeepCollectionEquality().equals(other.items, _items));
  }

  @override
  int get hashCode {
    return Object.hash(
        runtimeType, const DeepCollectionEquality().hash(_items));
  }

  @override
  String toString() {
    return 'DownloadsState(items: $items)';
  }
}

/// @nodoc
abstract mixin class _$DownloadsStateCopyWith<$Res>
    implements $DownloadsStateCopyWith<$Res> {
  factory _$DownloadsStateCopyWith(
          _DownloadsState value, $Res Function(_DownloadsState) _then) =
      __$DownloadsStateCopyWithImpl;
  @override
  @useResult
  $Res call({Map<String, DownloadItem> items});
}

/// @nodoc
class __$DownloadsStateCopyWithImpl<$Res>
    implements _$DownloadsStateCopyWith<$Res> {
  __$DownloadsStateCopyWithImpl(this._self, this._then);

  final _DownloadsState _self;
  final $Res Function(_DownloadsState) _then;

  /// Create a copy of DownloadsState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? items = null,
  }) {
    return _then(_DownloadsState(
      items: null == items
          ? _self._items
          : items // ignore: cast_nullable_to_non_nullable
              as Map<String, DownloadItem>,
    ));
  }
}

// dart format on

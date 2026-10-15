// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'azkar_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AzkarState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is AzkarState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'AzkarState()';
  }
}

/// @nodoc
class $AzkarStateCopyWith<$Res> {
  $AzkarStateCopyWith(AzkarState _, $Res Function(AzkarState) __);
}

/// Adds pattern-matching-related methods to [AzkarState].
extension AzkarStatePatterns on AzkarState {
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
    TResult Function(AzkarLoading value)? loading,
    TResult Function(AzkarBrowsing value)? browsing,
    TResult Function(AzkarReciting value)? reciting,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case AzkarLoading() when loading != null:
        return loading(_that);
      case AzkarBrowsing() when browsing != null:
        return browsing(_that);
      case AzkarReciting() when reciting != null:
        return reciting(_that);
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
    required TResult Function(AzkarLoading value) loading,
    required TResult Function(AzkarBrowsing value) browsing,
    required TResult Function(AzkarReciting value) reciting,
  }) {
    final _that = this;
    switch (_that) {
      case AzkarLoading():
        return loading(_that);
      case AzkarBrowsing():
        return browsing(_that);
      case AzkarReciting():
        return reciting(_that);
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
    TResult? Function(AzkarLoading value)? loading,
    TResult? Function(AzkarBrowsing value)? browsing,
    TResult? Function(AzkarReciting value)? reciting,
  }) {
    final _that = this;
    switch (_that) {
      case AzkarLoading() when loading != null:
        return loading(_that);
      case AzkarBrowsing() when browsing != null:
        return browsing(_that);
      case AzkarReciting() when reciting != null:
        return reciting(_that);
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
    TResult Function(List<AzkarCollection> collections)? browsing,
    TResult Function(AzkarCollection collection, List<int> remaining)? reciting,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case AzkarLoading() when loading != null:
        return loading();
      case AzkarBrowsing() when browsing != null:
        return browsing(_that.collections);
      case AzkarReciting() when reciting != null:
        return reciting(_that.collection, _that.remaining);
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
    required TResult Function(List<AzkarCollection> collections) browsing,
    required TResult Function(AzkarCollection collection, List<int> remaining)
        reciting,
  }) {
    final _that = this;
    switch (_that) {
      case AzkarLoading():
        return loading();
      case AzkarBrowsing():
        return browsing(_that.collections);
      case AzkarReciting():
        return reciting(_that.collection, _that.remaining);
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
    TResult? Function(List<AzkarCollection> collections)? browsing,
    TResult? Function(AzkarCollection collection, List<int> remaining)?
        reciting,
  }) {
    final _that = this;
    switch (_that) {
      case AzkarLoading() when loading != null:
        return loading();
      case AzkarBrowsing() when browsing != null:
        return browsing(_that.collections);
      case AzkarReciting() when reciting != null:
        return reciting(_that.collection, _that.remaining);
      case _:
        return null;
    }
  }
}

/// @nodoc

class AzkarLoading implements AzkarState {
  const AzkarLoading();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is AzkarLoading);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'AzkarState.loading()';
  }
}

/// @nodoc

class AzkarBrowsing implements AzkarState {
  const AzkarBrowsing(
      {List<AzkarCollection> collections = const <AzkarCollection>[]})
      : _collections = collections;

  final List<AzkarCollection> _collections;
  @JsonKey()
  List<AzkarCollection> get collections {
    if (_collections is EqualUnmodifiableListView) return _collections;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_collections);
  }

  /// Create a copy of AzkarState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AzkarBrowsingCopyWith<AzkarBrowsing> get copyWith =>
      _$AzkarBrowsingCopyWithImpl<AzkarBrowsing>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AzkarBrowsing &&
            const DeepCollectionEquality()
                .equals(other.collections, _collections));
  }

  @override
  int get hashCode {
    return Object.hash(
        runtimeType, const DeepCollectionEquality().hash(_collections));
  }

  @override
  String toString() {
    return 'AzkarState.browsing(collections: $collections)';
  }
}

/// @nodoc
abstract mixin class $AzkarBrowsingCopyWith<$Res>
    implements $AzkarStateCopyWith<$Res> {
  factory $AzkarBrowsingCopyWith(
          AzkarBrowsing value, $Res Function(AzkarBrowsing) _then) =
      _$AzkarBrowsingCopyWithImpl;
  @useResult
  $Res call({List<AzkarCollection> collections});
}

/// @nodoc
class _$AzkarBrowsingCopyWithImpl<$Res>
    implements $AzkarBrowsingCopyWith<$Res> {
  _$AzkarBrowsingCopyWithImpl(this._self, this._then);

  final AzkarBrowsing _self;
  final $Res Function(AzkarBrowsing) _then;

  /// Create a copy of AzkarState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? collections = null,
  }) {
    return _then(AzkarBrowsing(
      collections: null == collections
          ? _self._collections
          : collections // ignore: cast_nullable_to_non_nullable
              as List<AzkarCollection>,
    ));
  }
}

/// @nodoc

class AzkarReciting implements AzkarState {
  const AzkarReciting(
      {required this.collection, List<int> remaining = const <int>[]})
      : _remaining = remaining;

  final AzkarCollection collection;
  final List<int> _remaining;
  @JsonKey()
  List<int> get remaining {
    if (_remaining is EqualUnmodifiableListView) return _remaining;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_remaining);
  }

  /// Create a copy of AzkarState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AzkarRecitingCopyWith<AzkarReciting> get copyWith =>
      _$AzkarRecitingCopyWithImpl<AzkarReciting>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AzkarReciting &&
            (identical(other.collection, collection) ||
                other.collection == collection) &&
            const DeepCollectionEquality().equals(other.remaining, _remaining));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, collection,
        const DeepCollectionEquality().hash(_remaining));
  }

  @override
  String toString() {
    return 'AzkarState.reciting(collection: $collection, remaining: $remaining)';
  }
}

/// @nodoc
abstract mixin class $AzkarRecitingCopyWith<$Res>
    implements $AzkarStateCopyWith<$Res> {
  factory $AzkarRecitingCopyWith(
          AzkarReciting value, $Res Function(AzkarReciting) _then) =
      _$AzkarRecitingCopyWithImpl;
  @useResult
  $Res call({AzkarCollection collection, List<int> remaining});
}

/// @nodoc
class _$AzkarRecitingCopyWithImpl<$Res>
    implements $AzkarRecitingCopyWith<$Res> {
  _$AzkarRecitingCopyWithImpl(this._self, this._then);

  final AzkarReciting _self;
  final $Res Function(AzkarReciting) _then;

  /// Create a copy of AzkarState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? collection = null,
    Object? remaining = null,
  }) {
    return _then(AzkarReciting(
      collection: null == collection
          ? _self.collection
          : collection // ignore: cast_nullable_to_non_nullable
              as AzkarCollection,
      remaining: null == remaining
          ? _self._remaining
          : remaining // ignore: cast_nullable_to_non_nullable
              as List<int>,
    ));
  }
}

// dart format on

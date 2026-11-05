// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'translation_search_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TranslationSearchState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is TranslationSearchState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'TranslationSearchState()';
  }
}

/// @nodoc
class $TranslationSearchStateCopyWith<$Res> {
  $TranslationSearchStateCopyWith(
      TranslationSearchState _, $Res Function(TranslationSearchState) __);
}

/// Adds pattern-matching-related methods to [TranslationSearchState].
extension TranslationSearchStatePatterns on TranslationSearchState {
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
    TResult Function(TranslationSearchLoading value)? loading,
    TResult Function(TranslationSearchFailed value)? failed,
    TResult Function(TranslationSearchReady value)? ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case TranslationSearchLoading() when loading != null:
        return loading(_that);
      case TranslationSearchFailed() when failed != null:
        return failed(_that);
      case TranslationSearchReady() when ready != null:
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
    required TResult Function(TranslationSearchLoading value) loading,
    required TResult Function(TranslationSearchFailed value) failed,
    required TResult Function(TranslationSearchReady value) ready,
  }) {
    final _that = this;
    switch (_that) {
      case TranslationSearchLoading():
        return loading(_that);
      case TranslationSearchFailed():
        return failed(_that);
      case TranslationSearchReady():
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
    TResult? Function(TranslationSearchLoading value)? loading,
    TResult? Function(TranslationSearchFailed value)? failed,
    TResult? Function(TranslationSearchReady value)? ready,
  }) {
    final _that = this;
    switch (_that) {
      case TranslationSearchLoading() when loading != null:
        return loading(_that);
      case TranslationSearchFailed() when failed != null:
        return failed(_that);
      case TranslationSearchReady() when ready != null:
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
    TResult Function(
            bool hasPacks, String query, List<TranslationHit> hits, int total)?
        ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case TranslationSearchLoading() when loading != null:
        return loading();
      case TranslationSearchFailed() when failed != null:
        return failed();
      case TranslationSearchReady() when ready != null:
        return ready(_that.hasPacks, _that.query, _that.hits, _that.total);
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
            bool hasPacks, String query, List<TranslationHit> hits, int total)
        ready,
  }) {
    final _that = this;
    switch (_that) {
      case TranslationSearchLoading():
        return loading();
      case TranslationSearchFailed():
        return failed();
      case TranslationSearchReady():
        return ready(_that.hasPacks, _that.query, _that.hits, _that.total);
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
            bool hasPacks, String query, List<TranslationHit> hits, int total)?
        ready,
  }) {
    final _that = this;
    switch (_that) {
      case TranslationSearchLoading() when loading != null:
        return loading();
      case TranslationSearchFailed() when failed != null:
        return failed();
      case TranslationSearchReady() when ready != null:
        return ready(_that.hasPacks, _that.query, _that.hits, _that.total);
      case _:
        return null;
    }
  }
}

/// @nodoc

class TranslationSearchLoading implements TranslationSearchState {
  const TranslationSearchLoading();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is TranslationSearchLoading);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'TranslationSearchState.loading()';
  }
}

/// @nodoc

class TranslationSearchFailed implements TranslationSearchState {
  const TranslationSearchFailed();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is TranslationSearchFailed);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'TranslationSearchState.failed()';
  }
}

/// @nodoc

class TranslationSearchReady implements TranslationSearchState {
  const TranslationSearchReady(
      {this.hasPacks = false,
      this.query = '',
      List<TranslationHit> hits = const <TranslationHit>[],
      this.total = 0})
      : _hits = hits;

  @JsonKey()
  final bool hasPacks;
  @JsonKey()
  final String query;
  final List<TranslationHit> _hits;
  @JsonKey()
  List<TranslationHit> get hits {
    if (_hits is EqualUnmodifiableListView) return _hits;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_hits);
  }

  @JsonKey()
  final int total;

  /// Create a copy of TranslationSearchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TranslationSearchReadyCopyWith<TranslationSearchReady> get copyWith =>
      _$TranslationSearchReadyCopyWithImpl<TranslationSearchReady>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TranslationSearchReady &&
            (identical(other.hasPacks, hasPacks) ||
                other.hasPacks == hasPacks) &&
            (identical(other.query, query) || other.query == query) &&
            const DeepCollectionEquality().equals(other.hits, _hits) &&
            (identical(other.total, total) || other.total == total));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, hasPacks, query,
        const DeepCollectionEquality().hash(_hits), total);
  }

  @override
  String toString() {
    return 'TranslationSearchState.ready(hasPacks: $hasPacks, query: $query, hits: $hits, total: $total)';
  }
}

/// @nodoc
abstract mixin class $TranslationSearchReadyCopyWith<$Res>
    implements $TranslationSearchStateCopyWith<$Res> {
  factory $TranslationSearchReadyCopyWith(TranslationSearchReady value,
          $Res Function(TranslationSearchReady) _then) =
      _$TranslationSearchReadyCopyWithImpl;
  @useResult
  $Res call(
      {bool hasPacks, String query, List<TranslationHit> hits, int total});
}

/// @nodoc
class _$TranslationSearchReadyCopyWithImpl<$Res>
    implements $TranslationSearchReadyCopyWith<$Res> {
  _$TranslationSearchReadyCopyWithImpl(this._self, this._then);

  final TranslationSearchReady _self;
  final $Res Function(TranslationSearchReady) _then;

  /// Create a copy of TranslationSearchState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? hasPacks = null,
    Object? query = null,
    Object? hits = null,
    Object? total = null,
  }) {
    return _then(TranslationSearchReady(
      hasPacks: null == hasPacks
          ? _self.hasPacks
          : hasPacks // ignore: cast_nullable_to_non_nullable
              as bool,
      query: null == query
          ? _self.query
          : query // ignore: cast_nullable_to_non_nullable
              as String,
      hits: null == hits
          ? _self._hits
          : hits // ignore: cast_nullable_to_non_nullable
              as List<TranslationHit>,
      total: null == total
          ? _self.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on

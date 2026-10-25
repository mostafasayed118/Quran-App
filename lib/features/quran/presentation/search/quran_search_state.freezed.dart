// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quran_search_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$QuranSearchState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is QuranSearchState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'QuranSearchState()';
  }
}

/// @nodoc
class $QuranSearchStateCopyWith<$Res> {
  $QuranSearchStateCopyWith(
      QuranSearchState _, $Res Function(QuranSearchState) __);
}

/// Adds pattern-matching-related methods to [QuranSearchState].
extension QuranSearchStatePatterns on QuranSearchState {
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
    TResult Function(QuranSearchLoading value)? loading,
    TResult Function(QuranSearchReady value)? ready,
    TResult Function(QuranSearchFailed value)? failed,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case QuranSearchLoading() when loading != null:
        return loading(_that);
      case QuranSearchReady() when ready != null:
        return ready(_that);
      case QuranSearchFailed() when failed != null:
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
    required TResult Function(QuranSearchLoading value) loading,
    required TResult Function(QuranSearchReady value) ready,
    required TResult Function(QuranSearchFailed value) failed,
  }) {
    final _that = this;
    switch (_that) {
      case QuranSearchLoading():
        return loading(_that);
      case QuranSearchReady():
        return ready(_that);
      case QuranSearchFailed():
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
    TResult? Function(QuranSearchLoading value)? loading,
    TResult? Function(QuranSearchReady value)? ready,
    TResult? Function(QuranSearchFailed value)? failed,
  }) {
    final _that = this;
    switch (_that) {
      case QuranSearchLoading() when loading != null:
        return loading(_that);
      case QuranSearchReady() when ready != null:
        return ready(_that);
      case QuranSearchFailed() when failed != null:
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
    TResult Function(String query, List<QuranSearchHit> hits, int total,
            bool hasMore, bool loadingMore, bool moreFailed)?
        ready,
    TResult Function()? failed,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case QuranSearchLoading() when loading != null:
        return loading();
      case QuranSearchReady() when ready != null:
        return ready(_that.query, _that.hits, _that.total, _that.hasMore,
            _that.loadingMore, _that.moreFailed);
      case QuranSearchFailed() when failed != null:
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
    required TResult Function(String query, List<QuranSearchHit> hits,
            int total, bool hasMore, bool loadingMore, bool moreFailed)
        ready,
    required TResult Function() failed,
  }) {
    final _that = this;
    switch (_that) {
      case QuranSearchLoading():
        return loading();
      case QuranSearchReady():
        return ready(_that.query, _that.hits, _that.total, _that.hasMore,
            _that.loadingMore, _that.moreFailed);
      case QuranSearchFailed():
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
    TResult? Function(String query, List<QuranSearchHit> hits, int total,
            bool hasMore, bool loadingMore, bool moreFailed)?
        ready,
    TResult? Function()? failed,
  }) {
    final _that = this;
    switch (_that) {
      case QuranSearchLoading() when loading != null:
        return loading();
      case QuranSearchReady() when ready != null:
        return ready(_that.query, _that.hits, _that.total, _that.hasMore,
            _that.loadingMore, _that.moreFailed);
      case QuranSearchFailed() when failed != null:
        return failed();
      case _:
        return null;
    }
  }
}

/// @nodoc

class QuranSearchLoading implements QuranSearchState {
  const QuranSearchLoading();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is QuranSearchLoading);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'QuranSearchState.loading()';
  }
}

/// @nodoc

class QuranSearchReady implements QuranSearchState {
  const QuranSearchReady(
      {required this.query,
      required List<QuranSearchHit> hits,
      required this.total,
      required this.hasMore,
      this.loadingMore = false,
      this.moreFailed = false})
      : _hits = hits;

  final String query;
  final List<QuranSearchHit> _hits;
  List<QuranSearchHit> get hits {
    if (_hits is EqualUnmodifiableListView) return _hits;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_hits);
  }

  final int total;
  final bool hasMore;
  @JsonKey()
  final bool loadingMore;
  @JsonKey()
  final bool moreFailed;

  /// Create a copy of QuranSearchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $QuranSearchReadyCopyWith<QuranSearchReady> get copyWith =>
      _$QuranSearchReadyCopyWithImpl<QuranSearchReady>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is QuranSearchReady &&
            (identical(other.query, query) || other.query == query) &&
            const DeepCollectionEquality().equals(other.hits, _hits) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore) &&
            (identical(other.loadingMore, loadingMore) ||
                other.loadingMore == loadingMore) &&
            (identical(other.moreFailed, moreFailed) ||
                other.moreFailed == moreFailed));
  }

  @override
  int get hashCode {
    return Object.hash(
        runtimeType,
        query,
        const DeepCollectionEquality().hash(_hits),
        total,
        hasMore,
        loadingMore,
        moreFailed);
  }

  @override
  String toString() {
    return 'QuranSearchState.ready(query: $query, hits: $hits, total: $total, hasMore: $hasMore, loadingMore: $loadingMore, moreFailed: $moreFailed)';
  }
}

/// @nodoc
abstract mixin class $QuranSearchReadyCopyWith<$Res>
    implements $QuranSearchStateCopyWith<$Res> {
  factory $QuranSearchReadyCopyWith(
          QuranSearchReady value, $Res Function(QuranSearchReady) _then) =
      _$QuranSearchReadyCopyWithImpl;
  @useResult
  $Res call(
      {String query,
      List<QuranSearchHit> hits,
      int total,
      bool hasMore,
      bool loadingMore,
      bool moreFailed});
}

/// @nodoc
class _$QuranSearchReadyCopyWithImpl<$Res>
    implements $QuranSearchReadyCopyWith<$Res> {
  _$QuranSearchReadyCopyWithImpl(this._self, this._then);

  final QuranSearchReady _self;
  final $Res Function(QuranSearchReady) _then;

  /// Create a copy of QuranSearchState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? query = null,
    Object? hits = null,
    Object? total = null,
    Object? hasMore = null,
    Object? loadingMore = null,
    Object? moreFailed = null,
  }) {
    return _then(QuranSearchReady(
      query: null == query
          ? _self.query
          : query // ignore: cast_nullable_to_non_nullable
              as String,
      hits: null == hits
          ? _self._hits
          : hits // ignore: cast_nullable_to_non_nullable
              as List<QuranSearchHit>,
      total: null == total
          ? _self.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      hasMore: null == hasMore
          ? _self.hasMore
          : hasMore // ignore: cast_nullable_to_non_nullable
              as bool,
      loadingMore: null == loadingMore
          ? _self.loadingMore
          : loadingMore // ignore: cast_nullable_to_non_nullable
              as bool,
      moreFailed: null == moreFailed
          ? _self.moreFailed
          : moreFailed // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class QuranSearchFailed implements QuranSearchState {
  const QuranSearchFailed();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is QuranSearchFailed);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'QuranSearchState.failed()';
  }
}

// dart format on

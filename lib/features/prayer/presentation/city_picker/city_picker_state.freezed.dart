// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'city_picker_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CityPickerState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is CityPickerState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'CityPickerState()';
  }
}

/// @nodoc
class $CityPickerStateCopyWith<$Res> {
  $CityPickerStateCopyWith(
      CityPickerState _, $Res Function(CityPickerState) __);
}

/// Adds pattern-matching-related methods to [CityPickerState].
extension CityPickerStatePatterns on CityPickerState {
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
    TResult Function(CityPickerLoading value)? loading,
    TResult Function(CityPickerReady value)? ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case CityPickerLoading() when loading != null:
        return loading(_that);
      case CityPickerReady() when ready != null:
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
    required TResult Function(CityPickerLoading value) loading,
    required TResult Function(CityPickerReady value) ready,
  }) {
    final _that = this;
    switch (_that) {
      case CityPickerLoading():
        return loading(_that);
      case CityPickerReady():
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
    TResult? Function(CityPickerLoading value)? loading,
    TResult? Function(CityPickerReady value)? ready,
  }) {
    final _that = this;
    switch (_that) {
      case CityPickerLoading() when loading != null:
        return loading(_that);
      case CityPickerReady() when ready != null:
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
    TResult Function(String query, List<City> results, bool locating)? ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case CityPickerLoading() when loading != null:
        return loading();
      case CityPickerReady() when ready != null:
        return ready(_that.query, _that.results, _that.locating);
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
    required TResult Function(String query, List<City> results, bool locating)
        ready,
  }) {
    final _that = this;
    switch (_that) {
      case CityPickerLoading():
        return loading();
      case CityPickerReady():
        return ready(_that.query, _that.results, _that.locating);
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
    TResult? Function(String query, List<City> results, bool locating)? ready,
  }) {
    final _that = this;
    switch (_that) {
      case CityPickerLoading() when loading != null:
        return loading();
      case CityPickerReady() when ready != null:
        return ready(_that.query, _that.results, _that.locating);
      case _:
        return null;
    }
  }
}

/// @nodoc

class CityPickerLoading implements CityPickerState {
  const CityPickerLoading();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is CityPickerLoading);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'CityPickerState.loading()';
  }
}

/// @nodoc

class CityPickerReady implements CityPickerState {
  const CityPickerReady(
      {this.query = '',
      List<City> results = const <City>[],
      this.locating = false})
      : _results = results;

  @JsonKey()
  final String query;
  final List<City> _results;
  @JsonKey()
  List<City> get results {
    if (_results is EqualUnmodifiableListView) return _results;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_results);
  }

  @JsonKey()
  final bool locating;

  /// Create a copy of CityPickerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CityPickerReadyCopyWith<CityPickerReady> get copyWith =>
      _$CityPickerReadyCopyWithImpl<CityPickerReady>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CityPickerReady &&
            (identical(other.query, query) || other.query == query) &&
            const DeepCollectionEquality().equals(other.results, _results) &&
            (identical(other.locating, locating) ||
                other.locating == locating));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, query,
        const DeepCollectionEquality().hash(_results), locating);
  }

  @override
  String toString() {
    return 'CityPickerState.ready(query: $query, results: $results, locating: $locating)';
  }
}

/// @nodoc
abstract mixin class $CityPickerReadyCopyWith<$Res>
    implements $CityPickerStateCopyWith<$Res> {
  factory $CityPickerReadyCopyWith(
          CityPickerReady value, $Res Function(CityPickerReady) _then) =
      _$CityPickerReadyCopyWithImpl;
  @useResult
  $Res call({String query, List<City> results, bool locating});
}

/// @nodoc
class _$CityPickerReadyCopyWithImpl<$Res>
    implements $CityPickerReadyCopyWith<$Res> {
  _$CityPickerReadyCopyWithImpl(this._self, this._then);

  final CityPickerReady _self;
  final $Res Function(CityPickerReady) _then;

  /// Create a copy of CityPickerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? query = null,
    Object? results = null,
    Object? locating = null,
  }) {
    return _then(CityPickerReady(
      query: null == query
          ? _self.query
          : query // ignore: cast_nullable_to_non_nullable
              as String,
      results: null == results
          ? _self._results
          : results // ignore: cast_nullable_to_non_nullable
              as List<City>,
      locating: null == locating
          ? _self.locating
          : locating // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on

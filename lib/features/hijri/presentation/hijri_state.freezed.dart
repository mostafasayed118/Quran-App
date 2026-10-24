// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hijri_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HijriState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is HijriState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'HijriState()';
  }
}

/// @nodoc
class $HijriStateCopyWith<$Res> {
  $HijriStateCopyWith(HijriState _, $Res Function(HijriState) __);
}

/// Adds pattern-matching-related methods to [HijriState].
extension HijriStatePatterns on HijriState {
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
    TResult Function(HijriLoading value)? loading,
    TResult Function(HijriFailed value)? failed,
    TResult Function(HijriReady value)? ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case HijriLoading() when loading != null:
        return loading(_that);
      case HijriFailed() when failed != null:
        return failed(_that);
      case HijriReady() when ready != null:
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
    required TResult Function(HijriLoading value) loading,
    required TResult Function(HijriFailed value) failed,
    required TResult Function(HijriReady value) ready,
  }) {
    final _that = this;
    switch (_that) {
      case HijriLoading():
        return loading(_that);
      case HijriFailed():
        return failed(_that);
      case HijriReady():
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
    TResult? Function(HijriLoading value)? loading,
    TResult? Function(HijriFailed value)? failed,
    TResult? Function(HijriReady value)? ready,
  }) {
    final _that = this;
    switch (_that) {
      case HijriLoading() when loading != null:
        return loading(_that);
      case HijriFailed() when failed != null:
        return failed(_that);
      case HijriReady() when ready != null:
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
    TResult Function(int month, int year, String monthName, int offset,
            List<HijriCell> cells, String todayHeader)?
        ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case HijriLoading() when loading != null:
        return loading();
      case HijriFailed() when failed != null:
        return failed();
      case HijriReady() when ready != null:
        return ready(_that.month, _that.year, _that.monthName, _that.offset,
            _that.cells, _that.todayHeader);
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
    required TResult Function(int month, int year, String monthName, int offset,
            List<HijriCell> cells, String todayHeader)
        ready,
  }) {
    final _that = this;
    switch (_that) {
      case HijriLoading():
        return loading();
      case HijriFailed():
        return failed();
      case HijriReady():
        return ready(_that.month, _that.year, _that.monthName, _that.offset,
            _that.cells, _that.todayHeader);
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
    TResult? Function(int month, int year, String monthName, int offset,
            List<HijriCell> cells, String todayHeader)?
        ready,
  }) {
    final _that = this;
    switch (_that) {
      case HijriLoading() when loading != null:
        return loading();
      case HijriFailed() when failed != null:
        return failed();
      case HijriReady() when ready != null:
        return ready(_that.month, _that.year, _that.monthName, _that.offset,
            _that.cells, _that.todayHeader);
      case _:
        return null;
    }
  }
}

/// @nodoc

class HijriLoading implements HijriState {
  const HijriLoading();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is HijriLoading);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'HijriState.loading()';
  }
}

/// @nodoc

class HijriFailed implements HijriState {
  const HijriFailed();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is HijriFailed);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'HijriState.failed()';
  }
}

/// @nodoc

class HijriReady implements HijriState {
  const HijriReady(
      {required this.month,
      required this.year,
      required this.monthName,
      required this.offset,
      required List<HijriCell> cells,
      required this.todayHeader})
      : _cells = cells;

  final int month;
  final int year;
  final String monthName;
  final int offset;
  final List<HijriCell> _cells;
  List<HijriCell> get cells {
    if (_cells is EqualUnmodifiableListView) return _cells;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_cells);
  }

  final String todayHeader;

  /// Create a copy of HijriState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $HijriReadyCopyWith<HijriReady> get copyWith =>
      _$HijriReadyCopyWithImpl<HijriReady>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is HijriReady &&
            (identical(other.month, month) || other.month == month) &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.monthName, monthName) ||
                other.monthName == monthName) &&
            (identical(other.offset, offset) || other.offset == offset) &&
            const DeepCollectionEquality().equals(other.cells, _cells) &&
            (identical(other.todayHeader, todayHeader) ||
                other.todayHeader == todayHeader));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, month, year, monthName, offset,
        const DeepCollectionEquality().hash(_cells), todayHeader);
  }

  @override
  String toString() {
    return 'HijriState.ready(month: $month, year: $year, monthName: $monthName, offset: $offset, cells: $cells, todayHeader: $todayHeader)';
  }
}

/// @nodoc
abstract mixin class $HijriReadyCopyWith<$Res>
    implements $HijriStateCopyWith<$Res> {
  factory $HijriReadyCopyWith(
          HijriReady value, $Res Function(HijriReady) _then) =
      _$HijriReadyCopyWithImpl;
  @useResult
  $Res call(
      {int month,
      int year,
      String monthName,
      int offset,
      List<HijriCell> cells,
      String todayHeader});
}

/// @nodoc
class _$HijriReadyCopyWithImpl<$Res> implements $HijriReadyCopyWith<$Res> {
  _$HijriReadyCopyWithImpl(this._self, this._then);

  final HijriReady _self;
  final $Res Function(HijriReady) _then;

  /// Create a copy of HijriState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? month = null,
    Object? year = null,
    Object? monthName = null,
    Object? offset = null,
    Object? cells = null,
    Object? todayHeader = null,
  }) {
    return _then(HijriReady(
      month: null == month
          ? _self.month
          : month // ignore: cast_nullable_to_non_nullable
              as int,
      year: null == year
          ? _self.year
          : year // ignore: cast_nullable_to_non_nullable
              as int,
      monthName: null == monthName
          ? _self.monthName
          : monthName // ignore: cast_nullable_to_non_nullable
              as String,
      offset: null == offset
          ? _self.offset
          : offset // ignore: cast_nullable_to_non_nullable
              as int,
      cells: null == cells
          ? _self._cells
          : cells // ignore: cast_nullable_to_non_nullable
              as List<HijriCell>,
      todayHeader: null == todayHeader
          ? _self.todayHeader
          : todayHeader // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on

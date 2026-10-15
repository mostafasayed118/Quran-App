// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'zakat_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ZakatState {
  bool get nisabBySilver;
  String get goldGrams;
  String get silverGrams;
  String get goldPrice;
  String get silverPrice;
  String get cash;
  String get debts;
  ZakatResult get result;

  /// Create a copy of ZakatState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ZakatStateCopyWith<ZakatState> get copyWith =>
      _$ZakatStateCopyWithImpl<ZakatState>(this as ZakatState, _$identity);

  @override
  bool operator ==(Object other) {
    final _this = this as ZakatState;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ZakatState &&
            (identical(other.nisabBySilver, _this.nisabBySilver) ||
                other.nisabBySilver == _this.nisabBySilver) &&
            (identical(other.goldGrams, _this.goldGrams) ||
                other.goldGrams == _this.goldGrams) &&
            (identical(other.silverGrams, _this.silverGrams) ||
                other.silverGrams == _this.silverGrams) &&
            (identical(other.goldPrice, _this.goldPrice) ||
                other.goldPrice == _this.goldPrice) &&
            (identical(other.silverPrice, _this.silverPrice) ||
                other.silverPrice == _this.silverPrice) &&
            (identical(other.cash, _this.cash) || other.cash == _this.cash) &&
            (identical(other.debts, _this.debts) ||
                other.debts == _this.debts) &&
            (identical(other.result, _this.result) ||
                other.result == _this.result));
  }

  @override
  int get hashCode {
    final _this = this as ZakatState;
    return Object.hash(
        runtimeType,
        _this.nisabBySilver,
        _this.goldGrams,
        _this.silverGrams,
        _this.goldPrice,
        _this.silverPrice,
        _this.cash,
        _this.debts,
        _this.result);
  }

  @override
  String toString() {
    final _this = this as ZakatState;
    return 'ZakatState(nisabBySilver: ${_this.nisabBySilver}, goldGrams: ${_this.goldGrams}, silverGrams: ${_this.silverGrams}, goldPrice: ${_this.goldPrice}, silverPrice: ${_this.silverPrice}, cash: ${_this.cash}, debts: ${_this.debts}, result: ${_this.result})';
  }
}

/// @nodoc
abstract mixin class $ZakatStateCopyWith<$Res> {
  factory $ZakatStateCopyWith(
          ZakatState value, $Res Function(ZakatState) _then) =
      _$ZakatStateCopyWithImpl;
  @useResult
  $Res call(
      {bool nisabBySilver,
      String goldGrams,
      String silverGrams,
      String goldPrice,
      String silverPrice,
      String cash,
      String debts,
      ZakatResult result});
}

/// @nodoc
class _$ZakatStateCopyWithImpl<$Res> implements $ZakatStateCopyWith<$Res> {
  _$ZakatStateCopyWithImpl(this._self, this._then);

  final ZakatState _self;
  final $Res Function(ZakatState) _then;

  /// Create a copy of ZakatState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? nisabBySilver = null,
    Object? goldGrams = null,
    Object? silverGrams = null,
    Object? goldPrice = null,
    Object? silverPrice = null,
    Object? cash = null,
    Object? debts = null,
    Object? result = null,
  }) {
    return _then(ZakatState.ready(
      nisabBySilver: null == nisabBySilver
          ? _self.nisabBySilver
          : nisabBySilver // ignore: cast_nullable_to_non_nullable
              as bool,
      goldGrams: null == goldGrams
          ? _self.goldGrams
          : goldGrams // ignore: cast_nullable_to_non_nullable
              as String,
      silverGrams: null == silverGrams
          ? _self.silverGrams
          : silverGrams // ignore: cast_nullable_to_non_nullable
              as String,
      goldPrice: null == goldPrice
          ? _self.goldPrice
          : goldPrice // ignore: cast_nullable_to_non_nullable
              as String,
      silverPrice: null == silverPrice
          ? _self.silverPrice
          : silverPrice // ignore: cast_nullable_to_non_nullable
              as String,
      cash: null == cash
          ? _self.cash
          : cash // ignore: cast_nullable_to_non_nullable
              as String,
      debts: null == debts
          ? _self.debts
          : debts // ignore: cast_nullable_to_non_nullable
              as String,
      result: null == result
          ? _self.result
          : result // ignore: cast_nullable_to_non_nullable
              as ZakatResult,
    ));
  }
}

/// Adds pattern-matching-related methods to [ZakatState].
extension ZakatStatePatterns on ZakatState {
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
    TResult Function(ZakatReady value)? ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case ZakatReady() when ready != null:
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
    required TResult Function(ZakatReady value) ready,
  }) {
    final _that = this;
    switch (_that) {
      case ZakatReady():
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
    TResult? Function(ZakatReady value)? ready,
  }) {
    final _that = this;
    switch (_that) {
      case ZakatReady() when ready != null:
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
    TResult Function(
            bool nisabBySilver,
            String goldGrams,
            String silverGrams,
            String goldPrice,
            String silverPrice,
            String cash,
            String debts,
            ZakatResult result)?
        ready,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case ZakatReady() when ready != null:
        return ready(
            _that.nisabBySilver,
            _that.goldGrams,
            _that.silverGrams,
            _that.goldPrice,
            _that.silverPrice,
            _that.cash,
            _that.debts,
            _that.result);
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
    required TResult Function(
            bool nisabBySilver,
            String goldGrams,
            String silverGrams,
            String goldPrice,
            String silverPrice,
            String cash,
            String debts,
            ZakatResult result)
        ready,
  }) {
    final _that = this;
    switch (_that) {
      case ZakatReady():
        return ready(
            _that.nisabBySilver,
            _that.goldGrams,
            _that.silverGrams,
            _that.goldPrice,
            _that.silverPrice,
            _that.cash,
            _that.debts,
            _that.result);
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
    TResult? Function(
            bool nisabBySilver,
            String goldGrams,
            String silverGrams,
            String goldPrice,
            String silverPrice,
            String cash,
            String debts,
            ZakatResult result)?
        ready,
  }) {
    final _that = this;
    switch (_that) {
      case ZakatReady() when ready != null:
        return ready(
            _that.nisabBySilver,
            _that.goldGrams,
            _that.silverGrams,
            _that.goldPrice,
            _that.silverPrice,
            _that.cash,
            _that.debts,
            _that.result);
      case _:
        return null;
    }
  }
}

/// @nodoc

class ZakatReady implements ZakatState {
  const ZakatReady(
      {this.nisabBySilver = true,
      this.goldGrams = '',
      this.silverGrams = '',
      this.goldPrice = '',
      this.silverPrice = '',
      this.cash = '',
      this.debts = '',
      this.result = const ZakatResult(
          zakatable: 0, nisabValue: 0, due: false, amount: 0)});

  @override
  @JsonKey()
  final bool nisabBySilver;
  @override
  @JsonKey()
  final String goldGrams;
  @override
  @JsonKey()
  final String silverGrams;
  @override
  @JsonKey()
  final String goldPrice;
  @override
  @JsonKey()
  final String silverPrice;
  @override
  @JsonKey()
  final String cash;
  @override
  @JsonKey()
  final String debts;
  @override
  @JsonKey()
  final ZakatResult result;

  /// Create a copy of ZakatState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ZakatReadyCopyWith<ZakatReady> get copyWith =>
      _$ZakatReadyCopyWithImpl<ZakatReady>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ZakatReady &&
            (identical(other.nisabBySilver, nisabBySilver) ||
                other.nisabBySilver == nisabBySilver) &&
            (identical(other.goldGrams, goldGrams) ||
                other.goldGrams == goldGrams) &&
            (identical(other.silverGrams, silverGrams) ||
                other.silverGrams == silverGrams) &&
            (identical(other.goldPrice, goldPrice) ||
                other.goldPrice == goldPrice) &&
            (identical(other.silverPrice, silverPrice) ||
                other.silverPrice == silverPrice) &&
            (identical(other.cash, cash) || other.cash == cash) &&
            (identical(other.debts, debts) || other.debts == debts) &&
            (identical(other.result, result) || other.result == result));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, nisabBySilver, goldGrams, silverGrams,
        goldPrice, silverPrice, cash, debts, result);
  }

  @override
  String toString() {
    return 'ZakatState.ready(nisabBySilver: $nisabBySilver, goldGrams: $goldGrams, silverGrams: $silverGrams, goldPrice: $goldPrice, silverPrice: $silverPrice, cash: $cash, debts: $debts, result: $result)';
  }
}

/// @nodoc
abstract mixin class $ZakatReadyCopyWith<$Res>
    implements $ZakatStateCopyWith<$Res> {
  factory $ZakatReadyCopyWith(
          ZakatReady value, $Res Function(ZakatReady) _then) =
      _$ZakatReadyCopyWithImpl;
  @override
  @useResult
  $Res call(
      {bool nisabBySilver,
      String goldGrams,
      String silverGrams,
      String goldPrice,
      String silverPrice,
      String cash,
      String debts,
      ZakatResult result});
}

/// @nodoc
class _$ZakatReadyCopyWithImpl<$Res> implements $ZakatReadyCopyWith<$Res> {
  _$ZakatReadyCopyWithImpl(this._self, this._then);

  final ZakatReady _self;
  final $Res Function(ZakatReady) _then;

  /// Create a copy of ZakatState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? nisabBySilver = null,
    Object? goldGrams = null,
    Object? silverGrams = null,
    Object? goldPrice = null,
    Object? silverPrice = null,
    Object? cash = null,
    Object? debts = null,
    Object? result = null,
  }) {
    return _then(ZakatReady(
      nisabBySilver: null == nisabBySilver
          ? _self.nisabBySilver
          : nisabBySilver // ignore: cast_nullable_to_non_nullable
              as bool,
      goldGrams: null == goldGrams
          ? _self.goldGrams
          : goldGrams // ignore: cast_nullable_to_non_nullable
              as String,
      silverGrams: null == silverGrams
          ? _self.silverGrams
          : silverGrams // ignore: cast_nullable_to_non_nullable
              as String,
      goldPrice: null == goldPrice
          ? _self.goldPrice
          : goldPrice // ignore: cast_nullable_to_non_nullable
              as String,
      silverPrice: null == silverPrice
          ? _self.silverPrice
          : silverPrice // ignore: cast_nullable_to_non_nullable
              as String,
      cash: null == cash
          ? _self.cash
          : cash // ignore: cast_nullable_to_non_nullable
              as String,
      debts: null == debts
          ? _self.debts
          : debts // ignore: cast_nullable_to_non_nullable
              as String,
      result: null == result
          ? _self.result
          : result // ignore: cast_nullable_to_non_nullable
              as ZakatResult,
    ));
  }
}

// dart format on

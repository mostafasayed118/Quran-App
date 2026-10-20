// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reader_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReaderState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is ReaderState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'ReaderState()';
  }
}

/// @nodoc
class $ReaderStateCopyWith<$Res> {
  $ReaderStateCopyWith(ReaderState _, $Res Function(ReaderState) __);
}

/// Adds pattern-matching-related methods to [ReaderState].
extension ReaderStatePatterns on ReaderState {
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
    TResult Function(ReaderLoading value)? loading,
    TResult Function(ReaderReady value)? ready,
    TResult Function(ReaderFailed value)? failed,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case ReaderLoading() when loading != null:
        return loading(_that);
      case ReaderReady() when ready != null:
        return ready(_that);
      case ReaderFailed() when failed != null:
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
    required TResult Function(ReaderLoading value) loading,
    required TResult Function(ReaderReady value) ready,
    required TResult Function(ReaderFailed value) failed,
  }) {
    final _that = this;
    switch (_that) {
      case ReaderLoading():
        return loading(_that);
      case ReaderReady():
        return ready(_that);
      case ReaderFailed():
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
    TResult? Function(ReaderLoading value)? loading,
    TResult? Function(ReaderReady value)? ready,
    TResult? Function(ReaderFailed value)? failed,
  }) {
    final _that = this;
    switch (_that) {
      case ReaderLoading() when loading != null:
        return loading(_that);
      case ReaderReady() when ready != null:
        return ready(_that);
      case ReaderFailed() when failed != null:
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
    TResult Function(int surahId, int initialAyah)? loading,
    TResult Function(
            int surahId,
            String surahName,
            int initialAyah,
            List<Verse> ayahs,
            List<MushafPageBlock> mushafPages,
            ReaderMode mode,
            Set<int> bookmarkedAyahIds,
            bool showBasmala)?
        ready,
    TResult Function(int? emptySurahId)? failed,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case ReaderLoading() when loading != null:
        return loading(_that.surahId, _that.initialAyah);
      case ReaderReady() when ready != null:
        return ready(
            _that.surahId,
            _that.surahName,
            _that.initialAyah,
            _that.ayahs,
            _that.mushafPages,
            _that.mode,
            _that.bookmarkedAyahIds,
            _that.showBasmala);
      case ReaderFailed() when failed != null:
        return failed(_that.emptySurahId);
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
    required TResult Function(int surahId, int initialAyah) loading,
    required TResult Function(
            int surahId,
            String surahName,
            int initialAyah,
            List<Verse> ayahs,
            List<MushafPageBlock> mushafPages,
            ReaderMode mode,
            Set<int> bookmarkedAyahIds,
            bool showBasmala)
        ready,
    required TResult Function(int? emptySurahId) failed,
  }) {
    final _that = this;
    switch (_that) {
      case ReaderLoading():
        return loading(_that.surahId, _that.initialAyah);
      case ReaderReady():
        return ready(
            _that.surahId,
            _that.surahName,
            _that.initialAyah,
            _that.ayahs,
            _that.mushafPages,
            _that.mode,
            _that.bookmarkedAyahIds,
            _that.showBasmala);
      case ReaderFailed():
        return failed(_that.emptySurahId);
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
    TResult? Function(int surahId, int initialAyah)? loading,
    TResult? Function(
            int surahId,
            String surahName,
            int initialAyah,
            List<Verse> ayahs,
            List<MushafPageBlock> mushafPages,
            ReaderMode mode,
            Set<int> bookmarkedAyahIds,
            bool showBasmala)?
        ready,
    TResult? Function(int? emptySurahId)? failed,
  }) {
    final _that = this;
    switch (_that) {
      case ReaderLoading() when loading != null:
        return loading(_that.surahId, _that.initialAyah);
      case ReaderReady() when ready != null:
        return ready(
            _that.surahId,
            _that.surahName,
            _that.initialAyah,
            _that.ayahs,
            _that.mushafPages,
            _that.mode,
            _that.bookmarkedAyahIds,
            _that.showBasmala);
      case ReaderFailed() when failed != null:
        return failed(_that.emptySurahId);
      case _:
        return null;
    }
  }
}

/// @nodoc

class ReaderLoading implements ReaderState {
  const ReaderLoading({required this.surahId, required this.initialAyah});

  final int surahId;
  final int initialAyah;

  /// Create a copy of ReaderState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ReaderLoadingCopyWith<ReaderLoading> get copyWith =>
      _$ReaderLoadingCopyWithImpl<ReaderLoading>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ReaderLoading &&
            (identical(other.surahId, surahId) || other.surahId == surahId) &&
            (identical(other.initialAyah, initialAyah) ||
                other.initialAyah == initialAyah));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, surahId, initialAyah);
  }

  @override
  String toString() {
    return 'ReaderState.loading(surahId: $surahId, initialAyah: $initialAyah)';
  }
}

/// @nodoc
abstract mixin class $ReaderLoadingCopyWith<$Res>
    implements $ReaderStateCopyWith<$Res> {
  factory $ReaderLoadingCopyWith(
          ReaderLoading value, $Res Function(ReaderLoading) _then) =
      _$ReaderLoadingCopyWithImpl;
  @useResult
  $Res call({int surahId, int initialAyah});
}

/// @nodoc
class _$ReaderLoadingCopyWithImpl<$Res>
    implements $ReaderLoadingCopyWith<$Res> {
  _$ReaderLoadingCopyWithImpl(this._self, this._then);

  final ReaderLoading _self;
  final $Res Function(ReaderLoading) _then;

  /// Create a copy of ReaderState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? surahId = null,
    Object? initialAyah = null,
  }) {
    return _then(ReaderLoading(
      surahId: null == surahId
          ? _self.surahId
          : surahId // ignore: cast_nullable_to_non_nullable
              as int,
      initialAyah: null == initialAyah
          ? _self.initialAyah
          : initialAyah // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class ReaderReady implements ReaderState {
  const ReaderReady(
      {required this.surahId,
      required this.surahName,
      required this.initialAyah,
      required List<Verse> ayahs,
      required List<MushafPageBlock> mushafPages,
      this.mode = ReaderMode.verses,
      Set<int> bookmarkedAyahIds = const <int>{},
      this.showBasmala = true})
      : _ayahs = ayahs,
        _mushafPages = mushafPages,
        _bookmarkedAyahIds = bookmarkedAyahIds;

  final int surahId;
  final String surahName;
  final int initialAyah;
  final List<Verse> _ayahs;
  List<Verse> get ayahs {
    if (_ayahs is EqualUnmodifiableListView) return _ayahs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_ayahs);
  }

  final List<MushafPageBlock> _mushafPages;
  List<MushafPageBlock> get mushafPages {
    if (_mushafPages is EqualUnmodifiableListView) return _mushafPages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_mushafPages);
  }

  @JsonKey()
  final ReaderMode mode;
  final Set<int> _bookmarkedAyahIds;
  @JsonKey()
  Set<int> get bookmarkedAyahIds {
    if (_bookmarkedAyahIds is EqualUnmodifiableSetView)
      return _bookmarkedAyahIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_bookmarkedAyahIds);
  }

  @JsonKey()
  final bool showBasmala;

  /// Create a copy of ReaderState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ReaderReadyCopyWith<ReaderReady> get copyWith =>
      _$ReaderReadyCopyWithImpl<ReaderReady>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ReaderReady &&
            (identical(other.surahId, surahId) || other.surahId == surahId) &&
            (identical(other.surahName, surahName) ||
                other.surahName == surahName) &&
            (identical(other.initialAyah, initialAyah) ||
                other.initialAyah == initialAyah) &&
            const DeepCollectionEquality().equals(other.ayahs, _ayahs) &&
            const DeepCollectionEquality()
                .equals(other.mushafPages, _mushafPages) &&
            (identical(other.mode, mode) || other.mode == mode) &&
            const DeepCollectionEquality()
                .equals(other.bookmarkedAyahIds, _bookmarkedAyahIds) &&
            (identical(other.showBasmala, showBasmala) ||
                other.showBasmala == showBasmala));
  }

  @override
  int get hashCode {
    return Object.hash(
        runtimeType,
        surahId,
        surahName,
        initialAyah,
        const DeepCollectionEquality().hash(_ayahs),
        const DeepCollectionEquality().hash(_mushafPages),
        mode,
        const DeepCollectionEquality().hash(_bookmarkedAyahIds),
        showBasmala);
  }

  @override
  String toString() {
    return 'ReaderState.ready(surahId: $surahId, surahName: $surahName, initialAyah: $initialAyah, ayahs: $ayahs, mushafPages: $mushafPages, mode: $mode, bookmarkedAyahIds: $bookmarkedAyahIds, showBasmala: $showBasmala)';
  }
}

/// @nodoc
abstract mixin class $ReaderReadyCopyWith<$Res>
    implements $ReaderStateCopyWith<$Res> {
  factory $ReaderReadyCopyWith(
          ReaderReady value, $Res Function(ReaderReady) _then) =
      _$ReaderReadyCopyWithImpl;
  @useResult
  $Res call(
      {int surahId,
      String surahName,
      int initialAyah,
      List<Verse> ayahs,
      List<MushafPageBlock> mushafPages,
      ReaderMode mode,
      Set<int> bookmarkedAyahIds,
      bool showBasmala});
}

/// @nodoc
class _$ReaderReadyCopyWithImpl<$Res> implements $ReaderReadyCopyWith<$Res> {
  _$ReaderReadyCopyWithImpl(this._self, this._then);

  final ReaderReady _self;
  final $Res Function(ReaderReady) _then;

  /// Create a copy of ReaderState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? surahId = null,
    Object? surahName = null,
    Object? initialAyah = null,
    Object? ayahs = null,
    Object? mushafPages = null,
    Object? mode = null,
    Object? bookmarkedAyahIds = null,
    Object? showBasmala = null,
  }) {
    return _then(ReaderReady(
      surahId: null == surahId
          ? _self.surahId
          : surahId // ignore: cast_nullable_to_non_nullable
              as int,
      surahName: null == surahName
          ? _self.surahName
          : surahName // ignore: cast_nullable_to_non_nullable
              as String,
      initialAyah: null == initialAyah
          ? _self.initialAyah
          : initialAyah // ignore: cast_nullable_to_non_nullable
              as int,
      ayahs: null == ayahs
          ? _self._ayahs
          : ayahs // ignore: cast_nullable_to_non_nullable
              as List<Verse>,
      mushafPages: null == mushafPages
          ? _self._mushafPages
          : mushafPages // ignore: cast_nullable_to_non_nullable
              as List<MushafPageBlock>,
      mode: null == mode
          ? _self.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as ReaderMode,
      bookmarkedAyahIds: null == bookmarkedAyahIds
          ? _self._bookmarkedAyahIds
          : bookmarkedAyahIds // ignore: cast_nullable_to_non_nullable
              as Set<int>,
      showBasmala: null == showBasmala
          ? _self.showBasmala
          : showBasmala // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class ReaderFailed implements ReaderState {
  const ReaderFailed({this.emptySurahId = null});

  @JsonKey()
  final int? emptySurahId;

  /// Create a copy of ReaderState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ReaderFailedCopyWith<ReaderFailed> get copyWith =>
      _$ReaderFailedCopyWithImpl<ReaderFailed>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ReaderFailed &&
            (identical(other.emptySurahId, emptySurahId) ||
                other.emptySurahId == emptySurahId));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, emptySurahId);
  }

  @override
  String toString() {
    return 'ReaderState.failed(emptySurahId: $emptySurahId)';
  }
}

/// @nodoc
abstract mixin class $ReaderFailedCopyWith<$Res>
    implements $ReaderStateCopyWith<$Res> {
  factory $ReaderFailedCopyWith(
          ReaderFailed value, $Res Function(ReaderFailed) _then) =
      _$ReaderFailedCopyWithImpl;
  @useResult
  $Res call({int? emptySurahId});
}

/// @nodoc
class _$ReaderFailedCopyWithImpl<$Res> implements $ReaderFailedCopyWith<$Res> {
  _$ReaderFailedCopyWithImpl(this._self, this._then);

  final ReaderFailed _self;
  final $Res Function(ReaderFailed) _then;

  /// Create a copy of ReaderState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? emptySurahId = freezed,
  }) {
    return _then(ReaderFailed(
      emptySurahId: freezed == emptySurahId
          ? _self.emptySurahId
          : emptySurahId // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playback_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlaybackState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is PlaybackState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'PlaybackState()';
  }
}

/// @nodoc
class $PlaybackStateCopyWith<$Res> {
  $PlaybackStateCopyWith(PlaybackState _, $Res Function(PlaybackState) __);
}

/// Adds pattern-matching-related methods to [PlaybackState].
extension PlaybackStatePatterns on PlaybackState {
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
    TResult Function(PlaybackLoading value)? initial,
    TResult Function(PlaybackPlaying value)? playing,
    TResult Function(PlaybackPaused value)? paused,
    TResult Function(PlaybackFailed value)? failed,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case PlaybackLoading() when initial != null:
        return initial(_that);
      case PlaybackPlaying() when playing != null:
        return playing(_that);
      case PlaybackPaused() when paused != null:
        return paused(_that);
      case PlaybackFailed() when failed != null:
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
    required TResult Function(PlaybackLoading value) initial,
    required TResult Function(PlaybackPlaying value) playing,
    required TResult Function(PlaybackPaused value) paused,
    required TResult Function(PlaybackFailed value) failed,
  }) {
    final _that = this;
    switch (_that) {
      case PlaybackLoading():
        return initial(_that);
      case PlaybackPlaying():
        return playing(_that);
      case PlaybackPaused():
        return paused(_that);
      case PlaybackFailed():
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
    TResult? Function(PlaybackLoading value)? initial,
    TResult? Function(PlaybackPlaying value)? playing,
    TResult? Function(PlaybackPaused value)? paused,
    TResult? Function(PlaybackFailed value)? failed,
  }) {
    final _that = this;
    switch (_that) {
      case PlaybackLoading() when initial != null:
        return initial(_that);
      case PlaybackPlaying() when playing != null:
        return playing(_that);
      case PlaybackPaused() when paused != null:
        return paused(_that);
      case PlaybackFailed() when failed != null:
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
    TResult Function(String? reciterName, int surahNumber)? initial,
    TResult Function(String reciterName, int surahNumber, Duration position,
            Duration duration)?
        playing,
    TResult Function(String reciterName, int surahNumber, Duration position,
            Duration duration)?
        paused,
    TResult Function(PlaybackFailureKind kind)? failed,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case PlaybackLoading() when initial != null:
        return initial(_that.reciterName, _that.surahNumber);
      case PlaybackPlaying() when playing != null:
        return playing(_that.reciterName, _that.surahNumber, _that.position,
            _that.duration);
      case PlaybackPaused() when paused != null:
        return paused(_that.reciterName, _that.surahNumber, _that.position,
            _that.duration);
      case PlaybackFailed() when failed != null:
        return failed(_that.kind);
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
    required TResult Function(String? reciterName, int surahNumber) initial,
    required TResult Function(String reciterName, int surahNumber,
            Duration position, Duration duration)
        playing,
    required TResult Function(String reciterName, int surahNumber,
            Duration position, Duration duration)
        paused,
    required TResult Function(PlaybackFailureKind kind) failed,
  }) {
    final _that = this;
    switch (_that) {
      case PlaybackLoading():
        return initial(_that.reciterName, _that.surahNumber);
      case PlaybackPlaying():
        return playing(_that.reciterName, _that.surahNumber, _that.position,
            _that.duration);
      case PlaybackPaused():
        return paused(_that.reciterName, _that.surahNumber, _that.position,
            _that.duration);
      case PlaybackFailed():
        return failed(_that.kind);
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
    TResult? Function(String? reciterName, int surahNumber)? initial,
    TResult? Function(String reciterName, int surahNumber, Duration position,
            Duration duration)?
        playing,
    TResult? Function(String reciterName, int surahNumber, Duration position,
            Duration duration)?
        paused,
    TResult? Function(PlaybackFailureKind kind)? failed,
  }) {
    final _that = this;
    switch (_that) {
      case PlaybackLoading() when initial != null:
        return initial(_that.reciterName, _that.surahNumber);
      case PlaybackPlaying() when playing != null:
        return playing(_that.reciterName, _that.surahNumber, _that.position,
            _that.duration);
      case PlaybackPaused() when paused != null:
        return paused(_that.reciterName, _that.surahNumber, _that.position,
            _that.duration);
      case PlaybackFailed() when failed != null:
        return failed(_that.kind);
      case _:
        return null;
    }
  }
}

/// @nodoc

class PlaybackLoading implements PlaybackState {
  const PlaybackLoading({this.reciterName, this.surahNumber = 0});

  final String? reciterName;
  @JsonKey()
  final int surahNumber;

  /// Create a copy of PlaybackState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PlaybackLoadingCopyWith<PlaybackLoading> get copyWith =>
      _$PlaybackLoadingCopyWithImpl<PlaybackLoading>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PlaybackLoading &&
            (identical(other.reciterName, reciterName) ||
                other.reciterName == reciterName) &&
            (identical(other.surahNumber, surahNumber) ||
                other.surahNumber == surahNumber));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, reciterName, surahNumber);
  }

  @override
  String toString() {
    return 'PlaybackState.initial(reciterName: $reciterName, surahNumber: $surahNumber)';
  }
}

/// @nodoc
abstract mixin class $PlaybackLoadingCopyWith<$Res>
    implements $PlaybackStateCopyWith<$Res> {
  factory $PlaybackLoadingCopyWith(
          PlaybackLoading value, $Res Function(PlaybackLoading) _then) =
      _$PlaybackLoadingCopyWithImpl;
  @useResult
  $Res call({String? reciterName, int surahNumber});
}

/// @nodoc
class _$PlaybackLoadingCopyWithImpl<$Res>
    implements $PlaybackLoadingCopyWith<$Res> {
  _$PlaybackLoadingCopyWithImpl(this._self, this._then);

  final PlaybackLoading _self;
  final $Res Function(PlaybackLoading) _then;

  /// Create a copy of PlaybackState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? reciterName = freezed,
    Object? surahNumber = null,
  }) {
    return _then(PlaybackLoading(
      reciterName: freezed == reciterName
          ? _self.reciterName
          : reciterName // ignore: cast_nullable_to_non_nullable
              as String?,
      surahNumber: null == surahNumber
          ? _self.surahNumber
          : surahNumber // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class PlaybackPlaying implements PlaybackState {
  const PlaybackPlaying(
      {required this.reciterName,
      required this.surahNumber,
      this.position = Duration.zero,
      this.duration = Duration.zero});

  final String reciterName;
  final int surahNumber;
  @JsonKey()
  final Duration position;
  @JsonKey()
  final Duration duration;

  /// Create a copy of PlaybackState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PlaybackPlayingCopyWith<PlaybackPlaying> get copyWith =>
      _$PlaybackPlayingCopyWithImpl<PlaybackPlaying>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PlaybackPlaying &&
            (identical(other.reciterName, reciterName) ||
                other.reciterName == reciterName) &&
            (identical(other.surahNumber, surahNumber) ||
                other.surahNumber == surahNumber) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.duration, duration) ||
                other.duration == duration));
  }

  @override
  int get hashCode {
    return Object.hash(
        runtimeType, reciterName, surahNumber, position, duration);
  }

  @override
  String toString() {
    return 'PlaybackState.playing(reciterName: $reciterName, surahNumber: $surahNumber, position: $position, duration: $duration)';
  }
}

/// @nodoc
abstract mixin class $PlaybackPlayingCopyWith<$Res>
    implements $PlaybackStateCopyWith<$Res> {
  factory $PlaybackPlayingCopyWith(
          PlaybackPlaying value, $Res Function(PlaybackPlaying) _then) =
      _$PlaybackPlayingCopyWithImpl;
  @useResult
  $Res call(
      {String reciterName,
      int surahNumber,
      Duration position,
      Duration duration});
}

/// @nodoc
class _$PlaybackPlayingCopyWithImpl<$Res>
    implements $PlaybackPlayingCopyWith<$Res> {
  _$PlaybackPlayingCopyWithImpl(this._self, this._then);

  final PlaybackPlaying _self;
  final $Res Function(PlaybackPlaying) _then;

  /// Create a copy of PlaybackState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? reciterName = null,
    Object? surahNumber = null,
    Object? position = null,
    Object? duration = null,
  }) {
    return _then(PlaybackPlaying(
      reciterName: null == reciterName
          ? _self.reciterName
          : reciterName // ignore: cast_nullable_to_non_nullable
              as String,
      surahNumber: null == surahNumber
          ? _self.surahNumber
          : surahNumber // ignore: cast_nullable_to_non_nullable
              as int,
      position: null == position
          ? _self.position
          : position // ignore: cast_nullable_to_non_nullable
              as Duration,
      duration: null == duration
          ? _self.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as Duration,
    ));
  }
}

/// @nodoc

class PlaybackPaused implements PlaybackState {
  const PlaybackPaused(
      {required this.reciterName,
      required this.surahNumber,
      this.position = Duration.zero,
      this.duration = Duration.zero});

  final String reciterName;
  final int surahNumber;
  @JsonKey()
  final Duration position;
  @JsonKey()
  final Duration duration;

  /// Create a copy of PlaybackState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PlaybackPausedCopyWith<PlaybackPaused> get copyWith =>
      _$PlaybackPausedCopyWithImpl<PlaybackPaused>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PlaybackPaused &&
            (identical(other.reciterName, reciterName) ||
                other.reciterName == reciterName) &&
            (identical(other.surahNumber, surahNumber) ||
                other.surahNumber == surahNumber) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.duration, duration) ||
                other.duration == duration));
  }

  @override
  int get hashCode {
    return Object.hash(
        runtimeType, reciterName, surahNumber, position, duration);
  }

  @override
  String toString() {
    return 'PlaybackState.paused(reciterName: $reciterName, surahNumber: $surahNumber, position: $position, duration: $duration)';
  }
}

/// @nodoc
abstract mixin class $PlaybackPausedCopyWith<$Res>
    implements $PlaybackStateCopyWith<$Res> {
  factory $PlaybackPausedCopyWith(
          PlaybackPaused value, $Res Function(PlaybackPaused) _then) =
      _$PlaybackPausedCopyWithImpl;
  @useResult
  $Res call(
      {String reciterName,
      int surahNumber,
      Duration position,
      Duration duration});
}

/// @nodoc
class _$PlaybackPausedCopyWithImpl<$Res>
    implements $PlaybackPausedCopyWith<$Res> {
  _$PlaybackPausedCopyWithImpl(this._self, this._then);

  final PlaybackPaused _self;
  final $Res Function(PlaybackPaused) _then;

  /// Create a copy of PlaybackState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? reciterName = null,
    Object? surahNumber = null,
    Object? position = null,
    Object? duration = null,
  }) {
    return _then(PlaybackPaused(
      reciterName: null == reciterName
          ? _self.reciterName
          : reciterName // ignore: cast_nullable_to_non_nullable
              as String,
      surahNumber: null == surahNumber
          ? _self.surahNumber
          : surahNumber // ignore: cast_nullable_to_non_nullable
              as int,
      position: null == position
          ? _self.position
          : position // ignore: cast_nullable_to_non_nullable
              as Duration,
      duration: null == duration
          ? _self.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as Duration,
    ));
  }
}

/// @nodoc

class PlaybackFailed implements PlaybackState {
  const PlaybackFailed({required this.kind});

  final PlaybackFailureKind kind;

  /// Create a copy of PlaybackState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PlaybackFailedCopyWith<PlaybackFailed> get copyWith =>
      _$PlaybackFailedCopyWithImpl<PlaybackFailed>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PlaybackFailed &&
            (identical(other.kind, kind) || other.kind == kind));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, kind);
  }

  @override
  String toString() {
    return 'PlaybackState.failed(kind: $kind)';
  }
}

/// @nodoc
abstract mixin class $PlaybackFailedCopyWith<$Res>
    implements $PlaybackStateCopyWith<$Res> {
  factory $PlaybackFailedCopyWith(
          PlaybackFailed value, $Res Function(PlaybackFailed) _then) =
      _$PlaybackFailedCopyWithImpl;
  @useResult
  $Res call({PlaybackFailureKind kind});
}

/// @nodoc
class _$PlaybackFailedCopyWithImpl<$Res>
    implements $PlaybackFailedCopyWith<$Res> {
  _$PlaybackFailedCopyWithImpl(this._self, this._then);

  final PlaybackFailed _self;
  final $Res Function(PlaybackFailed) _then;

  /// Create a copy of PlaybackState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? kind = null,
  }) {
    return _then(PlaybackFailed(
      kind: null == kind
          ? _self.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as PlaybackFailureKind,
    ));
  }
}

// dart format on

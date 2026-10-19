// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'backup_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BackupState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is BackupState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'BackupState()';
  }
}

/// @nodoc
class $BackupStateCopyWith<$Res> {
  $BackupStateCopyWith(BackupState _, $Res Function(BackupState) __);
}

/// Adds pattern-matching-related methods to [BackupState].
extension BackupStatePatterns on BackupState {
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
    TResult Function(BackupIdle value)? idle,
    TResult Function(BackupPreviewReady value)? preview,
    TResult Function(BackupExported value)? exported,
    TResult Function(BackupImported value)? imported,
    TResult Function(BackupFailed value)? failed,
    TResult Function(BackupInvalidFile value)? invalidFile,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case BackupIdle() when idle != null:
        return idle(_that);
      case BackupPreviewReady() when preview != null:
        return preview(_that);
      case BackupExported() when exported != null:
        return exported(_that);
      case BackupImported() when imported != null:
        return imported(_that);
      case BackupFailed() when failed != null:
        return failed(_that);
      case BackupInvalidFile() when invalidFile != null:
        return invalidFile(_that);
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
    required TResult Function(BackupIdle value) idle,
    required TResult Function(BackupPreviewReady value) preview,
    required TResult Function(BackupExported value) exported,
    required TResult Function(BackupImported value) imported,
    required TResult Function(BackupFailed value) failed,
    required TResult Function(BackupInvalidFile value) invalidFile,
  }) {
    final _that = this;
    switch (_that) {
      case BackupIdle():
        return idle(_that);
      case BackupPreviewReady():
        return preview(_that);
      case BackupExported():
        return exported(_that);
      case BackupImported():
        return imported(_that);
      case BackupFailed():
        return failed(_that);
      case BackupInvalidFile():
        return invalidFile(_that);
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
    TResult? Function(BackupIdle value)? idle,
    TResult? Function(BackupPreviewReady value)? preview,
    TResult? Function(BackupExported value)? exported,
    TResult? Function(BackupImported value)? imported,
    TResult? Function(BackupFailed value)? failed,
    TResult? Function(BackupInvalidFile value)? invalidFile,
  }) {
    final _that = this;
    switch (_that) {
      case BackupIdle() when idle != null:
        return idle(_that);
      case BackupPreviewReady() when preview != null:
        return preview(_that);
      case BackupExported() when exported != null:
        return exported(_that);
      case BackupImported() when imported != null:
        return imported(_that);
      case BackupFailed() when failed != null:
        return failed(_that);
      case BackupInvalidFile() when invalidFile != null:
        return invalidFile(_that);
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
    TResult Function(bool busy)? idle,
    TResult Function(BackupDocument document, BackupSummary summary)? preview,
    TResult Function()? exported,
    TResult Function(BackupSummary summary)? imported,
    TResult Function(bool duringExport)? failed,
    TResult Function()? invalidFile,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case BackupIdle() when idle != null:
        return idle(_that.busy);
      case BackupPreviewReady() when preview != null:
        return preview(_that.document, _that.summary);
      case BackupExported() when exported != null:
        return exported();
      case BackupImported() when imported != null:
        return imported(_that.summary);
      case BackupFailed() when failed != null:
        return failed(_that.duringExport);
      case BackupInvalidFile() when invalidFile != null:
        return invalidFile();
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
    required TResult Function(bool busy) idle,
    required TResult Function(BackupDocument document, BackupSummary summary)
        preview,
    required TResult Function() exported,
    required TResult Function(BackupSummary summary) imported,
    required TResult Function(bool duringExport) failed,
    required TResult Function() invalidFile,
  }) {
    final _that = this;
    switch (_that) {
      case BackupIdle():
        return idle(_that.busy);
      case BackupPreviewReady():
        return preview(_that.document, _that.summary);
      case BackupExported():
        return exported();
      case BackupImported():
        return imported(_that.summary);
      case BackupFailed():
        return failed(_that.duringExport);
      case BackupInvalidFile():
        return invalidFile();
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
    TResult? Function(bool busy)? idle,
    TResult? Function(BackupDocument document, BackupSummary summary)? preview,
    TResult? Function()? exported,
    TResult? Function(BackupSummary summary)? imported,
    TResult? Function(bool duringExport)? failed,
    TResult? Function()? invalidFile,
  }) {
    final _that = this;
    switch (_that) {
      case BackupIdle() when idle != null:
        return idle(_that.busy);
      case BackupPreviewReady() when preview != null:
        return preview(_that.document, _that.summary);
      case BackupExported() when exported != null:
        return exported();
      case BackupImported() when imported != null:
        return imported(_that.summary);
      case BackupFailed() when failed != null:
        return failed(_that.duringExport);
      case BackupInvalidFile() when invalidFile != null:
        return invalidFile();
      case _:
        return null;
    }
  }
}

/// @nodoc

class BackupIdle implements BackupState {
  const BackupIdle({this.busy = false});

  @JsonKey()
  final bool busy;

  /// Create a copy of BackupState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BackupIdleCopyWith<BackupIdle> get copyWith =>
      _$BackupIdleCopyWithImpl<BackupIdle>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BackupIdle &&
            (identical(other.busy, busy) || other.busy == busy));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, busy);
  }

  @override
  String toString() {
    return 'BackupState.idle(busy: $busy)';
  }
}

/// @nodoc
abstract mixin class $BackupIdleCopyWith<$Res>
    implements $BackupStateCopyWith<$Res> {
  factory $BackupIdleCopyWith(
          BackupIdle value, $Res Function(BackupIdle) _then) =
      _$BackupIdleCopyWithImpl;
  @useResult
  $Res call({bool busy});
}

/// @nodoc
class _$BackupIdleCopyWithImpl<$Res> implements $BackupIdleCopyWith<$Res> {
  _$BackupIdleCopyWithImpl(this._self, this._then);

  final BackupIdle _self;
  final $Res Function(BackupIdle) _then;

  /// Create a copy of BackupState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? busy = null,
  }) {
    return _then(BackupIdle(
      busy: null == busy
          ? _self.busy
          : busy // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class BackupPreviewReady implements BackupState {
  const BackupPreviewReady({required this.document, required this.summary});

  final BackupDocument document;
  final BackupSummary summary;

  /// Create a copy of BackupState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BackupPreviewReadyCopyWith<BackupPreviewReady> get copyWith =>
      _$BackupPreviewReadyCopyWithImpl<BackupPreviewReady>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BackupPreviewReady &&
            (identical(other.document, document) ||
                other.document == document) &&
            (identical(other.summary, summary) || other.summary == summary));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, document, summary);
  }

  @override
  String toString() {
    return 'BackupState.preview(document: $document, summary: $summary)';
  }
}

/// @nodoc
abstract mixin class $BackupPreviewReadyCopyWith<$Res>
    implements $BackupStateCopyWith<$Res> {
  factory $BackupPreviewReadyCopyWith(
          BackupPreviewReady value, $Res Function(BackupPreviewReady) _then) =
      _$BackupPreviewReadyCopyWithImpl;
  @useResult
  $Res call({BackupDocument document, BackupSummary summary});
}

/// @nodoc
class _$BackupPreviewReadyCopyWithImpl<$Res>
    implements $BackupPreviewReadyCopyWith<$Res> {
  _$BackupPreviewReadyCopyWithImpl(this._self, this._then);

  final BackupPreviewReady _self;
  final $Res Function(BackupPreviewReady) _then;

  /// Create a copy of BackupState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? document = null,
    Object? summary = null,
  }) {
    return _then(BackupPreviewReady(
      document: null == document
          ? _self.document
          : document // ignore: cast_nullable_to_non_nullable
              as BackupDocument,
      summary: null == summary
          ? _self.summary
          : summary // ignore: cast_nullable_to_non_nullable
              as BackupSummary,
    ));
  }
}

/// @nodoc

class BackupExported implements BackupState {
  const BackupExported();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is BackupExported);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'BackupState.exported()';
  }
}

/// @nodoc

class BackupImported implements BackupState {
  const BackupImported({required this.summary});

  final BackupSummary summary;

  /// Create a copy of BackupState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BackupImportedCopyWith<BackupImported> get copyWith =>
      _$BackupImportedCopyWithImpl<BackupImported>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BackupImported &&
            (identical(other.summary, summary) || other.summary == summary));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, summary);
  }

  @override
  String toString() {
    return 'BackupState.imported(summary: $summary)';
  }
}

/// @nodoc
abstract mixin class $BackupImportedCopyWith<$Res>
    implements $BackupStateCopyWith<$Res> {
  factory $BackupImportedCopyWith(
          BackupImported value, $Res Function(BackupImported) _then) =
      _$BackupImportedCopyWithImpl;
  @useResult
  $Res call({BackupSummary summary});
}

/// @nodoc
class _$BackupImportedCopyWithImpl<$Res>
    implements $BackupImportedCopyWith<$Res> {
  _$BackupImportedCopyWithImpl(this._self, this._then);

  final BackupImported _self;
  final $Res Function(BackupImported) _then;

  /// Create a copy of BackupState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? summary = null,
  }) {
    return _then(BackupImported(
      summary: null == summary
          ? _self.summary
          : summary // ignore: cast_nullable_to_non_nullable
              as BackupSummary,
    ));
  }
}

/// @nodoc

class BackupFailed implements BackupState {
  const BackupFailed({required this.duringExport});

  final bool duringExport;

  /// Create a copy of BackupState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BackupFailedCopyWith<BackupFailed> get copyWith =>
      _$BackupFailedCopyWithImpl<BackupFailed>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BackupFailed &&
            (identical(other.duringExport, duringExport) ||
                other.duringExport == duringExport));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, duringExport);
  }

  @override
  String toString() {
    return 'BackupState.failed(duringExport: $duringExport)';
  }
}

/// @nodoc
abstract mixin class $BackupFailedCopyWith<$Res>
    implements $BackupStateCopyWith<$Res> {
  factory $BackupFailedCopyWith(
          BackupFailed value, $Res Function(BackupFailed) _then) =
      _$BackupFailedCopyWithImpl;
  @useResult
  $Res call({bool duringExport});
}

/// @nodoc
class _$BackupFailedCopyWithImpl<$Res> implements $BackupFailedCopyWith<$Res> {
  _$BackupFailedCopyWithImpl(this._self, this._then);

  final BackupFailed _self;
  final $Res Function(BackupFailed) _then;

  /// Create a copy of BackupState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? duringExport = null,
  }) {
    return _then(BackupFailed(
      duringExport: null == duringExport
          ? _self.duringExport
          : duringExport // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class BackupInvalidFile implements BackupState {
  const BackupInvalidFile();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is BackupInvalidFile);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'BackupState.invalidFile()';
  }
}

// dart format on

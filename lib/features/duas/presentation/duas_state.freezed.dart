// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'duas_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DuasState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is DuasState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'DuasState()';
  }
}

/// @nodoc
class $DuasStateCopyWith<$Res> {
  $DuasStateCopyWith(DuasState _, $Res Function(DuasState) __);
}

/// Adds pattern-matching-related methods to [DuasState].
extension DuasStatePatterns on DuasState {
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
    TResult Function(DuasLoading value)? loading,
    TResult Function(DuasInView value)? duas,
    TResult Function(RuqyahInView value)? ruqyah,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case DuasLoading() when loading != null:
        return loading(_that);
      case DuasInView() when duas != null:
        return duas(_that);
      case RuqyahInView() when ruqyah != null:
        return ruqyah(_that);
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
    required TResult Function(DuasLoading value) loading,
    required TResult Function(DuasInView value) duas,
    required TResult Function(RuqyahInView value) ruqyah,
  }) {
    final _that = this;
    switch (_that) {
      case DuasLoading():
        return loading(_that);
      case DuasInView():
        return duas(_that);
      case RuqyahInView():
        return ruqyah(_that);
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
    TResult? Function(DuasLoading value)? loading,
    TResult? Function(DuasInView value)? duas,
    TResult? Function(RuqyahInView value)? ruqyah,
  }) {
    final _that = this;
    switch (_that) {
      case DuasLoading() when loading != null:
        return loading(_that);
      case DuasInView() when duas != null:
        return duas(_that);
      case RuqyahInView() when ruqyah != null:
        return ruqyah(_that);
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
    TResult Function(DuasTab tab)? loading,
    TResult Function(List<String> categories, List<DuaEntry> entries,
            String? selectedCategory)?
        duas,
    TResult Function(List<RuqyahResolved> entries)? ruqyah,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case DuasLoading() when loading != null:
        return loading(_that.tab);
      case DuasInView() when duas != null:
        return duas(_that.categories, _that.entries, _that.selectedCategory);
      case RuqyahInView() when ruqyah != null:
        return ruqyah(_that.entries);
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
    required TResult Function(DuasTab tab) loading,
    required TResult Function(List<String> categories, List<DuaEntry> entries,
            String? selectedCategory)
        duas,
    required TResult Function(List<RuqyahResolved> entries) ruqyah,
  }) {
    final _that = this;
    switch (_that) {
      case DuasLoading():
        return loading(_that.tab);
      case DuasInView():
        return duas(_that.categories, _that.entries, _that.selectedCategory);
      case RuqyahInView():
        return ruqyah(_that.entries);
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
    TResult? Function(DuasTab tab)? loading,
    TResult? Function(List<String> categories, List<DuaEntry> entries,
            String? selectedCategory)?
        duas,
    TResult? Function(List<RuqyahResolved> entries)? ruqyah,
  }) {
    final _that = this;
    switch (_that) {
      case DuasLoading() when loading != null:
        return loading(_that.tab);
      case DuasInView() when duas != null:
        return duas(_that.categories, _that.entries, _that.selectedCategory);
      case RuqyahInView() when ruqyah != null:
        return ruqyah(_that.entries);
      case _:
        return null;
    }
  }
}

/// @nodoc

class DuasLoading implements DuasState {
  const DuasLoading({this.tab = DuasTab.duas});

  @JsonKey()
  final DuasTab tab;

  /// Create a copy of DuasState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DuasLoadingCopyWith<DuasLoading> get copyWith =>
      _$DuasLoadingCopyWithImpl<DuasLoading>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DuasLoading &&
            (identical(other.tab, tab) || other.tab == tab));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, tab);
  }

  @override
  String toString() {
    return 'DuasState.loading(tab: $tab)';
  }
}

/// @nodoc
abstract mixin class $DuasLoadingCopyWith<$Res>
    implements $DuasStateCopyWith<$Res> {
  factory $DuasLoadingCopyWith(
          DuasLoading value, $Res Function(DuasLoading) _then) =
      _$DuasLoadingCopyWithImpl;
  @useResult
  $Res call({DuasTab tab});
}

/// @nodoc
class _$DuasLoadingCopyWithImpl<$Res> implements $DuasLoadingCopyWith<$Res> {
  _$DuasLoadingCopyWithImpl(this._self, this._then);

  final DuasLoading _self;
  final $Res Function(DuasLoading) _then;

  /// Create a copy of DuasState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? tab = null,
  }) {
    return _then(DuasLoading(
      tab: null == tab
          ? _self.tab
          : tab // ignore: cast_nullable_to_non_nullable
              as DuasTab,
    ));
  }
}

/// @nodoc

class DuasInView implements DuasState {
  const DuasInView(
      {required List<String> categories,
      required List<DuaEntry> entries,
      this.selectedCategory = null})
      : _categories = categories,
        _entries = entries;

  final List<String> _categories;
  List<String> get categories {
    if (_categories is EqualUnmodifiableListView) return _categories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_categories);
  }

  final List<DuaEntry> _entries;
  List<DuaEntry> get entries {
    if (_entries is EqualUnmodifiableListView) return _entries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_entries);
  }

  @JsonKey()
  final String? selectedCategory;

  /// Create a copy of DuasState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DuasInViewCopyWith<DuasInView> get copyWith =>
      _$DuasInViewCopyWithImpl<DuasInView>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DuasInView &&
            const DeepCollectionEquality()
                .equals(other.categories, _categories) &&
            const DeepCollectionEquality().equals(other.entries, _entries) &&
            (identical(other.selectedCategory, selectedCategory) ||
                other.selectedCategory == selectedCategory));
  }

  @override
  int get hashCode {
    return Object.hash(
        runtimeType,
        const DeepCollectionEquality().hash(_categories),
        const DeepCollectionEquality().hash(_entries),
        selectedCategory);
  }

  @override
  String toString() {
    return 'DuasState.duas(categories: $categories, entries: $entries, selectedCategory: $selectedCategory)';
  }
}

/// @nodoc
abstract mixin class $DuasInViewCopyWith<$Res>
    implements $DuasStateCopyWith<$Res> {
  factory $DuasInViewCopyWith(
          DuasInView value, $Res Function(DuasInView) _then) =
      _$DuasInViewCopyWithImpl;
  @useResult
  $Res call(
      {List<String> categories,
      List<DuaEntry> entries,
      String? selectedCategory});
}

/// @nodoc
class _$DuasInViewCopyWithImpl<$Res> implements $DuasInViewCopyWith<$Res> {
  _$DuasInViewCopyWithImpl(this._self, this._then);

  final DuasInView _self;
  final $Res Function(DuasInView) _then;

  /// Create a copy of DuasState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? categories = null,
    Object? entries = null,
    Object? selectedCategory = freezed,
  }) {
    return _then(DuasInView(
      categories: null == categories
          ? _self._categories
          : categories // ignore: cast_nullable_to_non_nullable
              as List<String>,
      entries: null == entries
          ? _self._entries
          : entries // ignore: cast_nullable_to_non_nullable
              as List<DuaEntry>,
      selectedCategory: freezed == selectedCategory
          ? _self.selectedCategory
          : selectedCategory // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class RuqyahInView implements DuasState {
  const RuqyahInView({required List<RuqyahResolved> entries})
      : _entries = entries;

  final List<RuqyahResolved> _entries;
  List<RuqyahResolved> get entries {
    if (_entries is EqualUnmodifiableListView) return _entries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_entries);
  }

  /// Create a copy of DuasState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RuqyahInViewCopyWith<RuqyahInView> get copyWith =>
      _$RuqyahInViewCopyWithImpl<RuqyahInView>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RuqyahInView &&
            const DeepCollectionEquality().equals(other.entries, _entries));
  }

  @override
  int get hashCode {
    return Object.hash(
        runtimeType, const DeepCollectionEquality().hash(_entries));
  }

  @override
  String toString() {
    return 'DuasState.ruqyah(entries: $entries)';
  }
}

/// @nodoc
abstract mixin class $RuqyahInViewCopyWith<$Res>
    implements $DuasStateCopyWith<$Res> {
  factory $RuqyahInViewCopyWith(
          RuqyahInView value, $Res Function(RuqyahInView) _then) =
      _$RuqyahInViewCopyWithImpl;
  @useResult
  $Res call({List<RuqyahResolved> entries});
}

/// @nodoc
class _$RuqyahInViewCopyWithImpl<$Res> implements $RuqyahInViewCopyWith<$Res> {
  _$RuqyahInViewCopyWithImpl(this._self, this._then);

  final RuqyahInView _self;
  final $Res Function(RuqyahInView) _then;

  /// Create a copy of DuasState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? entries = null,
  }) {
    return _then(RuqyahInView(
      entries: null == entries
          ? _self._entries
          : entries // ignore: cast_nullable_to_non_nullable
              as List<RuqyahResolved>,
    ));
  }
}

// dart format on

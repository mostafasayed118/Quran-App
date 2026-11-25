// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feelings_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FeelingsState {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FeelingsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'FeelingsState()';
}


}

/// @nodoc
class $FeelingsStateCopyWith<$Res>  {
$FeelingsStateCopyWith(FeelingsState _, $Res Function(FeelingsState) __);
}


/// Adds pattern-matching-related methods to [FeelingsState].
extension FeelingsStatePatterns on FeelingsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( FeelingsLoading value)?  loading,TResult Function( FeelingsFailed value)?  failed,TResult Function( FeelingsReady value)?  ready,required TResult orElse(),}){
final _that = this;
switch (_that) {
case FeelingsLoading() when loading != null:
return loading(_that);case FeelingsFailed() when failed != null:
return failed(_that);case FeelingsReady() when ready != null:
return ready(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( FeelingsLoading value)  loading,required TResult Function( FeelingsFailed value)  failed,required TResult Function( FeelingsReady value)  ready,}){
final _that = this;
switch (_that) {
case FeelingsLoading():
return loading(_that);case FeelingsFailed():
return failed(_that);case FeelingsReady():
return ready(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( FeelingsLoading value)?  loading,TResult? Function( FeelingsFailed value)?  failed,TResult? Function( FeelingsReady value)?  ready,}){
final _that = this;
switch (_that) {
case FeelingsLoading() when loading != null:
return loading(_that);case FeelingsFailed() when failed != null:
return failed(_that);case FeelingsReady() when ready != null:
return ready(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function()?  failed,TResult Function( List<Feeling> feelings,  String heroExcerpt,  int savedCount)?  ready,required TResult orElse(),}) {final _that = this;
switch (_that) {
case FeelingsLoading() when loading != null:
return loading();case FeelingsFailed() when failed != null:
return failed();case FeelingsReady() when ready != null:
return ready(_that.feelings,_that.heroExcerpt,_that.savedCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function()  failed,required TResult Function( List<Feeling> feelings,  String heroExcerpt,  int savedCount)  ready,}) {final _that = this;
switch (_that) {
case FeelingsLoading():
return loading();case FeelingsFailed():
return failed();case FeelingsReady():
return ready(_that.feelings,_that.heroExcerpt,_that.savedCount);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function()?  failed,TResult? Function( List<Feeling> feelings,  String heroExcerpt,  int savedCount)?  ready,}) {final _that = this;
switch (_that) {
case FeelingsLoading() when loading != null:
return loading();case FeelingsFailed() when failed != null:
return failed();case FeelingsReady() when ready != null:
return ready(_that.feelings,_that.heroExcerpt,_that.savedCount);case _:
  return null;

}
}

}

/// @nodoc


class FeelingsLoading implements FeelingsState {
  const FeelingsLoading();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FeelingsLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'FeelingsState.loading()';
}


}




/// @nodoc


class FeelingsFailed implements FeelingsState {
  const FeelingsFailed();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FeelingsFailed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'FeelingsState.failed()';
}


}




/// @nodoc


class FeelingsReady implements FeelingsState {
  const FeelingsReady({required  List<Feeling> feelings, required this.heroExcerpt, required this.savedCount}): _feelings = feelings;
  

 final  List<Feeling> _feelings;
 List<Feeling> get feelings {
  if (_feelings is EqualUnmodifiableListView) return _feelings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_feelings);
}

 final  String heroExcerpt;
 final  int savedCount;

/// Create a copy of FeelingsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeelingsReadyCopyWith<FeelingsReady> get copyWith => _$FeelingsReadyCopyWithImpl<FeelingsReady>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FeelingsReady&&const DeepCollectionEquality().equals(other.feelings, _feelings)&&(identical(other.heroExcerpt, heroExcerpt) || other.heroExcerpt == heroExcerpt)&&(identical(other.savedCount, savedCount) || other.savedCount == savedCount));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_feelings),heroExcerpt,savedCount);
}

@override
String toString() {
    return 'FeelingsState.ready(feelings: $feelings, heroExcerpt: $heroExcerpt, savedCount: $savedCount)';
}


}

/// @nodoc
abstract mixin class $FeelingsReadyCopyWith<$Res> implements $FeelingsStateCopyWith<$Res> {
  factory $FeelingsReadyCopyWith(FeelingsReady value, $Res Function(FeelingsReady) _then) = _$FeelingsReadyCopyWithImpl;
@useResult
$Res call({
 List<Feeling> feelings, String heroExcerpt, int savedCount
});




}
/// @nodoc
class _$FeelingsReadyCopyWithImpl<$Res>
    implements $FeelingsReadyCopyWith<$Res> {
  _$FeelingsReadyCopyWithImpl(this._self, this._then);

  final FeelingsReady _self;
  final $Res Function(FeelingsReady) _then;

/// Create a copy of FeelingsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? feelings = null,Object? heroExcerpt = null,Object? savedCount = null,}) {
  return _then(FeelingsReady(
feelings: null == feelings ? _self._feelings : feelings // ignore: cast_nullable_to_non_nullable
as List<Feeling>,heroExcerpt: null == heroExcerpt ? _self.heroExcerpt : heroExcerpt // ignore: cast_nullable_to_non_nullable
as String,savedCount: null == savedCount ? _self.savedCount : savedCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$FeelingVersesState {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FeelingVersesState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'FeelingVersesState()';
}


}

/// @nodoc
class $FeelingVersesStateCopyWith<$Res>  {
$FeelingVersesStateCopyWith(FeelingVersesState _, $Res Function(FeelingVersesState) __);
}


/// Adds pattern-matching-related methods to [FeelingVersesState].
extension FeelingVersesStatePatterns on FeelingVersesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( FeelingVersesLoading value)?  loading,TResult Function( FeelingVersesFailed value)?  failed,TResult Function( FeelingVersesReady value)?  ready,required TResult orElse(),}){
final _that = this;
switch (_that) {
case FeelingVersesLoading() when loading != null:
return loading(_that);case FeelingVersesFailed() when failed != null:
return failed(_that);case FeelingVersesReady() when ready != null:
return ready(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( FeelingVersesLoading value)  loading,required TResult Function( FeelingVersesFailed value)  failed,required TResult Function( FeelingVersesReady value)  ready,}){
final _that = this;
switch (_that) {
case FeelingVersesLoading():
return loading(_that);case FeelingVersesFailed():
return failed(_that);case FeelingVersesReady():
return ready(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( FeelingVersesLoading value)?  loading,TResult? Function( FeelingVersesFailed value)?  failed,TResult? Function( FeelingVersesReady value)?  ready,}){
final _that = this;
switch (_that) {
case FeelingVersesLoading() when loading != null:
return loading(_that);case FeelingVersesFailed() when failed != null:
return failed(_that);case FeelingVersesReady() when ready != null:
return ready(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function()?  failed,TResult Function( FeelingKey feeling,  List<FeelingVerseView> verses)?  ready,required TResult orElse(),}) {final _that = this;
switch (_that) {
case FeelingVersesLoading() when loading != null:
return loading();case FeelingVersesFailed() when failed != null:
return failed();case FeelingVersesReady() when ready != null:
return ready(_that.feeling,_that.verses);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function()  failed,required TResult Function( FeelingKey feeling,  List<FeelingVerseView> verses)  ready,}) {final _that = this;
switch (_that) {
case FeelingVersesLoading():
return loading();case FeelingVersesFailed():
return failed();case FeelingVersesReady():
return ready(_that.feeling,_that.verses);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function()?  failed,TResult? Function( FeelingKey feeling,  List<FeelingVerseView> verses)?  ready,}) {final _that = this;
switch (_that) {
case FeelingVersesLoading() when loading != null:
return loading();case FeelingVersesFailed() when failed != null:
return failed();case FeelingVersesReady() when ready != null:
return ready(_that.feeling,_that.verses);case _:
  return null;

}
}

}

/// @nodoc


class FeelingVersesLoading implements FeelingVersesState {
  const FeelingVersesLoading();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FeelingVersesLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'FeelingVersesState.loading()';
}


}




/// @nodoc


class FeelingVersesFailed implements FeelingVersesState {
  const FeelingVersesFailed();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FeelingVersesFailed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'FeelingVersesState.failed()';
}


}




/// @nodoc


class FeelingVersesReady implements FeelingVersesState {
  const FeelingVersesReady({required this.feeling, required  List<FeelingVerseView> verses}): _verses = verses;
  

 final  FeelingKey feeling;
 final  List<FeelingVerseView> _verses;
 List<FeelingVerseView> get verses {
  if (_verses is EqualUnmodifiableListView) return _verses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_verses);
}


/// Create a copy of FeelingVersesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeelingVersesReadyCopyWith<FeelingVersesReady> get copyWith => _$FeelingVersesReadyCopyWithImpl<FeelingVersesReady>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FeelingVersesReady&&(identical(other.feeling, feeling) || other.feeling == feeling)&&const DeepCollectionEquality().equals(other.verses, _verses));
}


@override
int get hashCode {
    return Object.hash(runtimeType,feeling,const DeepCollectionEquality().hash(_verses));
}

@override
String toString() {
    return 'FeelingVersesState.ready(feeling: $feeling, verses: $verses)';
}


}

/// @nodoc
abstract mixin class $FeelingVersesReadyCopyWith<$Res> implements $FeelingVersesStateCopyWith<$Res> {
  factory $FeelingVersesReadyCopyWith(FeelingVersesReady value, $Res Function(FeelingVersesReady) _then) = _$FeelingVersesReadyCopyWithImpl;
@useResult
$Res call({
 FeelingKey feeling, List<FeelingVerseView> verses
});




}
/// @nodoc
class _$FeelingVersesReadyCopyWithImpl<$Res>
    implements $FeelingVersesReadyCopyWith<$Res> {
  _$FeelingVersesReadyCopyWithImpl(this._self, this._then);

  final FeelingVersesReady _self;
  final $Res Function(FeelingVersesReady) _then;

/// Create a copy of FeelingVersesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? feeling = null,Object? verses = null,}) {
  return _then(FeelingVersesReady(
feeling: null == feeling ? _self.feeling : feeling // ignore: cast_nullable_to_non_nullable
as FeelingKey,verses: null == verses ? _self._verses : verses // ignore: cast_nullable_to_non_nullable
as List<FeelingVerseView>,
  ));
}


}

/// @nodoc
mixin _$VerseDetailState {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is VerseDetailState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'VerseDetailState()';
}


}

/// @nodoc
class $VerseDetailStateCopyWith<$Res>  {
$VerseDetailStateCopyWith(VerseDetailState _, $Res Function(VerseDetailState) __);
}


/// Adds pattern-matching-related methods to [VerseDetailState].
extension VerseDetailStatePatterns on VerseDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( VerseDetailLoading value)?  loading,TResult Function( VerseDetailFailed value)?  failed,TResult Function( VerseDetailReady value)?  ready,required TResult orElse(),}){
final _that = this;
switch (_that) {
case VerseDetailLoading() when loading != null:
return loading(_that);case VerseDetailFailed() when failed != null:
return failed(_that);case VerseDetailReady() when ready != null:
return ready(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( VerseDetailLoading value)  loading,required TResult Function( VerseDetailFailed value)  failed,required TResult Function( VerseDetailReady value)  ready,}){
final _that = this;
switch (_that) {
case VerseDetailLoading():
return loading(_that);case VerseDetailFailed():
return failed(_that);case VerseDetailReady():
return ready(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( VerseDetailLoading value)?  loading,TResult? Function( VerseDetailFailed value)?  failed,TResult? Function( VerseDetailReady value)?  ready,}){
final _that = this;
switch (_that) {
case VerseDetailLoading() when loading != null:
return loading(_that);case VerseDetailFailed() when failed != null:
return failed(_that);case VerseDetailReady() when ready != null:
return ready(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function()?  failed,TResult Function( FeelingVerseView verse,  bool isSaved)?  ready,required TResult orElse(),}) {final _that = this;
switch (_that) {
case VerseDetailLoading() when loading != null:
return loading();case VerseDetailFailed() when failed != null:
return failed();case VerseDetailReady() when ready != null:
return ready(_that.verse,_that.isSaved);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function()  failed,required TResult Function( FeelingVerseView verse,  bool isSaved)  ready,}) {final _that = this;
switch (_that) {
case VerseDetailLoading():
return loading();case VerseDetailFailed():
return failed();case VerseDetailReady():
return ready(_that.verse,_that.isSaved);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function()?  failed,TResult? Function( FeelingVerseView verse,  bool isSaved)?  ready,}) {final _that = this;
switch (_that) {
case VerseDetailLoading() when loading != null:
return loading();case VerseDetailFailed() when failed != null:
return failed();case VerseDetailReady() when ready != null:
return ready(_that.verse,_that.isSaved);case _:
  return null;

}
}

}

/// @nodoc


class VerseDetailLoading implements VerseDetailState {
  const VerseDetailLoading();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is VerseDetailLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'VerseDetailState.loading()';
}


}




/// @nodoc


class VerseDetailFailed implements VerseDetailState {
  const VerseDetailFailed();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is VerseDetailFailed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'VerseDetailState.failed()';
}


}




/// @nodoc


class VerseDetailReady implements VerseDetailState {
  const VerseDetailReady({required this.verse, required this.isSaved});
  

 final  FeelingVerseView verse;
 final  bool isSaved;

/// Create a copy of VerseDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerseDetailReadyCopyWith<VerseDetailReady> get copyWith => _$VerseDetailReadyCopyWithImpl<VerseDetailReady>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is VerseDetailReady&&(identical(other.verse, verse) || other.verse == verse)&&(identical(other.isSaved, isSaved) || other.isSaved == isSaved));
}


@override
int get hashCode {
    return Object.hash(runtimeType,verse,isSaved);
}

@override
String toString() {
    return 'VerseDetailState.ready(verse: $verse, isSaved: $isSaved)';
}


}

/// @nodoc
abstract mixin class $VerseDetailReadyCopyWith<$Res> implements $VerseDetailStateCopyWith<$Res> {
  factory $VerseDetailReadyCopyWith(VerseDetailReady value, $Res Function(VerseDetailReady) _then) = _$VerseDetailReadyCopyWithImpl;
@useResult
$Res call({
 FeelingVerseView verse, bool isSaved
});




}
/// @nodoc
class _$VerseDetailReadyCopyWithImpl<$Res>
    implements $VerseDetailReadyCopyWith<$Res> {
  _$VerseDetailReadyCopyWithImpl(this._self, this._then);

  final VerseDetailReady _self;
  final $Res Function(VerseDetailReady) _then;

/// Create a copy of VerseDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? verse = null,Object? isSaved = null,}) {
  return _then(VerseDetailReady(
verse: null == verse ? _self.verse : verse // ignore: cast_nullable_to_non_nullable
as FeelingVerseView,isSaved: null == isSaved ? _self.isSaved : isSaved // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$SavedVersesState {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SavedVersesState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SavedVersesState()';
}


}

/// @nodoc
class $SavedVersesStateCopyWith<$Res>  {
$SavedVersesStateCopyWith(SavedVersesState _, $Res Function(SavedVersesState) __);
}


/// Adds pattern-matching-related methods to [SavedVersesState].
extension SavedVersesStatePatterns on SavedVersesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SavedVersesLoading value)?  loading,TResult Function( SavedVersesReady value)?  ready,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SavedVersesLoading() when loading != null:
return loading(_that);case SavedVersesReady() when ready != null:
return ready(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SavedVersesLoading value)  loading,required TResult Function( SavedVersesReady value)  ready,}){
final _that = this;
switch (_that) {
case SavedVersesLoading():
return loading(_that);case SavedVersesReady():
return ready(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SavedVersesLoading value)?  loading,TResult? Function( SavedVersesReady value)?  ready,}){
final _that = this;
switch (_that) {
case SavedVersesLoading() when loading != null:
return loading(_that);case SavedVersesReady() when ready != null:
return ready(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<SavedFeelingVerse> verses,  Map<int, AyahRef> refs)?  ready,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SavedVersesLoading() when loading != null:
return loading();case SavedVersesReady() when ready != null:
return ready(_that.verses,_that.refs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<SavedFeelingVerse> verses,  Map<int, AyahRef> refs)  ready,}) {final _that = this;
switch (_that) {
case SavedVersesLoading():
return loading();case SavedVersesReady():
return ready(_that.verses,_that.refs);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<SavedFeelingVerse> verses,  Map<int, AyahRef> refs)?  ready,}) {final _that = this;
switch (_that) {
case SavedVersesLoading() when loading != null:
return loading();case SavedVersesReady() when ready != null:
return ready(_that.verses,_that.refs);case _:
  return null;

}
}

}

/// @nodoc


class SavedVersesLoading implements SavedVersesState {
  const SavedVersesLoading();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SavedVersesLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SavedVersesState.loading()';
}


}




/// @nodoc


class SavedVersesReady implements SavedVersesState {
  const SavedVersesReady({required  List<SavedFeelingVerse> verses,  Map<int, AyahRef> refs = const <int, AyahRef>{}}): _verses = verses,_refs = refs;
  

 final  List<SavedFeelingVerse> _verses;
 List<SavedFeelingVerse> get verses {
  if (_verses is EqualUnmodifiableListView) return _verses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_verses);
}

/// Resolved surah:ayah labels, keyed by global ayah id. Missing ids are
/// absent, so the list still renders with the feeling-name fallback.
 final  Map<int, AyahRef> _refs;
/// Resolved surah:ayah labels, keyed by global ayah id. Missing ids are
/// absent, so the list still renders with the feeling-name fallback.
@JsonKey() Map<int, AyahRef> get refs {
  if (_refs is EqualUnmodifiableMapView) return _refs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_refs);
}


/// Create a copy of SavedVersesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavedVersesReadyCopyWith<SavedVersesReady> get copyWith => _$SavedVersesReadyCopyWithImpl<SavedVersesReady>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SavedVersesReady&&const DeepCollectionEquality().equals(other.verses, _verses)&&const DeepCollectionEquality().equals(other.refs, _refs));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_verses),const DeepCollectionEquality().hash(_refs));
}

@override
String toString() {
    return 'SavedVersesState.ready(verses: $verses, refs: $refs)';
}


}

/// @nodoc
abstract mixin class $SavedVersesReadyCopyWith<$Res> implements $SavedVersesStateCopyWith<$Res> {
  factory $SavedVersesReadyCopyWith(SavedVersesReady value, $Res Function(SavedVersesReady) _then) = _$SavedVersesReadyCopyWithImpl;
@useResult
$Res call({
 List<SavedFeelingVerse> verses, Map<int, AyahRef> refs
});




}
/// @nodoc
class _$SavedVersesReadyCopyWithImpl<$Res>
    implements $SavedVersesReadyCopyWith<$Res> {
  _$SavedVersesReadyCopyWithImpl(this._self, this._then);

  final SavedVersesReady _self;
  final $Res Function(SavedVersesReady) _then;

/// Create a copy of SavedVersesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? verses = null,Object? refs = null,}) {
  return _then(SavedVersesReady(
verses: null == verses ? _self._verses : verses // ignore: cast_nullable_to_non_nullable
as List<SavedFeelingVerse>,refs: null == refs ? _self._refs : refs // ignore: cast_nullable_to_non_nullable
as Map<int, AyahRef>,
  ));
}


}

// dart format on

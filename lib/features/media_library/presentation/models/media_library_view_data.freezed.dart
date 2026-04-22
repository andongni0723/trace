// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'media_library_view_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MediaLibraryViewData {

 List<MediaLibraryItemViewData> get items;
/// Create a copy of MediaLibraryViewData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MediaLibraryViewDataCopyWith<MediaLibraryViewData> get copyWith => _$MediaLibraryViewDataCopyWithImpl<MediaLibraryViewData>(this as MediaLibraryViewData, _$identity);

  /// Serializes this MediaLibraryViewData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MediaLibraryViewData&&const DeepCollectionEquality().equals(other.items, items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'MediaLibraryViewData(items: $items)';
}


}

/// @nodoc
abstract mixin class $MediaLibraryViewDataCopyWith<$Res>  {
  factory $MediaLibraryViewDataCopyWith(MediaLibraryViewData value, $Res Function(MediaLibraryViewData) _then) = _$MediaLibraryViewDataCopyWithImpl;
@useResult
$Res call({
 List<MediaLibraryItemViewData> items
});




}
/// @nodoc
class _$MediaLibraryViewDataCopyWithImpl<$Res>
    implements $MediaLibraryViewDataCopyWith<$Res> {
  _$MediaLibraryViewDataCopyWithImpl(this._self, this._then);

  final MediaLibraryViewData _self;
  final $Res Function(MediaLibraryViewData) _then;

/// Create a copy of MediaLibraryViewData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<MediaLibraryItemViewData>,
  ));
}

}


/// Adds pattern-matching-related methods to [MediaLibraryViewData].
extension MediaLibraryViewDataPatterns on MediaLibraryViewData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MediaLibraryViewData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MediaLibraryViewData() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MediaLibraryViewData value)  $default,){
final _that = this;
switch (_that) {
case _MediaLibraryViewData():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MediaLibraryViewData value)?  $default,){
final _that = this;
switch (_that) {
case _MediaLibraryViewData() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<MediaLibraryItemViewData> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MediaLibraryViewData() when $default != null:
return $default(_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<MediaLibraryItemViewData> items)  $default,) {final _that = this;
switch (_that) {
case _MediaLibraryViewData():
return $default(_that.items);case _:
  throw StateError('Unexpected subclass');

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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<MediaLibraryItemViewData> items)?  $default,) {final _that = this;
switch (_that) {
case _MediaLibraryViewData() when $default != null:
return $default(_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MediaLibraryViewData implements MediaLibraryViewData {
  const _MediaLibraryViewData({final  List<MediaLibraryItemViewData> items = const <MediaLibraryItemViewData>[]}): _items = items;
  factory _MediaLibraryViewData.fromJson(Map<String, dynamic> json) => _$MediaLibraryViewDataFromJson(json);

 final  List<MediaLibraryItemViewData> _items;
@override@JsonKey() List<MediaLibraryItemViewData> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of MediaLibraryViewData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MediaLibraryViewDataCopyWith<_MediaLibraryViewData> get copyWith => __$MediaLibraryViewDataCopyWithImpl<_MediaLibraryViewData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MediaLibraryViewDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MediaLibraryViewData&&const DeepCollectionEquality().equals(other._items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'MediaLibraryViewData(items: $items)';
}


}

/// @nodoc
abstract mixin class _$MediaLibraryViewDataCopyWith<$Res> implements $MediaLibraryViewDataCopyWith<$Res> {
  factory _$MediaLibraryViewDataCopyWith(_MediaLibraryViewData value, $Res Function(_MediaLibraryViewData) _then) = __$MediaLibraryViewDataCopyWithImpl;
@override @useResult
$Res call({
 List<MediaLibraryItemViewData> items
});




}
/// @nodoc
class __$MediaLibraryViewDataCopyWithImpl<$Res>
    implements _$MediaLibraryViewDataCopyWith<$Res> {
  __$MediaLibraryViewDataCopyWithImpl(this._self, this._then);

  final _MediaLibraryViewData _self;
  final $Res Function(_MediaLibraryViewData) _then;

/// Create a copy of MediaLibraryViewData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,}) {
  return _then(_MediaLibraryViewData(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<MediaLibraryItemViewData>,
  ));
}


}


/// @nodoc
mixin _$MediaLibraryItemViewData {

 String get id; MediaAssetKind get kind; String get name; String get sizeLabel; String? get previewPath;
/// Create a copy of MediaLibraryItemViewData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MediaLibraryItemViewDataCopyWith<MediaLibraryItemViewData> get copyWith => _$MediaLibraryItemViewDataCopyWithImpl<MediaLibraryItemViewData>(this as MediaLibraryItemViewData, _$identity);

  /// Serializes this MediaLibraryItemViewData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MediaLibraryItemViewData&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.name, name) || other.name == name)&&(identical(other.sizeLabel, sizeLabel) || other.sizeLabel == sizeLabel)&&(identical(other.previewPath, previewPath) || other.previewPath == previewPath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,name,sizeLabel,previewPath);

@override
String toString() {
  return 'MediaLibraryItemViewData(id: $id, kind: $kind, name: $name, sizeLabel: $sizeLabel, previewPath: $previewPath)';
}


}

/// @nodoc
abstract mixin class $MediaLibraryItemViewDataCopyWith<$Res>  {
  factory $MediaLibraryItemViewDataCopyWith(MediaLibraryItemViewData value, $Res Function(MediaLibraryItemViewData) _then) = _$MediaLibraryItemViewDataCopyWithImpl;
@useResult
$Res call({
 String id, MediaAssetKind kind, String name, String sizeLabel, String? previewPath
});




}
/// @nodoc
class _$MediaLibraryItemViewDataCopyWithImpl<$Res>
    implements $MediaLibraryItemViewDataCopyWith<$Res> {
  _$MediaLibraryItemViewDataCopyWithImpl(this._self, this._then);

  final MediaLibraryItemViewData _self;
  final $Res Function(MediaLibraryItemViewData) _then;

/// Create a copy of MediaLibraryItemViewData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? name = null,Object? sizeLabel = null,Object? previewPath = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MediaAssetKind,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sizeLabel: null == sizeLabel ? _self.sizeLabel : sizeLabel // ignore: cast_nullable_to_non_nullable
as String,previewPath: freezed == previewPath ? _self.previewPath : previewPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MediaLibraryItemViewData].
extension MediaLibraryItemViewDataPatterns on MediaLibraryItemViewData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MediaLibraryItemViewData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MediaLibraryItemViewData() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MediaLibraryItemViewData value)  $default,){
final _that = this;
switch (_that) {
case _MediaLibraryItemViewData():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MediaLibraryItemViewData value)?  $default,){
final _that = this;
switch (_that) {
case _MediaLibraryItemViewData() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  MediaAssetKind kind,  String name,  String sizeLabel,  String? previewPath)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MediaLibraryItemViewData() when $default != null:
return $default(_that.id,_that.kind,_that.name,_that.sizeLabel,_that.previewPath);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  MediaAssetKind kind,  String name,  String sizeLabel,  String? previewPath)  $default,) {final _that = this;
switch (_that) {
case _MediaLibraryItemViewData():
return $default(_that.id,_that.kind,_that.name,_that.sizeLabel,_that.previewPath);case _:
  throw StateError('Unexpected subclass');

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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  MediaAssetKind kind,  String name,  String sizeLabel,  String? previewPath)?  $default,) {final _that = this;
switch (_that) {
case _MediaLibraryItemViewData() when $default != null:
return $default(_that.id,_that.kind,_that.name,_that.sizeLabel,_that.previewPath);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MediaLibraryItemViewData implements MediaLibraryItemViewData {
  const _MediaLibraryItemViewData({required this.id, required this.kind, required this.name, required this.sizeLabel, this.previewPath});
  factory _MediaLibraryItemViewData.fromJson(Map<String, dynamic> json) => _$MediaLibraryItemViewDataFromJson(json);

@override final  String id;
@override final  MediaAssetKind kind;
@override final  String name;
@override final  String sizeLabel;
@override final  String? previewPath;

/// Create a copy of MediaLibraryItemViewData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MediaLibraryItemViewDataCopyWith<_MediaLibraryItemViewData> get copyWith => __$MediaLibraryItemViewDataCopyWithImpl<_MediaLibraryItemViewData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MediaLibraryItemViewDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MediaLibraryItemViewData&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.name, name) || other.name == name)&&(identical(other.sizeLabel, sizeLabel) || other.sizeLabel == sizeLabel)&&(identical(other.previewPath, previewPath) || other.previewPath == previewPath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,name,sizeLabel,previewPath);

@override
String toString() {
  return 'MediaLibraryItemViewData(id: $id, kind: $kind, name: $name, sizeLabel: $sizeLabel, previewPath: $previewPath)';
}


}

/// @nodoc
abstract mixin class _$MediaLibraryItemViewDataCopyWith<$Res> implements $MediaLibraryItemViewDataCopyWith<$Res> {
  factory _$MediaLibraryItemViewDataCopyWith(_MediaLibraryItemViewData value, $Res Function(_MediaLibraryItemViewData) _then) = __$MediaLibraryItemViewDataCopyWithImpl;
@override @useResult
$Res call({
 String id, MediaAssetKind kind, String name, String sizeLabel, String? previewPath
});




}
/// @nodoc
class __$MediaLibraryItemViewDataCopyWithImpl<$Res>
    implements _$MediaLibraryItemViewDataCopyWith<$Res> {
  __$MediaLibraryItemViewDataCopyWithImpl(this._self, this._then);

  final _MediaLibraryItemViewData _self;
  final $Res Function(_MediaLibraryItemViewData) _then;

/// Create a copy of MediaLibraryItemViewData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? name = null,Object? sizeLabel = null,Object? previewPath = freezed,}) {
  return _then(_MediaLibraryItemViewData(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MediaAssetKind,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sizeLabel: null == sizeLabel ? _self.sizeLabel : sizeLabel // ignore: cast_nullable_to_non_nullable
as String,previewPath: freezed == previewPath ? _self.previewPath : previewPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

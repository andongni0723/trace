// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'biometric_lock_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BiometricLockSettings {

 bool get enabled; BiometricReauthInterval get reauthInterval; DateTime? get lastVerifiedAt;
/// Create a copy of BiometricLockSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BiometricLockSettingsCopyWith<BiometricLockSettings> get copyWith => _$BiometricLockSettingsCopyWithImpl<BiometricLockSettings>(this as BiometricLockSettings, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BiometricLockSettings&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.reauthInterval, reauthInterval) || other.reauthInterval == reauthInterval)&&(identical(other.lastVerifiedAt, lastVerifiedAt) || other.lastVerifiedAt == lastVerifiedAt));
}


@override
int get hashCode => Object.hash(runtimeType,enabled,reauthInterval,lastVerifiedAt);

@override
String toString() {
  return 'BiometricLockSettings(enabled: $enabled, reauthInterval: $reauthInterval, lastVerifiedAt: $lastVerifiedAt)';
}


}

/// @nodoc
abstract mixin class $BiometricLockSettingsCopyWith<$Res>  {
  factory $BiometricLockSettingsCopyWith(BiometricLockSettings value, $Res Function(BiometricLockSettings) _then) = _$BiometricLockSettingsCopyWithImpl;
@useResult
$Res call({
 bool enabled, BiometricReauthInterval reauthInterval, DateTime? lastVerifiedAt
});




}
/// @nodoc
class _$BiometricLockSettingsCopyWithImpl<$Res>
    implements $BiometricLockSettingsCopyWith<$Res> {
  _$BiometricLockSettingsCopyWithImpl(this._self, this._then);

  final BiometricLockSettings _self;
  final $Res Function(BiometricLockSettings) _then;

/// Create a copy of BiometricLockSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? reauthInterval = null,Object? lastVerifiedAt = freezed,}) {
  return _then(_self.copyWith(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,reauthInterval: null == reauthInterval ? _self.reauthInterval : reauthInterval // ignore: cast_nullable_to_non_nullable
as BiometricReauthInterval,lastVerifiedAt: freezed == lastVerifiedAt ? _self.lastVerifiedAt : lastVerifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [BiometricLockSettings].
extension BiometricLockSettingsPatterns on BiometricLockSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BiometricLockSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BiometricLockSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BiometricLockSettings value)  $default,){
final _that = this;
switch (_that) {
case _BiometricLockSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BiometricLockSettings value)?  $default,){
final _that = this;
switch (_that) {
case _BiometricLockSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool enabled,  BiometricReauthInterval reauthInterval,  DateTime? lastVerifiedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BiometricLockSettings() when $default != null:
return $default(_that.enabled,_that.reauthInterval,_that.lastVerifiedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool enabled,  BiometricReauthInterval reauthInterval,  DateTime? lastVerifiedAt)  $default,) {final _that = this;
switch (_that) {
case _BiometricLockSettings():
return $default(_that.enabled,_that.reauthInterval,_that.lastVerifiedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool enabled,  BiometricReauthInterval reauthInterval,  DateTime? lastVerifiedAt)?  $default,) {final _that = this;
switch (_that) {
case _BiometricLockSettings() when $default != null:
return $default(_that.enabled,_that.reauthInterval,_that.lastVerifiedAt);case _:
  return null;

}
}

}

/// @nodoc


class _BiometricLockSettings implements BiometricLockSettings {
  const _BiometricLockSettings({this.enabled = false, this.reauthInterval = BiometricReauthInterval.nextOpen, this.lastVerifiedAt});
  

@override@JsonKey() final  bool enabled;
@override@JsonKey() final  BiometricReauthInterval reauthInterval;
@override final  DateTime? lastVerifiedAt;

/// Create a copy of BiometricLockSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BiometricLockSettingsCopyWith<_BiometricLockSettings> get copyWith => __$BiometricLockSettingsCopyWithImpl<_BiometricLockSettings>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BiometricLockSettings&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.reauthInterval, reauthInterval) || other.reauthInterval == reauthInterval)&&(identical(other.lastVerifiedAt, lastVerifiedAt) || other.lastVerifiedAt == lastVerifiedAt));
}


@override
int get hashCode => Object.hash(runtimeType,enabled,reauthInterval,lastVerifiedAt);

@override
String toString() {
  return 'BiometricLockSettings(enabled: $enabled, reauthInterval: $reauthInterval, lastVerifiedAt: $lastVerifiedAt)';
}


}

/// @nodoc
abstract mixin class _$BiometricLockSettingsCopyWith<$Res> implements $BiometricLockSettingsCopyWith<$Res> {
  factory _$BiometricLockSettingsCopyWith(_BiometricLockSettings value, $Res Function(_BiometricLockSettings) _then) = __$BiometricLockSettingsCopyWithImpl;
@override @useResult
$Res call({
 bool enabled, BiometricReauthInterval reauthInterval, DateTime? lastVerifiedAt
});




}
/// @nodoc
class __$BiometricLockSettingsCopyWithImpl<$Res>
    implements _$BiometricLockSettingsCopyWith<$Res> {
  __$BiometricLockSettingsCopyWithImpl(this._self, this._then);

  final _BiometricLockSettings _self;
  final $Res Function(_BiometricLockSettings) _then;

/// Create a copy of BiometricLockSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enabled = null,Object? reauthInterval = null,Object? lastVerifiedAt = freezed,}) {
  return _then(_BiometricLockSettings(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,reauthInterval: null == reauthInterval ? _self.reauthInterval : reauthInterval // ignore: cast_nullable_to_non_nullable
as BiometricReauthInterval,lastVerifiedAt: freezed == lastVerifiedAt ? _self.lastVerifiedAt : lastVerifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'biometric_lock_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BiometricLockState {

 BiometricLockSettings get settings; bool get sessionUnlocked; bool get canAuthenticate; bool get isAuthenticating; String? get lastErrorMessage;
/// Create a copy of BiometricLockState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BiometricLockStateCopyWith<BiometricLockState> get copyWith => _$BiometricLockStateCopyWithImpl<BiometricLockState>(this as BiometricLockState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BiometricLockState&&(identical(other.settings, settings) || other.settings == settings)&&(identical(other.sessionUnlocked, sessionUnlocked) || other.sessionUnlocked == sessionUnlocked)&&(identical(other.canAuthenticate, canAuthenticate) || other.canAuthenticate == canAuthenticate)&&(identical(other.isAuthenticating, isAuthenticating) || other.isAuthenticating == isAuthenticating)&&(identical(other.lastErrorMessage, lastErrorMessage) || other.lastErrorMessage == lastErrorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,settings,sessionUnlocked,canAuthenticate,isAuthenticating,lastErrorMessage);

@override
String toString() {
  return 'BiometricLockState(settings: $settings, sessionUnlocked: $sessionUnlocked, canAuthenticate: $canAuthenticate, isAuthenticating: $isAuthenticating, lastErrorMessage: $lastErrorMessage)';
}


}

/// @nodoc
abstract mixin class $BiometricLockStateCopyWith<$Res>  {
  factory $BiometricLockStateCopyWith(BiometricLockState value, $Res Function(BiometricLockState) _then) = _$BiometricLockStateCopyWithImpl;
@useResult
$Res call({
 BiometricLockSettings settings, bool sessionUnlocked, bool canAuthenticate, bool isAuthenticating, String? lastErrorMessage
});


$BiometricLockSettingsCopyWith<$Res> get settings;

}
/// @nodoc
class _$BiometricLockStateCopyWithImpl<$Res>
    implements $BiometricLockStateCopyWith<$Res> {
  _$BiometricLockStateCopyWithImpl(this._self, this._then);

  final BiometricLockState _self;
  final $Res Function(BiometricLockState) _then;

/// Create a copy of BiometricLockState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? settings = null,Object? sessionUnlocked = null,Object? canAuthenticate = null,Object? isAuthenticating = null,Object? lastErrorMessage = freezed,}) {
  return _then(_self.copyWith(
settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as BiometricLockSettings,sessionUnlocked: null == sessionUnlocked ? _self.sessionUnlocked : sessionUnlocked // ignore: cast_nullable_to_non_nullable
as bool,canAuthenticate: null == canAuthenticate ? _self.canAuthenticate : canAuthenticate // ignore: cast_nullable_to_non_nullable
as bool,isAuthenticating: null == isAuthenticating ? _self.isAuthenticating : isAuthenticating // ignore: cast_nullable_to_non_nullable
as bool,lastErrorMessage: freezed == lastErrorMessage ? _self.lastErrorMessage : lastErrorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of BiometricLockState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BiometricLockSettingsCopyWith<$Res> get settings {
  
  return $BiometricLockSettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}
}


/// Adds pattern-matching-related methods to [BiometricLockState].
extension BiometricLockStatePatterns on BiometricLockState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BiometricLockState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BiometricLockState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BiometricLockState value)  $default,){
final _that = this;
switch (_that) {
case _BiometricLockState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BiometricLockState value)?  $default,){
final _that = this;
switch (_that) {
case _BiometricLockState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BiometricLockSettings settings,  bool sessionUnlocked,  bool canAuthenticate,  bool isAuthenticating,  String? lastErrorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BiometricLockState() when $default != null:
return $default(_that.settings,_that.sessionUnlocked,_that.canAuthenticate,_that.isAuthenticating,_that.lastErrorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BiometricLockSettings settings,  bool sessionUnlocked,  bool canAuthenticate,  bool isAuthenticating,  String? lastErrorMessage)  $default,) {final _that = this;
switch (_that) {
case _BiometricLockState():
return $default(_that.settings,_that.sessionUnlocked,_that.canAuthenticate,_that.isAuthenticating,_that.lastErrorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BiometricLockSettings settings,  bool sessionUnlocked,  bool canAuthenticate,  bool isAuthenticating,  String? lastErrorMessage)?  $default,) {final _that = this;
switch (_that) {
case _BiometricLockState() when $default != null:
return $default(_that.settings,_that.sessionUnlocked,_that.canAuthenticate,_that.isAuthenticating,_that.lastErrorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _BiometricLockState extends BiometricLockState {
  const _BiometricLockState({required this.settings, this.sessionUnlocked = false, this.canAuthenticate = false, this.isAuthenticating = false, this.lastErrorMessage}): super._();
  

@override final  BiometricLockSettings settings;
@override@JsonKey() final  bool sessionUnlocked;
@override@JsonKey() final  bool canAuthenticate;
@override@JsonKey() final  bool isAuthenticating;
@override final  String? lastErrorMessage;

/// Create a copy of BiometricLockState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BiometricLockStateCopyWith<_BiometricLockState> get copyWith => __$BiometricLockStateCopyWithImpl<_BiometricLockState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BiometricLockState&&(identical(other.settings, settings) || other.settings == settings)&&(identical(other.sessionUnlocked, sessionUnlocked) || other.sessionUnlocked == sessionUnlocked)&&(identical(other.canAuthenticate, canAuthenticate) || other.canAuthenticate == canAuthenticate)&&(identical(other.isAuthenticating, isAuthenticating) || other.isAuthenticating == isAuthenticating)&&(identical(other.lastErrorMessage, lastErrorMessage) || other.lastErrorMessage == lastErrorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,settings,sessionUnlocked,canAuthenticate,isAuthenticating,lastErrorMessage);

@override
String toString() {
  return 'BiometricLockState(settings: $settings, sessionUnlocked: $sessionUnlocked, canAuthenticate: $canAuthenticate, isAuthenticating: $isAuthenticating, lastErrorMessage: $lastErrorMessage)';
}


}

/// @nodoc
abstract mixin class _$BiometricLockStateCopyWith<$Res> implements $BiometricLockStateCopyWith<$Res> {
  factory _$BiometricLockStateCopyWith(_BiometricLockState value, $Res Function(_BiometricLockState) _then) = __$BiometricLockStateCopyWithImpl;
@override @useResult
$Res call({
 BiometricLockSettings settings, bool sessionUnlocked, bool canAuthenticate, bool isAuthenticating, String? lastErrorMessage
});


@override $BiometricLockSettingsCopyWith<$Res> get settings;

}
/// @nodoc
class __$BiometricLockStateCopyWithImpl<$Res>
    implements _$BiometricLockStateCopyWith<$Res> {
  __$BiometricLockStateCopyWithImpl(this._self, this._then);

  final _BiometricLockState _self;
  final $Res Function(_BiometricLockState) _then;

/// Create a copy of BiometricLockState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? settings = null,Object? sessionUnlocked = null,Object? canAuthenticate = null,Object? isAuthenticating = null,Object? lastErrorMessage = freezed,}) {
  return _then(_BiometricLockState(
settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as BiometricLockSettings,sessionUnlocked: null == sessionUnlocked ? _self.sessionUnlocked : sessionUnlocked // ignore: cast_nullable_to_non_nullable
as bool,canAuthenticate: null == canAuthenticate ? _self.canAuthenticate : canAuthenticate // ignore: cast_nullable_to_non_nullable
as bool,isAuthenticating: null == isAuthenticating ? _self.isAuthenticating : isAuthenticating // ignore: cast_nullable_to_non_nullable
as bool,lastErrorMessage: freezed == lastErrorMessage ? _self.lastErrorMessage : lastErrorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of BiometricLockState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BiometricLockSettingsCopyWith<$Res> get settings {
  
  return $BiometricLockSettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}
}

// dart format on

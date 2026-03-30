// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'biometric_lock_policy.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BiometricLockDecision {

 BiometricLockTrigger get trigger; bool get shouldPrompt; String get reason; DateTime? get nextCheckAt;
/// Create a copy of BiometricLockDecision
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BiometricLockDecisionCopyWith<BiometricLockDecision> get copyWith => _$BiometricLockDecisionCopyWithImpl<BiometricLockDecision>(this as BiometricLockDecision, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BiometricLockDecision&&(identical(other.trigger, trigger) || other.trigger == trigger)&&(identical(other.shouldPrompt, shouldPrompt) || other.shouldPrompt == shouldPrompt)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.nextCheckAt, nextCheckAt) || other.nextCheckAt == nextCheckAt));
}


@override
int get hashCode => Object.hash(runtimeType,trigger,shouldPrompt,reason,nextCheckAt);

@override
String toString() {
  return 'BiometricLockDecision(trigger: $trigger, shouldPrompt: $shouldPrompt, reason: $reason, nextCheckAt: $nextCheckAt)';
}


}

/// @nodoc
abstract mixin class $BiometricLockDecisionCopyWith<$Res>  {
  factory $BiometricLockDecisionCopyWith(BiometricLockDecision value, $Res Function(BiometricLockDecision) _then) = _$BiometricLockDecisionCopyWithImpl;
@useResult
$Res call({
 BiometricLockTrigger trigger, bool shouldPrompt, String reason, DateTime? nextCheckAt
});




}
/// @nodoc
class _$BiometricLockDecisionCopyWithImpl<$Res>
    implements $BiometricLockDecisionCopyWith<$Res> {
  _$BiometricLockDecisionCopyWithImpl(this._self, this._then);

  final BiometricLockDecision _self;
  final $Res Function(BiometricLockDecision) _then;

/// Create a copy of BiometricLockDecision
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? trigger = null,Object? shouldPrompt = null,Object? reason = null,Object? nextCheckAt = freezed,}) {
  return _then(_self.copyWith(
trigger: null == trigger ? _self.trigger : trigger // ignore: cast_nullable_to_non_nullable
as BiometricLockTrigger,shouldPrompt: null == shouldPrompt ? _self.shouldPrompt : shouldPrompt // ignore: cast_nullable_to_non_nullable
as bool,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,nextCheckAt: freezed == nextCheckAt ? _self.nextCheckAt : nextCheckAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [BiometricLockDecision].
extension BiometricLockDecisionPatterns on BiometricLockDecision {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BiometricLockDecision value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BiometricLockDecision() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BiometricLockDecision value)  $default,){
final _that = this;
switch (_that) {
case _BiometricLockDecision():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BiometricLockDecision value)?  $default,){
final _that = this;
switch (_that) {
case _BiometricLockDecision() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BiometricLockTrigger trigger,  bool shouldPrompt,  String reason,  DateTime? nextCheckAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BiometricLockDecision() when $default != null:
return $default(_that.trigger,_that.shouldPrompt,_that.reason,_that.nextCheckAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BiometricLockTrigger trigger,  bool shouldPrompt,  String reason,  DateTime? nextCheckAt)  $default,) {final _that = this;
switch (_that) {
case _BiometricLockDecision():
return $default(_that.trigger,_that.shouldPrompt,_that.reason,_that.nextCheckAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BiometricLockTrigger trigger,  bool shouldPrompt,  String reason,  DateTime? nextCheckAt)?  $default,) {final _that = this;
switch (_that) {
case _BiometricLockDecision() when $default != null:
return $default(_that.trigger,_that.shouldPrompt,_that.reason,_that.nextCheckAt);case _:
  return null;

}
}

}

/// @nodoc


class _BiometricLockDecision implements BiometricLockDecision {
  const _BiometricLockDecision({required this.trigger, required this.shouldPrompt, required this.reason, this.nextCheckAt});
  

@override final  BiometricLockTrigger trigger;
@override final  bool shouldPrompt;
@override final  String reason;
@override final  DateTime? nextCheckAt;

/// Create a copy of BiometricLockDecision
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BiometricLockDecisionCopyWith<_BiometricLockDecision> get copyWith => __$BiometricLockDecisionCopyWithImpl<_BiometricLockDecision>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BiometricLockDecision&&(identical(other.trigger, trigger) || other.trigger == trigger)&&(identical(other.shouldPrompt, shouldPrompt) || other.shouldPrompt == shouldPrompt)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.nextCheckAt, nextCheckAt) || other.nextCheckAt == nextCheckAt));
}


@override
int get hashCode => Object.hash(runtimeType,trigger,shouldPrompt,reason,nextCheckAt);

@override
String toString() {
  return 'BiometricLockDecision(trigger: $trigger, shouldPrompt: $shouldPrompt, reason: $reason, nextCheckAt: $nextCheckAt)';
}


}

/// @nodoc
abstract mixin class _$BiometricLockDecisionCopyWith<$Res> implements $BiometricLockDecisionCopyWith<$Res> {
  factory _$BiometricLockDecisionCopyWith(_BiometricLockDecision value, $Res Function(_BiometricLockDecision) _then) = __$BiometricLockDecisionCopyWithImpl;
@override @useResult
$Res call({
 BiometricLockTrigger trigger, bool shouldPrompt, String reason, DateTime? nextCheckAt
});




}
/// @nodoc
class __$BiometricLockDecisionCopyWithImpl<$Res>
    implements _$BiometricLockDecisionCopyWith<$Res> {
  __$BiometricLockDecisionCopyWithImpl(this._self, this._then);

  final _BiometricLockDecision _self;
  final $Res Function(_BiometricLockDecision) _then;

/// Create a copy of BiometricLockDecision
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? trigger = null,Object? shouldPrompt = null,Object? reason = null,Object? nextCheckAt = freezed,}) {
  return _then(_BiometricLockDecision(
trigger: null == trigger ? _self.trigger : trigger // ignore: cast_nullable_to_non_nullable
as BiometricLockTrigger,shouldPrompt: null == shouldPrompt ? _self.shouldPrompt : shouldPrompt // ignore: cast_nullable_to_non_nullable
as bool,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,nextCheckAt: freezed == nextCheckAt ? _self.nextCheckAt : nextCheckAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$BiometricLockOutcome {

 BiometricLockDecision get decision; bool get attemptedAuthentication; bool get authenticated; String? get failureMessage;
/// Create a copy of BiometricLockOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BiometricLockOutcomeCopyWith<BiometricLockOutcome> get copyWith => _$BiometricLockOutcomeCopyWithImpl<BiometricLockOutcome>(this as BiometricLockOutcome, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BiometricLockOutcome&&(identical(other.decision, decision) || other.decision == decision)&&(identical(other.attemptedAuthentication, attemptedAuthentication) || other.attemptedAuthentication == attemptedAuthentication)&&(identical(other.authenticated, authenticated) || other.authenticated == authenticated)&&(identical(other.failureMessage, failureMessage) || other.failureMessage == failureMessage));
}


@override
int get hashCode => Object.hash(runtimeType,decision,attemptedAuthentication,authenticated,failureMessage);

@override
String toString() {
  return 'BiometricLockOutcome(decision: $decision, attemptedAuthentication: $attemptedAuthentication, authenticated: $authenticated, failureMessage: $failureMessage)';
}


}

/// @nodoc
abstract mixin class $BiometricLockOutcomeCopyWith<$Res>  {
  factory $BiometricLockOutcomeCopyWith(BiometricLockOutcome value, $Res Function(BiometricLockOutcome) _then) = _$BiometricLockOutcomeCopyWithImpl;
@useResult
$Res call({
 BiometricLockDecision decision, bool attemptedAuthentication, bool authenticated, String? failureMessage
});


$BiometricLockDecisionCopyWith<$Res> get decision;

}
/// @nodoc
class _$BiometricLockOutcomeCopyWithImpl<$Res>
    implements $BiometricLockOutcomeCopyWith<$Res> {
  _$BiometricLockOutcomeCopyWithImpl(this._self, this._then);

  final BiometricLockOutcome _self;
  final $Res Function(BiometricLockOutcome) _then;

/// Create a copy of BiometricLockOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? decision = null,Object? attemptedAuthentication = null,Object? authenticated = null,Object? failureMessage = freezed,}) {
  return _then(_self.copyWith(
decision: null == decision ? _self.decision : decision // ignore: cast_nullable_to_non_nullable
as BiometricLockDecision,attemptedAuthentication: null == attemptedAuthentication ? _self.attemptedAuthentication : attemptedAuthentication // ignore: cast_nullable_to_non_nullable
as bool,authenticated: null == authenticated ? _self.authenticated : authenticated // ignore: cast_nullable_to_non_nullable
as bool,failureMessage: freezed == failureMessage ? _self.failureMessage : failureMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of BiometricLockOutcome
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BiometricLockDecisionCopyWith<$Res> get decision {
  
  return $BiometricLockDecisionCopyWith<$Res>(_self.decision, (value) {
    return _then(_self.copyWith(decision: value));
  });
}
}


/// Adds pattern-matching-related methods to [BiometricLockOutcome].
extension BiometricLockOutcomePatterns on BiometricLockOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BiometricLockOutcome value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BiometricLockOutcome() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BiometricLockOutcome value)  $default,){
final _that = this;
switch (_that) {
case _BiometricLockOutcome():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BiometricLockOutcome value)?  $default,){
final _that = this;
switch (_that) {
case _BiometricLockOutcome() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BiometricLockDecision decision,  bool attemptedAuthentication,  bool authenticated,  String? failureMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BiometricLockOutcome() when $default != null:
return $default(_that.decision,_that.attemptedAuthentication,_that.authenticated,_that.failureMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BiometricLockDecision decision,  bool attemptedAuthentication,  bool authenticated,  String? failureMessage)  $default,) {final _that = this;
switch (_that) {
case _BiometricLockOutcome():
return $default(_that.decision,_that.attemptedAuthentication,_that.authenticated,_that.failureMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BiometricLockDecision decision,  bool attemptedAuthentication,  bool authenticated,  String? failureMessage)?  $default,) {final _that = this;
switch (_that) {
case _BiometricLockOutcome() when $default != null:
return $default(_that.decision,_that.attemptedAuthentication,_that.authenticated,_that.failureMessage);case _:
  return null;

}
}

}

/// @nodoc


class _BiometricLockOutcome implements BiometricLockOutcome {
  const _BiometricLockOutcome({required this.decision, required this.attemptedAuthentication, required this.authenticated, this.failureMessage});
  

@override final  BiometricLockDecision decision;
@override final  bool attemptedAuthentication;
@override final  bool authenticated;
@override final  String? failureMessage;

/// Create a copy of BiometricLockOutcome
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BiometricLockOutcomeCopyWith<_BiometricLockOutcome> get copyWith => __$BiometricLockOutcomeCopyWithImpl<_BiometricLockOutcome>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BiometricLockOutcome&&(identical(other.decision, decision) || other.decision == decision)&&(identical(other.attemptedAuthentication, attemptedAuthentication) || other.attemptedAuthentication == attemptedAuthentication)&&(identical(other.authenticated, authenticated) || other.authenticated == authenticated)&&(identical(other.failureMessage, failureMessage) || other.failureMessage == failureMessage));
}


@override
int get hashCode => Object.hash(runtimeType,decision,attemptedAuthentication,authenticated,failureMessage);

@override
String toString() {
  return 'BiometricLockOutcome(decision: $decision, attemptedAuthentication: $attemptedAuthentication, authenticated: $authenticated, failureMessage: $failureMessage)';
}


}

/// @nodoc
abstract mixin class _$BiometricLockOutcomeCopyWith<$Res> implements $BiometricLockOutcomeCopyWith<$Res> {
  factory _$BiometricLockOutcomeCopyWith(_BiometricLockOutcome value, $Res Function(_BiometricLockOutcome) _then) = __$BiometricLockOutcomeCopyWithImpl;
@override @useResult
$Res call({
 BiometricLockDecision decision, bool attemptedAuthentication, bool authenticated, String? failureMessage
});


@override $BiometricLockDecisionCopyWith<$Res> get decision;

}
/// @nodoc
class __$BiometricLockOutcomeCopyWithImpl<$Res>
    implements _$BiometricLockOutcomeCopyWith<$Res> {
  __$BiometricLockOutcomeCopyWithImpl(this._self, this._then);

  final _BiometricLockOutcome _self;
  final $Res Function(_BiometricLockOutcome) _then;

/// Create a copy of BiometricLockOutcome
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? decision = null,Object? attemptedAuthentication = null,Object? authenticated = null,Object? failureMessage = freezed,}) {
  return _then(_BiometricLockOutcome(
decision: null == decision ? _self.decision : decision // ignore: cast_nullable_to_non_nullable
as BiometricLockDecision,attemptedAuthentication: null == attemptedAuthentication ? _self.attemptedAuthentication : attemptedAuthentication // ignore: cast_nullable_to_non_nullable
as bool,authenticated: null == authenticated ? _self.authenticated : authenticated // ignore: cast_nullable_to_non_nullable
as bool,failureMessage: freezed == failureMessage ? _self.failureMessage : failureMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of BiometricLockOutcome
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BiometricLockDecisionCopyWith<$Res> get decision {
  
  return $BiometricLockDecisionCopyWith<$Res>(_self.decision, (value) {
    return _then(_self.copyWith(decision: value));
  });
}
}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'source.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Source {

@HiveField(0) String get id;@HiveField(1) String get name;@HiveField(2) SourceType get type;@HiveField(3) String get icon;@HiveField(4) String get color;@HiveField(5) double get initialBalance;
/// Create a copy of Source
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SourceCopyWith<Source> get copyWith => _$SourceCopyWithImpl<Source>(this as Source, _$identity);

  /// Serializes this Source to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Source&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.initialBalance, initialBalance) || other.initialBalance == initialBalance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,icon,color,initialBalance);

@override
String toString() {
  return 'Source(id: $id, name: $name, type: $type, icon: $icon, color: $color, initialBalance: $initialBalance)';
}


}

/// @nodoc
abstract mixin class $SourceCopyWith<$Res>  {
  factory $SourceCopyWith(Source value, $Res Function(Source) _then) = _$SourceCopyWithImpl;
@useResult
$Res call({
@HiveField(0) String id,@HiveField(1) String name,@HiveField(2) SourceType type,@HiveField(3) String icon,@HiveField(4) String color,@HiveField(5) double initialBalance
});




}
/// @nodoc
class _$SourceCopyWithImpl<$Res>
    implements $SourceCopyWith<$Res> {
  _$SourceCopyWithImpl(this._self, this._then);

  final Source _self;
  final $Res Function(Source) _then;

/// Create a copy of Source
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? type = null,Object? icon = null,Object? color = null,Object? initialBalance = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as SourceType,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,initialBalance: null == initialBalance ? _self.initialBalance : initialBalance // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [Source].
extension SourcePatterns on Source {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Source value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Source() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Source value)  $default,){
final _that = this;
switch (_that) {
case _Source():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Source value)?  $default,){
final _that = this;
switch (_that) {
case _Source() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@HiveField(0)  String id, @HiveField(1)  String name, @HiveField(2)  SourceType type, @HiveField(3)  String icon, @HiveField(4)  String color, @HiveField(5)  double initialBalance)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Source() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.icon,_that.color,_that.initialBalance);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@HiveField(0)  String id, @HiveField(1)  String name, @HiveField(2)  SourceType type, @HiveField(3)  String icon, @HiveField(4)  String color, @HiveField(5)  double initialBalance)  $default,) {final _that = this;
switch (_that) {
case _Source():
return $default(_that.id,_that.name,_that.type,_that.icon,_that.color,_that.initialBalance);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@HiveField(0)  String id, @HiveField(1)  String name, @HiveField(2)  SourceType type, @HiveField(3)  String icon, @HiveField(4)  String color, @HiveField(5)  double initialBalance)?  $default,) {final _that = this;
switch (_that) {
case _Source() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.icon,_that.color,_that.initialBalance);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Source implements Source {
  const _Source({@HiveField(0) required this.id, @HiveField(1) required this.name, @HiveField(2) required this.type, @HiveField(3) required this.icon, @HiveField(4) required this.color, @HiveField(5) this.initialBalance = 0.0});
  factory _Source.fromJson(Map<String, dynamic> json) => _$SourceFromJson(json);

@override@HiveField(0) final  String id;
@override@HiveField(1) final  String name;
@override@HiveField(2) final  SourceType type;
@override@HiveField(3) final  String icon;
@override@HiveField(4) final  String color;
@override@JsonKey()@HiveField(5) final  double initialBalance;

/// Create a copy of Source
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SourceCopyWith<_Source> get copyWith => __$SourceCopyWithImpl<_Source>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SourceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Source&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.initialBalance, initialBalance) || other.initialBalance == initialBalance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,icon,color,initialBalance);

@override
String toString() {
  return 'Source(id: $id, name: $name, type: $type, icon: $icon, color: $color, initialBalance: $initialBalance)';
}


}

/// @nodoc
abstract mixin class _$SourceCopyWith<$Res> implements $SourceCopyWith<$Res> {
  factory _$SourceCopyWith(_Source value, $Res Function(_Source) _then) = __$SourceCopyWithImpl;
@override @useResult
$Res call({
@HiveField(0) String id,@HiveField(1) String name,@HiveField(2) SourceType type,@HiveField(3) String icon,@HiveField(4) String color,@HiveField(5) double initialBalance
});




}
/// @nodoc
class __$SourceCopyWithImpl<$Res>
    implements _$SourceCopyWith<$Res> {
  __$SourceCopyWithImpl(this._self, this._then);

  final _Source _self;
  final $Res Function(_Source) _then;

/// Create a copy of Source
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? type = null,Object? icon = null,Object? color = null,Object? initialBalance = null,}) {
  return _then(_Source(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as SourceType,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,initialBalance: null == initialBalance ? _self.initialBalance : initialBalance // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$TransactionSourceSplit {

@HiveField(0) String get sourceId;@HiveField(1) double get amount;
/// Create a copy of TransactionSourceSplit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionSourceSplitCopyWith<TransactionSourceSplit> get copyWith => _$TransactionSourceSplitCopyWithImpl<TransactionSourceSplit>(this as TransactionSourceSplit, _$identity);

  /// Serializes this TransactionSourceSplit to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionSourceSplit&&(identical(other.sourceId, sourceId) || other.sourceId == sourceId)&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sourceId,amount);

@override
String toString() {
  return 'TransactionSourceSplit(sourceId: $sourceId, amount: $amount)';
}


}

/// @nodoc
abstract mixin class $TransactionSourceSplitCopyWith<$Res>  {
  factory $TransactionSourceSplitCopyWith(TransactionSourceSplit value, $Res Function(TransactionSourceSplit) _then) = _$TransactionSourceSplitCopyWithImpl;
@useResult
$Res call({
@HiveField(0) String sourceId,@HiveField(1) double amount
});




}
/// @nodoc
class _$TransactionSourceSplitCopyWithImpl<$Res>
    implements $TransactionSourceSplitCopyWith<$Res> {
  _$TransactionSourceSplitCopyWithImpl(this._self, this._then);

  final TransactionSourceSplit _self;
  final $Res Function(TransactionSourceSplit) _then;

/// Create a copy of TransactionSourceSplit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sourceId = null,Object? amount = null,}) {
  return _then(_self.copyWith(
sourceId: null == sourceId ? _self.sourceId : sourceId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [TransactionSourceSplit].
extension TransactionSourceSplitPatterns on TransactionSourceSplit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransactionSourceSplit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransactionSourceSplit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransactionSourceSplit value)  $default,){
final _that = this;
switch (_that) {
case _TransactionSourceSplit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransactionSourceSplit value)?  $default,){
final _that = this;
switch (_that) {
case _TransactionSourceSplit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@HiveField(0)  String sourceId, @HiveField(1)  double amount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransactionSourceSplit() when $default != null:
return $default(_that.sourceId,_that.amount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@HiveField(0)  String sourceId, @HiveField(1)  double amount)  $default,) {final _that = this;
switch (_that) {
case _TransactionSourceSplit():
return $default(_that.sourceId,_that.amount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@HiveField(0)  String sourceId, @HiveField(1)  double amount)?  $default,) {final _that = this;
switch (_that) {
case _TransactionSourceSplit() when $default != null:
return $default(_that.sourceId,_that.amount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TransactionSourceSplit implements TransactionSourceSplit {
  const _TransactionSourceSplit({@HiveField(0) required this.sourceId, @HiveField(1) required this.amount});
  factory _TransactionSourceSplit.fromJson(Map<String, dynamic> json) => _$TransactionSourceSplitFromJson(json);

@override@HiveField(0) final  String sourceId;
@override@HiveField(1) final  double amount;

/// Create a copy of TransactionSourceSplit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionSourceSplitCopyWith<_TransactionSourceSplit> get copyWith => __$TransactionSourceSplitCopyWithImpl<_TransactionSourceSplit>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TransactionSourceSplitToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransactionSourceSplit&&(identical(other.sourceId, sourceId) || other.sourceId == sourceId)&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sourceId,amount);

@override
String toString() {
  return 'TransactionSourceSplit(sourceId: $sourceId, amount: $amount)';
}


}

/// @nodoc
abstract mixin class _$TransactionSourceSplitCopyWith<$Res> implements $TransactionSourceSplitCopyWith<$Res> {
  factory _$TransactionSourceSplitCopyWith(_TransactionSourceSplit value, $Res Function(_TransactionSourceSplit) _then) = __$TransactionSourceSplitCopyWithImpl;
@override @useResult
$Res call({
@HiveField(0) String sourceId,@HiveField(1) double amount
});




}
/// @nodoc
class __$TransactionSourceSplitCopyWithImpl<$Res>
    implements _$TransactionSourceSplitCopyWith<$Res> {
  __$TransactionSourceSplitCopyWithImpl(this._self, this._then);

  final _TransactionSourceSplit _self;
  final $Res Function(_TransactionSourceSplit) _then;

/// Create a copy of TransactionSourceSplit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sourceId = null,Object? amount = null,}) {
  return _then(_TransactionSourceSplit(
sourceId: null == sourceId ? _self.sourceId : sourceId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on

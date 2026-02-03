// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'source.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SourceAdapter extends TypeAdapter<Source> {
  @override
  final typeId = 3;

  @override
  Source read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Source(
      id: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as SourceType,
      icon: fields[3] as String,
      color: fields[4] as String,
      initialBalance: fields[5] == null ? 0.0 : (fields[5] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, Source obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.icon)
      ..writeByte(4)
      ..write(obj.color)
      ..writeByte(5)
      ..write(obj.initialBalance);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SourceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TransactionSourceSplitAdapter
    extends TypeAdapter<TransactionSourceSplit> {
  @override
  final typeId = 5;

  @override
  TransactionSourceSplit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransactionSourceSplit(
      sourceId: fields[0] as String,
      amount: (fields[1] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, TransactionSourceSplit obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.sourceId)
      ..writeByte(1)
      ..write(obj.amount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionSourceSplitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SourceTypeAdapter extends TypeAdapter<SourceType> {
  @override
  final typeId = 4;

  @override
  SourceType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SourceType.bank;
      case 1:
        return SourceType.wallet;
      case 2:
        return SourceType.cash;
      default:
        return SourceType.bank;
    }
  }

  @override
  void write(BinaryWriter writer, SourceType obj) {
    switch (obj) {
      case SourceType.bank:
        writer.writeByte(0);
      case SourceType.wallet:
        writer.writeByte(1);
      case SourceType.cash:
        writer.writeByte(2);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SourceTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Source _$SourceFromJson(Map<String, dynamic> json) => _Source(
  id: json['id'] as String,
  name: json['name'] as String,
  type: $enumDecode(_$SourceTypeEnumMap, json['type']),
  icon: json['icon'] as String,
  color: json['color'] as String,
  initialBalance: (json['initialBalance'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$SourceToJson(_Source instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'type': _$SourceTypeEnumMap[instance.type]!,
  'icon': instance.icon,
  'color': instance.color,
  'initialBalance': instance.initialBalance,
};

const _$SourceTypeEnumMap = {
  SourceType.bank: 'bank',
  SourceType.wallet: 'wallet',
  SourceType.cash: 'cash',
};

_TransactionSourceSplit _$TransactionSourceSplitFromJson(
  Map<String, dynamic> json,
) => _TransactionSourceSplit(
  sourceId: json['sourceId'] as String,
  amount: (json['amount'] as num).toDouble(),
);

Map<String, dynamic> _$TransactionSourceSplitToJson(
  _TransactionSourceSplit instance,
) => <String, dynamic>{
  'sourceId': instance.sourceId,
  'amount': instance.amount,
};

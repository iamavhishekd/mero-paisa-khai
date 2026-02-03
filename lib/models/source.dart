import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

part 'source.freezed.dart';
part 'source.g.dart';

@freezed
@HiveType(typeId: 3)
abstract class Source with _$Source {
  const factory Source({
    @HiveField(0) required String id,
    @HiveField(1) required String name,
    @HiveField(2) required SourceType type,
    @HiveField(3) required String icon,
    @HiveField(4) required String color,
    @HiveField(5) @Default(0.0) double initialBalance,
  }) = _Source;

  factory Source.fromJson(Map<String, dynamic> json) => _$SourceFromJson(json);
}

@HiveType(typeId: 4)
enum SourceType {
  @HiveField(0)
  bank,
  @HiveField(1)
  wallet,
  @HiveField(2)
  cash,
}

@freezed
@HiveType(typeId: 5)
abstract class TransactionSourceSplit with _$TransactionSourceSplit {
  const factory TransactionSourceSplit({
    @HiveField(0) required String sourceId,
    @HiveField(1) required double amount,
  }) = _TransactionSourceSplit;

  factory TransactionSourceSplit.fromJson(Map<String, dynamic> json) =>
      _$TransactionSourceSplitFromJson(json);
}

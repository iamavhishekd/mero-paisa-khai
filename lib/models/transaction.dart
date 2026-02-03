import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

@freezed
@HiveType(typeId: 0)
abstract class Transaction with _$Transaction {
  const factory Transaction({
    @HiveField(0) required String id,
    @HiveField(1) required String title,
    @HiveField(2) required double amount,
    @HiveField(3) required DateTime date,
    @HiveField(4) required TransactionType type,
    @HiveField(5) required String category,
    @HiveField(6) String? description,
    @HiveField(7) String? relatedPerson,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
}

@HiveType(typeId: 1)
enum TransactionType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
}

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:paisa_khai/models/transaction.dart';

part 'category.freezed.dart';
part 'category.g.dart';

@freezed
@HiveType(typeId: 2)
abstract class Category with _$Category {
  const factory Category({
    @HiveField(0) required String id,
    @HiveField(1) required String name,
    @HiveField(2) required TransactionType type,
    @HiveField(3) required String icon,
    @HiveField(4) required String color,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
}

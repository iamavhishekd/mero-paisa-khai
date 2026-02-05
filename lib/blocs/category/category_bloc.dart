import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:paisa_khai/hive/hive_service.dart';
import 'package:paisa_khai/models/category.dart';

part 'category_event.dart';
part 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  StreamSubscription<BoxEvent>? _categoriesSubscription;

  CategoryBloc() : super(const CategoryState()) {
    on<LoadCategories>(_onLoadCategories);
    on<AddCategory>(_onAddCategory);
    on<UpdateCategory>(_onUpdateCategory);
    on<DeleteCategory>(_onDeleteCategory);

    _categoriesSubscription = HiveService.categoriesBoxInstance.watch().listen((
      _,
    ) {
      add(LoadCategories());
    });

    add(LoadCategories());
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<CategoryState> emit,
  ) async {
    emit(state.copyWith(status: CategoryStatus.loading));
    try {
      final categories = HiveService.categoriesBoxInstance.values.toList();
      emit(
        state.copyWith(
          categories: categories,
          status: CategoryStatus.success,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: CategoryStatus.failure));
    }
  }

  Future<void> _onAddCategory(
    AddCategory event,
    Emitter<CategoryState> emit,
  ) async {
    await HiveService.categoriesBoxInstance.put(
      event.category.id,
      event.category,
    );
  }

  Future<void> _onUpdateCategory(
    UpdateCategory event,
    Emitter<CategoryState> emit,
  ) async {
    await HiveService.categoriesBoxInstance.put(
      event.category.id,
      event.category,
    );
  }

  Future<void> _onDeleteCategory(
    DeleteCategory event,
    Emitter<CategoryState> emit,
  ) async {
    await HiveService.categoriesBoxInstance.delete(event.categoryId);
  }

  @override
  Future<void> close() async {
    await _categoriesSubscription?.cancel();
    return super.close();
  }
}

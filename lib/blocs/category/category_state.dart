part of 'category_bloc.dart';

enum CategoryStatus { initial, loading, success, failure }

class CategoryState extends Equatable {
  final List<Category> categories;
  final CategoryStatus status;

  const CategoryState({
    this.categories = const [],
    this.status = CategoryStatus.initial,
  });

  CategoryState copyWith({
    List<Category>? categories,
    CategoryStatus? status,
  }) {
    return CategoryState(
      categories: categories ?? this.categories,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [categories, status];
}

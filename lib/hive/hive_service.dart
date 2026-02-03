import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:paisa_khai/models/category.dart';
import 'package:paisa_khai/models/transaction.dart';

class HiveService {
  static const String transactionsBox = 'transactions';
  static const String categoriesBox = 'categories';
  static const String settingsBox = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(TransactionAdapter());
    Hive.registerAdapter(TransactionTypeAdapter());
    Hive.registerAdapter(CategoryAdapter());

    // Open boxes
    await Hive.openBox<Transaction>(transactionsBox);
    await Hive.openBox<Category>(categoriesBox);
    await Hive.openBox<dynamic>(settingsBox);

    // Initialize default categories if empty
    await _initializeDefaultCategories();
  }

  static Future<void> _initializeDefaultCategories() async {
    final box = Hive.box<Category>(categoriesBox);

    if (box.isEmpty) {
      final defaultCategories = [
        // Income categories
        const Category(
          id: '1',
          name: 'Salary',
          type: TransactionType.income,
          icon: '💰',
          color: '0xFF000000',
        ),
        const Category(
          id: '2',
          name: 'Freelance',
          type: TransactionType.income,
          icon: '💼',
          color: '0xFF000000',
        ),
        // Expense categories
        const Category(
          id: '3',
          name: 'Food',
          type: TransactionType.expense,
          icon: '🍔',
          color: '0xFF000000',
        ),
        const Category(
          id: '4',
          name: 'Transport',
          type: TransactionType.expense,
          icon: '🚗',
          color: '0xFF000000',
        ),
        const Category(
          id: '5',
          name: 'Shopping',
          type: TransactionType.expense,
          icon: '🛍️',
          color: '0xFF000000',
        ),
        // Lending/Borrowing categories
        const Category(
          id: '6',
          name: 'Lending',
          type: TransactionType.expense,
          icon: '👥',
          color: '0xFF000000',
        ),
        const Category(
          id: '7',
          name: 'Borrowing',
          type: TransactionType.income,
          icon: '👨‍👩‍👧‍👦',
          color: '0xFF000000',
        ),
      ];

      for (final Category category in defaultCategories) {
        await box.put(category.id, category);
      }
    }
  }

  static Box<Transaction> get transactionsBoxInstance =>
      Hive.box<Transaction>(transactionsBox);

  static Box<Category> get categoriesBoxInstance =>
      Hive.box<Category>(categoriesBox);

  static Box<dynamic> get settingsBoxInstance => Hive.box(settingsBox);
}

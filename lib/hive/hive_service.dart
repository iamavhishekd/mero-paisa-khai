import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:paisa_khai/models/category.dart';
import 'package:paisa_khai/models/source.dart';
import 'package:paisa_khai/models/transaction.dart';

class HiveService {
  static const String transactionsBox = 'transactions';
  static const String categoriesBox = 'categories';
  static const String sourcesBox = 'sources';
  static const String settingsBox = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(TransactionAdapter());
    Hive.registerAdapter(TransactionTypeAdapter());
    Hive.registerAdapter(CategoryAdapter());
    Hive.registerAdapter(SourceAdapter());
    Hive.registerAdapter(SourceTypeAdapter());
    Hive.registerAdapter(TransactionSourceSplitAdapter());

    // Open boxes
    await Hive.openBox<Transaction>(transactionsBox);
    await Hive.openBox<Category>(categoriesBox);
    await Hive.openBox<Source>(sourcesBox);
    await Hive.openBox<dynamic>(settingsBox);

    // Initialize defaults if empty and not previously initialized
    final settings = Hive.box<dynamic>(settingsBox);
    final initialSetupDone =
        settings.get('initial_setup_done', defaultValue: false) as bool;

    if (!initialSetupDone) {
      await _initializeDefaultCategories();
      await _initializeDefaultSources();
      await settings.put('initial_setup_done', true);
    }
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

  static Future<void> _initializeDefaultSources() async {
    final box = Hive.box<Source>(sourcesBox);

    if (box.isEmpty) {
      final defaultSources = [
        const Source(
          id: 's1',
          name: 'Main Bank',
          type: SourceType.bank,
          icon: '🏦',
          color: '0xFF000000',
        ),
        const Source(
          id: 's2',
          name: 'Digital Wallet',
          type: SourceType.wallet,
          icon: '📱',
          color: '0xFF000000',
        ),
        const Source(
          id: 's3',
          name: 'Physical Cash',
          type: SourceType.cash,
          icon: '💵',
          color: '0xFF000000',
        ),
      ];

      for (final Source source in defaultSources) {
        await box.put(source.id, source);
      }
    }
  }

  static Box<Transaction> get transactionsBoxInstance =>
      Hive.box<Transaction>(transactionsBox);

  static Box<Category> get categoriesBoxInstance =>
      Hive.box<Category>(categoriesBox);

  static Box<Source> get sourcesBoxInstance => Hive.box<Source>(sourcesBox);

  static Box<dynamic> get settingsBoxInstance => Hive.box(settingsBox);

  static double calculateBalanceAfter(String transactionId) {
    final allTx = transactionsBoxInstance.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    double currentBalance = sourcesBoxInstance.values.fold(
      0.0,
      (sum, s) => sum + s.initialBalance,
    );

    for (final tx in allTx) {
      if (tx.type == TransactionType.income) {
        currentBalance += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        currentBalance -= tx.amount;
      }
      if (tx.id == transactionId) return currentBalance;
    }
    return currentBalance;
  }

  static Future<void> clearAndReset() async {
    await transactionsBoxInstance.clear();
    await categoriesBoxInstance.clear();
    await sourcesBoxInstance.clear();

    // Reset initial setup flag
    await settingsBoxInstance.put('initial_setup_done', false);

    // Re-initialize defaults
    await _initializeDefaultCategories();
    await _initializeDefaultSources();
    await settingsBoxInstance.put('initial_setup_done', true);
  }
}

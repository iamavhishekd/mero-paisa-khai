import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:paisa_khai/hive/hive_service.dart';
import 'package:paisa_khai/models/transaction.dart';
import 'package:paisa_khai/screens/add_transaction_screen.dart';
import 'package:paisa_khai/screens/categories_screen.dart';
import 'package:paisa_khai/screens/import_export_screen.dart';
import 'package:paisa_khai/screens/transaction_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late List<Transaction> _transactions;

  @override
  void initState() {
    super.initState();
    _transactions = HiveService.transactionsBoxInstance.values.toList();
  }

  double get _totalIncome => _transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _totalExpense => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _balance => _totalIncome - _totalExpense;

  Map<String, double> _getCategoryExpenses() {
    final Map<String, double> categoryMap = {};
    for (final transaction in _transactions) {
      if (transaction.type == TransactionType.expense) {
        categoryMap.update(
          transaction.category,
          (value) => value + transaction.amount,
          ifAbsent: () => transaction.amount,
        );
      }
    }
    return categoryMap;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PAISA KHAI'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const ImportExportScreen(),
              ),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: ValueListenableBuilder<Box<Transaction>>(
        valueListenable: HiveService.transactionsBoxInstance.listenable(),
        builder: (context, box, _) {
          _transactions = box.values.toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 30),
                _buildBalanceCard(),
                const SizedBox(height: 30),
                _buildSectionHeader('Overview', null),
                const SizedBox(height: 12),
                _buildStatsGrid(),
                const SizedBox(height: 30),
                _buildSectionHeader('Analytics', 'Spending by category'),
                const SizedBox(height: 12),
                _buildExpenseChart(),
                const SizedBox(height: 30),
                _buildSectionHeader('Recent Activity', 'Latest 5 transactions'),
                const SizedBox(height: 12),
                _buildRecentTransactions(),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (context) => const AddTransactionScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('EEEE, d MMM').format(DateTime.now()),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Summary',
          style: Theme.of(context).textTheme.displayLarge,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String? subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBalanceCard() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // In dark mode, let's make the balance card a dark gradient instead of solid white
    // for a more "premium" look that doesn't "look off".
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(32),
        border: isDark
            ? Border.all(color: Colors.white.withOpacity(0.1))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL BALANCE',
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.white).withOpacity(0.5),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _balance < 0
                ? '-\$${_balance.abs().toStringAsFixed(2)}'
                : '\$${_balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _buildSimpleStat('Income', _totalIncome, Colors.white, true),
              const SizedBox(width: 40),
              _buildSimpleStat('Expense', _totalExpense, Colors.white, false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStat(
    String label,
    double amount,
    Color color,
    bool isIncome,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              size: 14,
              color: color.withOpacity(0.45),
            ),
            const SizedBox(width: 4),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: color.withOpacity(0.45),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Events',
            _transactions.length.toDouble(),
            Icons.receipt_long_outlined,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Active Tags',
            HiveService.categoriesBoxInstance.length.toDouble(),
            Icons.tag_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, double value, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 24,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            value.toInt().toString(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseChart() {
    final categoryExpenses = _getCategoryExpenses();
    if (categoryExpenses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.02),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          ),
        ),
        child: const Center(child: Text('No expense data available')),
      );
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final List<PieChartSectionData> sections = [];
    int index = 0;
    final colors = isDarkMode
        ? [
            Colors.white,
            Colors.white.withOpacity(0.8),
            Colors.white.withOpacity(0.6),
            Colors.white.withOpacity(0.4),
            Colors.white.withOpacity(0.2),
          ]
        : [
            Colors.black,
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.6),
            Colors.black.withOpacity(0.4),
            Colors.black.withOpacity(0.2),
          ];

    categoryExpenses.forEach((category, amount) {
      sections.add(
        PieChartSectionData(
          color: colors[index % colors.length],
          value: amount,
          title: '',
          radius: 30,
        ),
      );
      index++;
    });

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
        ),
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1.8,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 50,
                sectionsSpace: 4,
                startDegreeOffset: 180,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ...categoryExpenses.entries.map((entry) {
            final idx = categoryExpenses.keys.toList().indexOf(entry.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors[idx % colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    '\$${entry.value.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    final recentTransactions = _transactions.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final transactionsToShow = recentTransactions.take(5).toList();

    if (transactionsToShow.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.02),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.history_outlined,
              size: 40,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            ),
            const SizedBox(height: 12),
            Text(
              'No records yet',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        ...transactionsToShow.map(
          (transaction) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.08),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    transaction.type == TransactionType.income
                        ? Icons.add_circle_outline
                        : Icons.remove_circle_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        transaction.category,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${transaction.type == TransactionType.income ? "+" : "-"}\$${transaction.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d').format(transaction.date),
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const TransactionHistoryScreen(),
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'VIEW ANALYTICS HISTORY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        border: Border(
          top: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.05)),
        ),
      ),
      child: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        selectedItemColor: isDark ? Colors.white : Colors.black,
        unselectedItemColor: isDark ? Colors.white24 : Colors.black26,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 0) return;
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const CategoriesScreen(),
              ),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const TransactionHistoryScreen(),
              ),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const ImportExportScreen(),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_outlined),
            activeIcon: Icon(Icons.category),
            label: 'Tags',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

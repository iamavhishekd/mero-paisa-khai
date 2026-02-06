import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paisa_khai/blocs/category/category_bloc.dart';
import 'package:paisa_khai/blocs/source/source_bloc.dart';
import 'package:paisa_khai/blocs/transaction/transaction_bloc.dart';
import 'package:paisa_khai/hive/hive_service.dart';
import 'package:paisa_khai/models/category.dart';
import 'package:paisa_khai/models/source.dart';
import 'package:paisa_khai/models/transaction.dart';
import 'package:paisa_khai/widgets/budget_progress_card.dart';
import 'package:universal_platform/universal_platform.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  List<Transaction> _transactions = [];
  List<Source> _sources = [];
  List<Category> _categories = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    unawaited(_animationController.forward());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Calculate monthly income/expense for the current month
  double get _monthlyIncome {
    final now = DateTime.now();
    return _transactions
        .where(
          (t) =>
              t.type == TransactionType.income &&
              t.date.month == now.month &&
              t.date.year == now.year,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get _monthlyExpense {
    final now = DateTime.now();
    return _transactions
        .where(
          (t) =>
              t.type == TransactionType.expense &&
              t.date.month == now.month &&
              t.date.year == now.year,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get _totalIncome => _transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _totalExpense => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _balance {
    final initialBalances = _sources.fold(
      0.0,
      (sum, s) => sum + s.initialBalance,
    );
    return initialBalances + _totalIncome - _totalExpense;
  }

  // Get last 7 days spending data
  List<Map<String, dynamic>> get _last7DaysData {
    final now = DateTime.now();
    final List<Map<String, dynamic>> data = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final dayExpense = _transactions
          .where(
            (t) =>
                t.type == TransactionType.expense &&
                t.date.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
                t.date.isBefore(dayEnd),
          )
          .fold(0.0, (sum, t) => sum + t.amount);

      final dayIncome = _transactions
          .where(
            (t) =>
                t.type == TransactionType.income &&
                t.date.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
                t.date.isBefore(dayEnd),
          )
          .fold(0.0, (sum, t) => sum + t.amount);

      data.add({
        'date': date,
        'expense': dayExpense,
        'income': dayIncome,
        'label': DateFormat('E').format(date),
      });
    }

    return data;
  }

  // Get top spending categories
  List<Map<String, dynamic>> get _topCategories {
    final Map<String, double> categoryMap = {};
    for (final tx in _transactions) {
      if (tx.type == TransactionType.expense) {
        categoryMap.update(
          tx.category,
          (value) => value + tx.amount,
          ifAbsent: () => tx.amount,
        );
      }
    }

    final sorted = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
      const Color(0xFF8B5CF6),
    ];

    return sorted.take(5).toList().asMap().entries.map((e) {
      return {
        'category': e.value.key,
        'amount': e.value.value,
        'color': colors[e.key % colors.length],
        'percentage': _totalExpense > 0
            ? (e.value.value / _totalExpense * 100)
            : 0.0,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, txState) {
        return BlocBuilder<SourceBloc, SourceState>(
          builder: (context, sourceState) {
            return BlocBuilder<CategoryBloc, CategoryState>(
              builder: (context, categoryState) {
                _transactions = txState.transactions;
                _sources = sourceState.sources;
                _categories = categoryState.categories;

                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 1000;
                      final isMedium = constraints.maxWidth > 700;
                      final isNarrow = constraints.maxWidth < 600;

                      return SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMedium
                              ? 32.0
                              : (isNarrow ? 16.0 : 20.0),
                          vertical: isNarrow ? 20 : 32,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            SizedBox(height: isNarrow ? 16 : 28),
                            if (isWide)
                              _buildWideLayout()
                            else if (isMedium)
                              _buildMediumLayout()
                            else
                              _buildNarrowLayout(),
                            const SizedBox(height: 80),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildWideLayout() {
    final theme = Theme.of(context);
    return Column(
      children: [
        // Top row: Balance card + Quick Stats
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _buildBalanceCard()),
            const SizedBox(width: 20),
            Expanded(flex: 2, child: _buildQuickStatsCard()),
          ],
        ),
        const SizedBox(height: 12),
        // Middle row: Charts + Recent Activity
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  _buildSpendingTrendCard(),
                  const SizedBox(height: 12),
                  BudgetProgressCard(
                    transactions: _transactions,
                    categories: _categories,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.08,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildCategoryBreakdownCard(isUnified: true),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            width: 1,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.08,
                            ),
                          ),
                          Expanded(child: _buildAccountsCard(isUnified: true)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(flex: 2, child: _buildRecentActivityCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildMediumLayout() {
    final theme = Theme.of(context);
    return Column(
      children: [
        _buildBalanceCard(),
        const SizedBox(height: 20),
        _buildQuickStatsCard(),
        const SizedBox(height: 12),
        _buildSpendingTrendCard(),
        const SizedBox(height: 12),
        BudgetProgressCard(
          transactions: _transactions,
          categories: _categories,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildCategoryBreakdownCard(isUnified: true),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  width: 1,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                ),
                Expanded(child: _buildAccountsCard(isUnified: true)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildRecentActivityCard(),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      children: [
        _buildBalanceCard(),
        const SizedBox(height: 20),
        _buildQuickStatsCard(),
        const SizedBox(height: 12),
        _buildSpendingTrendCard(),
        const SizedBox(height: 12),
        BudgetProgressCard(
          transactions: _transactions,
          categories: _categories,
        ),
        const SizedBox(height: 12),
        _buildCategoryBreakdownCard(),
        const SizedBox(height: 12),
        _buildAccountsCard(),
        const SizedBox(height: 12),
        _buildRecentActivityCard(),
      ],
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final hour = DateTime.now().hour;
    String greeting = 'Good Morning';
    if (hour >= 12 && hour < 17) greeting = 'Good Afternoon';
    if (hour >= 17) greeting = 'Good Evening';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      greeting.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Dashboard',
                    style: theme.textTheme.displayLarge?.copyWith(
                      letterSpacing: -1,
                      fontSize: isNarrow ? 28 : 36,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildReportButton(theme, isNarrow),
            const SizedBox(width: 12),
            _buildAddButton(),
          ],
        );
      },
    );
  }

  Widget _buildReportButton(ThemeData theme, bool isNarrow) {
    return IconButton(
      onPressed: () => context.push('/daily-report'),
      style: IconButton.styleFrom(
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
        minimumSize: const Size(52, 52),
        fixedSize: const Size(52, 52),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      icon: Icon(
        Icons.insights_rounded,
        color: theme.colorScheme.primary,
        size: 22,
      ),
      tooltip: 'Today\'s Report',
    );
  }

  Widget _buildAddButton() {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isVeryNarrow = screenWidth < 450;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: theme.brightness == Brightness.dark
                    ? Colors.black.withValues(alpha: 0.3)
                    : theme.colorScheme.primary.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              if (UniversalPlatform.isWeb) {
                context.go('/add');
              } else {
                unawaited(context.push('/add'));
              }
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isVeryNarrow ? 16 : 24,
              ),
              minimumSize: const Size(0, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, size: 20),
                if (!isVeryNarrow) ...[
                  const SizedBox(width: 8),
                  const Text(
                    'ADD RECORD',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalanceCard() {
    final theme = Theme.of(context);
    final isPositive = _balance >= 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 450;
        final showExtra = constraints.maxWidth > 400;

        return Container(
          padding: EdgeInsets.all(isNarrow ? 20 : 28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: theme.brightness == Brightness.dark
                    ? Colors.black.withValues(alpha: 0.3)
                    : theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.account_balance_wallet_rounded,
                                color: theme.colorScheme.onPrimary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'TOTAL BALANCE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: theme.colorScheme.onPrimary.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (!showExtra)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: isPositive
                                  ? const Color(
                                      0xFF10B981,
                                    ).withValues(alpha: 0.2)
                                  : Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPositive
                                      ? Icons.trending_up_rounded
                                      : Icons.trending_down_rounded,
                                  size: 14,
                                  color: isPositive
                                      ? const Color(0xFF10B981)
                                      : Colors.redAccent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isPositive ? 'Healthy' : 'Low',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: isPositive
                                        ? const Color(0xFF10B981)
                                        : Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '\$${_balance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: isNarrow ? 32 : 44,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Across ${HiveService.sourcesBoxInstance.values.length} accounts',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onPrimary.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (showExtra) ...[
                Container(
                  width: 1,
                  height: 100,
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.1),
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'THIS MONTH',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: theme.colorScheme.onPrimary.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Income',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onPrimary.withValues(
                                    alpha: 0.7,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '+\$${_monthlyIncome.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Expense',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onPrimary.withValues(
                                    alpha: 0.7,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '-\$${_monthlyExpense.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Progress bar for net
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _monthlyIncome > 0
                              ? (_monthlyIncome - _monthlyExpense) /
                                    _monthlyIncome
                              : 0,
                          backgroundColor: theme.colorScheme.onPrimary
                              .withValues(
                                alpha: 0.1,
                              ),
                          valueColor: const AlwaysStoppedAnimation(
                            Color(0xFF10B981),
                          ),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Net Savings: \$${(_monthlyIncome - _monthlyExpense).toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: const Color(
                            0xFF10B981,
                          ).withValues(alpha: 0.9),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickStatsCard() {
    final theme = Theme.of(context);
    final isNarrow = MediaQuery.of(context).size.width < 600;
    final now = DateTime.now();
    final monthName = DateFormat('MMMM').format(now);

    return Container(
      padding: EdgeInsets.all(isNarrow ? 18 : 24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$monthName SUMMARY',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 20),
          _buildStatRow(
            'Income',
            '+\$${_monthlyIncome.toStringAsFixed(0)}',
            Icons.south_west_rounded,
            const Color(0xFF10B981),
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            'Expenses',
            '-\$${_monthlyExpense.toStringAsFixed(0)}',
            Icons.north_east_rounded,
            Colors.redAccent,
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            'Net',
            '\$${(_monthlyIncome - _monthlyExpense).toStringAsFixed(0)}',
            Icons.swap_vert_rounded,
            _monthlyIncome >= _monthlyExpense
                ? const Color(0xFF10B981)
                : Colors.redAccent,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  '${_transactions.length}',
                  'Total Records',
                  Icons.receipt_long_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStat(
                  '${_topCategories.length}',
                  'Categories',
                  Icons.category_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String value, String label, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 18,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingTrendCard() {
    final theme = Theme.of(context);
    final data = _last7DaysData;

    // Calculate max value for scaling
    final maxY = data.fold(0.0, (max, d) {
      final expense = d['expense'] as double;
      return expense > max ? expense : max;
    });

    final expenseSpots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value['expense'] as double);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SPENDING TREND',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Last 7 Days',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.trending_down_rounded,
                      size: 14,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Expense',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.redAccent.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: data.every((d) => d['expense'] == 0)
                ? Center(
                    child: Text(
                      'No expense data available',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        horizontalInterval: maxY > 0 ? maxY / 3 : 100,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.05,
                            ),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(),
                        topTitles: const AxisTitles(),
                        leftTitles: const AxisTitles(),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 &&
                                  value.toInt() < data.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    data[value.toInt()]['label'] as String,
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: 6,
                      minY: 0,
                      maxY: maxY * 1.2,
                      lineBarsData: [
                        LineChartBarData(
                          spots: expenseSpots,
                          isCurved: true,
                          color: Colors.redAccent,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 3,
                                color:
                                    theme.cardTheme.color ??
                                    theme.colorScheme.surface,
                                strokeWidth: 2,
                                strokeColor: Colors.redAccent,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                Colors.redAccent.withValues(alpha: 0.15),
                                Colors.redAccent.withValues(alpha: 0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdownCard({bool isUnified = false}) {
    final theme = Theme.of(context);
    final categories = _topCategories;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TOP SPENDING',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 20),
        if (categories.isEmpty)
          SizedBox(
            height: 150,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pie_chart_outline_rounded,
                    size: 36,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No expenses yet',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...categories.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildCategoryRow(cat),
            ),
          ),
      ],
    );

    if (isUnified) return content;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: content,
    );
  }

  Widget _buildCategoryRow(Map<String, dynamic> cat) {
    final theme = Theme.of(context);
    final color = cat['color'] as Color;
    final percentage = cat['percentage'] as double;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                cat['category'] as String,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '\$${(cat['amount'] as double).toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: theme.colorScheme.onSurface.withValues(
              alpha: 0.06,
            ),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountsCard({bool isUnified = false}) {
    final theme = Theme.of(context);
    final sources = HiveService.sourcesBoxInstance.values.toList();

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ACCOUNTS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            Text(
              '${sources.length} total',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (sources.isEmpty)
          SizedBox(
            height: 150,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_outlined,
                    size: 36,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No accounts added',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...sources.take(4).map((source) {
            final balance = _calculateSourceBalance(source);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildAccountRow(source, balance),
            );
          }),
      ],
    );

    if (isUnified) return content;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: content,
    );
  }

  double _calculateSourceBalance(Source source) {
    double balance = source.initialBalance;
    for (final tx in _transactions) {
      if (tx.sources == null || tx.sources!.isEmpty) continue;
      for (final split in tx.sources!) {
        if (split.sourceId == source.id) {
          if (tx.type == TransactionType.income) {
            balance += split.amount;
          } else if (tx.type == TransactionType.expense) {
            balance -= split.amount;
          }
        }
      }
    }
    return balance;
  }

  Widget _buildAccountRow(Source source, double balance) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(source.icon, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  source.type.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${balance.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: balance >= 0
                  ? theme.colorScheme.onSurface
                  : Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    final theme = Theme.of(context);
    final recentTransactions = List<Transaction>.from(_transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    final recent = recentTransactions.take(6).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RECENT ACTIVITY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/history'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recent.isEmpty)
            SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No transactions yet',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Add your first record to get started',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...recent.map((tx) => _buildRecentTransactionRow(tx)),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionRow(Transaction tx) {
    final theme = Theme.of(context);
    final isIncome = tx.type == TransactionType.income;
    final timeString = DateFormat('MMM d, h:mm a').format(tx.date);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (UniversalPlatform.isWeb) {
            context.go('/transaction/${tx.id}');
          } else {
            unawaited(context.push('/transaction/${tx.id}'));
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isIncome
                        ? [
                            const Color(0xFF10B981).withValues(alpha: 0.15),
                            const Color(0xFF10B981).withValues(alpha: 0.05),
                          ]
                        : [
                            Colors.redAccent.withValues(alpha: 0.15),
                            Colors.redAccent.withValues(alpha: 0.05),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isIncome
                      ? Icons.south_west_rounded
                      : Icons.north_east_rounded,
                  size: 16,
                  color: isIncome ? const Color(0xFF10B981) : Colors.redAccent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      timeString,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${isIncome ? '+' : '-'}\$${tx.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: isIncome ? const Color(0xFF10B981) : Colors.redAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:paisa_khai/hive/hive_service.dart';
import 'package:paisa_khai/models/source.dart';
import 'package:paisa_khai/models/transaction.dart';
import 'package:paisa_khai/screens/add_transaction_screen.dart';
import 'package:paisa_khai/screens/transaction_detail_screen.dart';

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

  double get _balance {
    final initialBalances = HiveService.sourcesBoxInstance.values.fold(
      0.0,
      (sum, s) => sum + s.initialBalance,
    );
    return initialBalances + _totalIncome - _totalExpense;
  }

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
    return ValueListenableBuilder<Box<Transaction>>(
      valueListenable: HiveService.transactionsBoxInstance.listenable(),
      builder: (context, txBox, _) {
        _transactions = txBox.values.toList();

        return ValueListenableBuilder<Box<Source>>(
          valueListenable: HiveService.sourcesBoxInstance.listenable(),
          builder: (context, sourceBox, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: 40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildSummaryCards(),
                  const SizedBox(height: 48),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 900;

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 13,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionHeader(
                                    'Overview',
                                    'Your accounts & assets',
                                  ),
                                  const SizedBox(height: 24),
                                  _buildSourcesOverview(),
                                  const SizedBox(height: 16),
                                  _buildSectionHeader(
                                    'Analytics',
                                    'Spending insights',
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: _buildExpenseChart()),
                                      const SizedBox(width: 24),
                                      Expanded(child: _buildDailyTrendChart()),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 40),
                            Expanded(
                              flex: 7,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionHeader(
                                    'Recent Activity',
                                    'Latest entries',
                                  ),
                                  const SizedBox(height: 16),
                                  _buildRecentTransactions(),
                                ],
                              ),
                            ),
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            'Overview',
                            'Your accounts & assets',
                          ),
                          const SizedBox(height: 24),
                          _buildSourcesOverview(),
                          _buildSectionHeader(
                            'Analytics',
                            'Spending insights',
                          ),
                          const SizedBox(height: 24),
                          _buildExpenseChart(),
                          const SizedBox(height: 24),
                          _buildDailyTrendChart(),
                          const SizedBox(height: 48),
                          _buildSectionHeader(
                            'Recent Activity',
                            'Latest entries',
                          ),
                          const SizedBox(height: 16),
                          _buildRecentTransactions(),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            );
          },
        );
      },
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
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'YOUR ',
                        style: theme.textTheme.displayLarge?.copyWith(
                          letterSpacing: -1,
                          fontSize: isNarrow ? 28 : 40,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'OVERVIEW',
                        style: theme.textTheme.displayLarge?.copyWith(
                          letterSpacing: -1,
                          fontSize: isNarrow ? 28 : 40,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Row(
              children: [
                if (!isNarrow) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.05,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_none_rounded),
                      onPressed: () {},
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      iconSize: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                ElevatedButton(
                  onPressed: () async {
                    await Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => const AddTransactionScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: isNarrow ? 12 : 24,
                      vertical: isNarrow ? 16 : 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: theme.colorScheme.onSurface,
                    foregroundColor: theme.colorScheme.surface,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, size: 20),
                      if (!isNarrow) ...[
                        const SizedBox(width: 8),
                        const Text(
                          'ADD RECORD',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;
        final List<Widget> cards = [
          _buildSummaryCard(
            'Total Balance',
            _balance,
            Icons.account_balance_wallet_rounded,
            true,
          ),
          _buildSummaryCard(
            'Monthly Income',
            _totalIncome,
            Icons.south_west_rounded,
            false,
          ),
          _buildSummaryCard(
            'Monthly Expense',
            _totalExpense,
            Icons.north_east_rounded,
            false,
          ),
        ];

        if (isNarrow) {
          return Column(
            children: cards
                .map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SizedBox(width: double.infinity, child: c),
                  ),
                )
                .toList(),
          );
        }

        return Row(
          children: cards
              .map(
                (c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: c,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildSummaryCard(
    String title,
    double amount,
    IconData icon,
    bool isPrimary,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isPrimary
            ? theme.colorScheme.primary
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        ),
        boxShadow: [
          if (isPrimary)
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: isPrimary
                      ? theme.colorScheme.onPrimary.withValues(alpha: 0.5)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              Icon(
                icon,
                size: 20,
                color: isPrimary
                    ? theme.colorScheme.onPrimary.withValues(alpha: 0.5)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.2),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '\$${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}',
            style: theme.textTheme.displaySmall?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: isPrimary
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String? subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildExpenseChart() {
    final categoryExpenses = _getCategoryExpenses();
    if (categoryExpenses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.05),
          ),
        ),
        child: const Center(child: Text('No expense data available')),
      );
    }

    final List<PieChartSectionData> sections = [];
    int index = 0;
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEC4899), // Pink
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFF3B82F6), // Blue
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
      height: 400,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 240,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 60,
                    sectionsSpace: 6,
                    startDegreeOffset: 270,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TOTAL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                  Text(
                    '\$${_totalExpense.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ],
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

  Widget _buildDailyTrendChart() {
    // Last 7 days
    final now = DateTime.now();
    final List<double> dailyExpenses = List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      return _transactions
          .where(
            (t) =>
                t.type == TransactionType.expense &&
                t.date.year == date.year &&
                t.date.month == date.month &&
                t.date.day == date.day,
          )
          .fold(0.0, (sum, t) => sum + t.amount);
    });

    final maxExpense = dailyExpenses.isEmpty
        ? 0.0
        : dailyExpenses.reduce((a, b) => a > b ? a : b);
    final theme = Theme.of(context);

    return Container(
      height: 400,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(32),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DAILY SPENDING',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last 7 days',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
              if (maxExpense > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Max: \$${maxExpense.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxExpense == 0 ? 100 : maxExpense * 1.3,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => theme.colorScheme.surface,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '\$${rod.toY.toStringAsFixed(2)}',
                        TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final date = now.subtract(
                          Duration(days: 6 - value.toInt()),
                        );
                        final isToday = value.toInt() == 6;
                        return Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Text(
                            isToday
                                ? 'TODAY'
                                : DateFormat('E').format(date).toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: isToday
                                  ? FontWeight.w900
                                  : FontWeight.w700,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: isToday ? 0.8 : 0.3,
                              ),
                            ),
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                ),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: maxExpense > 0 ? maxExpense / 3 : 25,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  7,
                  (index) => BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: dailyExpenses[index],
                        color: index == 6
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primary.withValues(alpha: 0.4),
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxExpense == 0 ? 100 : maxExpense * 1.3,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.02,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.history_outlined,
              size: 40,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 12),
            Text(
              'No records yet',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        ...transactionsToShow.map(
          (transaction) => Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => TransactionDetailScreen.show(context, transaction),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            (transaction.type == TransactionType.income
                                    ? const Color(0xFF10B981)
                                    : Colors.orange)
                                .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        transaction.type == TransactionType.income
                            ? Icons.south_west_rounded
                            : Icons.north_east_rounded,
                        size: 18,
                        color: transaction.type == TransactionType.income
                            ? const Color(0xFF10B981)
                            : Colors.orange,
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
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            transaction.category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.3),
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
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            color: transaction.type == TransactionType.income
                                ? const Color(0xFF10B981)
                                : Theme.of(context).colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat(
                            'MMM d',
                          ).format(transaction.date).toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => context.go('/history'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'VIEW FULL HISTORY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSourcesOverview() {
    return ValueListenableBuilder<Box<Source>>(
      valueListenable: HiveService.sourcesBoxInstance.listenable(),
      builder: (context, box, _) {
        final sources = box.values.toList();

        // Dynamic height based on sources
        // If no sources (only balance card), height is tight 310
        // If sources exist, we need more space for the peekaboo stack effect
        final double height = sources.isEmpty ? 310.0 : 360.0;

        return SizedBox(
          height: height,
          child: _SourcesStackedDeck(
            sources: sources,
            onCalculateBalance: _calculateSourceBalance,
            totalBalance: _balance,
            totalIncome: _totalIncome,
            totalExpense: _totalExpense,
          ),
        );
      },
    );
  }

  double _calculateSourceBalance(Source source) {
    double balance = source.initialBalance;
    for (final tx in _transactions) {
      if (tx.sources == null) continue;
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
}

class _SourcesStackedDeck extends StatefulWidget {
  final List<Source> sources;
  final double Function(Source) onCalculateBalance;
  final double totalBalance;
  final double totalIncome;
  final double totalExpense;

  const _SourcesStackedDeck({
    required this.sources,
    required this.onCalculateBalance,
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
  });

  @override
  State<_SourcesStackedDeck> createState() => _SourcesStackedDeckState();
}

class _SourcesStackedDeckState extends State<_SourcesStackedDeck>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  double _currentPage = 0;
  // Start at a large index to allow swiping "back" effectively and simulate infinite list
  // We'll update this in initState based on actual count
  static const int _initialPageMultiplier = 1000;

  @override
  void initState() {
    super.initState();

    final totalCards = widget.sources.length + 1; // Balance + Sources
    // Start somewhere in the middle-ish so we have space?
    // Actually just need enough buffer.
    final initialPage = totalCards > 0
        ? totalCards * _initialPageMultiplier
        : 0;
    _currentPage = initialPage.toDouble();

    _pageController = PageController(initialPage: initialPage)
      ..addListener(() {
        setState(() {
          _currentPage = _pageController.page ?? 0;
        });
      });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // +1 for the Total Balance card at index 0
    final totalCards = widget.sources.length + 1;
    if (totalCards == 0) return const SizedBox.shrink();

    return Stack(
      children: [
        // Page view for interaction
        PageView.builder(
          scrollDirection: Axis.vertical,
          controller: _pageController,
          itemBuilder: (context, index) => Container(),
        ),
        // The actual stack
        IgnorePointer(
          child: Builder(
            builder: (context) {
              final List<_CardLayout> layoutCards = [];
              // Adjust visible count. We need at least one extra card for smooth scroll (the incoming one).
              // But we don't need 5 if we only have 2.
              final int visibleCount = (totalCards + 1).clamp(0, 5);

              final double topOffset = 40.0;
              // We render a window of cards around the current page
              for (int offset = 0; offset < visibleCount; offset++) {
                final int index = _currentPage.floor() + offset;
                final int dataIndex = index % totalCards;
                final double relativePosition = index - _currentPage;

                double translateY = 0;
                double scale = 1.0;
                double opacity = 1.0;
                int zIndex = 0;

                if (relativePosition <= 0) {
                  // Active card leaving (0 to -1)
                  // We want it to arc over and go to back.

                  // 1. Z-Index Swap
                  zIndex = relativePosition > -0.5 ? 100 : -100;

                  // 2. Scale Interpolation
                  // Target scale based on where it lands in the stack
                  final double endStackDepth = (totalCards - 1)
                      .clamp(0, 4)
                      .toDouble();
                  final double bottomStackScale = 1.0 - (endStackDepth * 0.04);
                  scale = 1.0 + (relativePosition * (1.0 - bottomStackScale));

                  // 3. Position Arc
                  // Linear path from Start to End
                  final double endY = topOffset - (endStackDepth * 20.0);
                  final double linearY =
                      topOffset + (relativePosition * (topOffset - endY).abs());

                  // Arc offset (Parabolic approximation)
                  const double arcHeight = 350.0;
                  final double x = relativePosition;
                  final double parabola = -4 * x * (x + 1);
                  final double arcY = parabola * -arcHeight;

                  translateY = linearY + arcY;

                  // Opacity - keep full opacity for seamless loop?
                  // Or partial fade at peak?
                  // Let's keep it visible.
                  opacity = 1.0;
                } else {
                  // Stacked cards
                  final indexFromActive = relativePosition;
                  translateY = topOffset - (indexFromActive * 20);
                  scale = 1.0 - (indexFromActive * 0.04);

                  // Sort Order
                  zIndex = 50 - offset;

                  // Opacity Logic
                  // 1. Depth Fade: Deeper cards get slightly transparent
                  final double depthFade = 1.0 - (indexFromActive * 0.15);

                  // 2. Count Limit Fade: Ensures we don't see "Ghost" duplicates for small lists.
                  // For N=2. Rel 0, Rel 1 visible. Rel 2 (Duplicate) invisible at steady state.
                  // Rel 2 should fade in as we scroll (Rel 1.5).
                  // So we fade out as we approach 'totalCards'.
                  final double countLimitFade =
                      (totalCards.toDouble() - indexFromActive).clamp(0.0, 1.0);

                  opacity = (depthFade * countLimitFade).clamp(0.0, 1.0);

                  // Hard limit for deep stacks to prevent rendering too many
                  if (indexFromActive > 3.5) opacity = 0;
                }

                // Create Content
                Widget cardContent;
                if (dataIndex == 0) {
                  cardContent = _TotalBalanceCard(
                    balance: widget.totalBalance,
                    income: widget.totalIncome,
                    expense: widget.totalExpense,
                  );
                } else {
                  final source = widget.sources[dataIndex - 1];
                  final balance = widget.onCalculateBalance(source);
                  cardContent = SourceCard(
                    source: source,
                    balance: balance,
                    index: dataIndex - 1,
                  );
                }

                layoutCards.add(
                  _CardLayout(
                    key: ValueKey('card_$index'),
                    zIndex: zIndex,
                    widget: Transform(
                      transform: Matrix4.identity()
                        ..setTranslationRaw(0.0, translateY, 0.0)
                        ..multiply(Matrix4.diagonal3Values(scale, scale, 1.0)),
                      alignment: Alignment.topCenter,
                      child: Opacity(
                        opacity: opacity,
                        child: cardContent,
                      ),
                    ),
                  ),
                );
              }

              // Sort by zIndex (lowest first = back)
              layoutCards.sort((a, b) => a.zIndex.compareTo(b.zIndex));

              return Stack(
                children: layoutCards
                    .map(
                      (l) => KeyedSubtree(
                        key: l.key,
                        child: l.widget,
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CardLayout {
  final Key key;
  final int zIndex;
  final Widget widget;

  _CardLayout({required this.key, required this.zIndex, required this.widget});
}

class _TotalBalanceCard extends StatelessWidget {
  final double balance;
  final double income;
  final double expense;

  const _TotalBalanceCard({
    required this.balance,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: 270,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2D3238), const Color(0xFF16181D)]
              : [const Color(0xFF1A1C1E), const Color(0xFF2C3E50)],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.2),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL BALANCE',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white.withValues(alpha: 0.2),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            balance < 0
                ? '-\$${balance.abs().toStringAsFixed(2)}'
                : '\$${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w900,
              letterSpacing: -2,
            ),
          ),
          const Spacer(),
          // Use a Row closer to the SourceCard style but keeping stat info
          Row(
            children: [
              _buildSimpleStat('Income', income, Colors.white, true),
              Container(
                height: 40,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 32),
                color: Colors.white.withValues(alpha: 0.1),
              ),
              _buildSimpleStat('Expense', expense, Colors.white, false),
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
              color: color.withValues(alpha: 0.45),
            ),
            const SizedBox(width: 4),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: color.withValues(alpha: 0.45),
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
}

class SourceCard extends StatelessWidget {
  final Source source;
  final double balance;
  final int index;

  const SourceCard({
    super.key,
    required this.source,
    required this.balance,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final gradients = [
      [const Color(0xFF0F2027), const Color(0xFF2C5364)],
      [const Color(0xFF642B73), const Color(0xFFC6426E)],
      [const Color(0xFF134E5E), const Color(0xFF71B280)],
      [const Color(0xFF000000), const Color(0xFF434343)],
      [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)],
    ];

    final gradient = gradients[index % gradients.length];

    return Container(
      width: double.infinity,
      height: 270, // Increased height to prevent overflow
      padding: const EdgeInsets.all(28), // More breathing room
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.4),
            blurRadius: 32,
            offset: const Offset(0, 16),
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
                    source.type.name.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    source.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22, // Bigger text
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  source.icon,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            'TOTAL BALANCE',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  '\$',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                NumberFormat('#,##0.00').format(balance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40, // More prominent balance
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: 50,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFDAA520)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
          ),
        ],
      ),
    );
  }
}

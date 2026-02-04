import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:paisa_khai/hive/hive_service.dart';
import 'package:paisa_khai/models/transaction.dart';
import 'package:paisa_khai/screens/add_transaction_screen.dart';
import 'package:paisa_khai/screens/transaction_detail_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  TransactionType? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildFilters(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Divider(height: 1),
          ),
          Expanded(
            child: ValueListenableBuilder<Box<Transaction>>(
              valueListenable: HiveService.transactionsBoxInstance.listenable(),
              builder: (context, box, _) {
                // Calculate running balances using all transactions sorted ascending
                final allForBalance = box.values.toList()
                  ..sort((a, b) => a.date.compareTo(b.date));

                List<Transaction> transactions = List.from(allForBalance);

                final runningBalances = <String, double>{};
                double currentBalance = HiveService.sourcesBoxInstance.values
                    .fold(
                      0.0,
                      (sum, s) => sum + s.initialBalance,
                    );

                for (final tx in allForBalance) {
                  if (tx.type == TransactionType.income) {
                    currentBalance += tx.amount;
                  } else {
                    currentBalance -= tx.amount;
                  }
                  runningBalances[tx.id] = currentBalance;
                }

                if (_selectedFilter != null) {
                  transactions = transactions
                      .where((t) => t.type == _selectedFilter)
                      .toList();
                }

                transactions.sort((a, b) => b.date.compareTo(a.date));

                if (transactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_outlined,
                          size: 64,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.1),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No records found',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.3),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 800 ? 2 : 1;

                    if (crossAxisCount > 1) {
                      return GridView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 16.0,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              mainAxisExtent: 130,
                            ),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          final balanceAfter =
                              runningBalances[transaction.id] ?? 0.0;
                          return _buildTransactionItem(
                            transaction,
                            balanceAfter,
                          );
                        },
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 16.0,
                      ),
                      itemCount: transactions.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        final balanceAfter =
                            runningBalances[transaction.id] ?? 0.0;
                        return _buildTransactionItem(transaction, balanceAfter);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COLLECTION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'HISTORY',
                      style: theme.textTheme.displayLarge?.copyWith(
                        letterSpacing: -1,
                        fontSize: isNarrow ? 28 : 40,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
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
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, size: 20),
                    if (!isNarrow) ...[
                      const SizedBox(width: 8),
                      const Text('ADD RECORD'),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilters() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip(null, 'All Activities'),
          _buildFilterChip(TransactionType.expense, 'Expenses'),
          _buildFilterChip(TransactionType.income, 'Income'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(TransactionType? type, String label) {
    final isSelected = _selectedFilter == type;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = selected ? type : null;
          });
        },
        selectedColor: isDark ? Colors.white : Colors.black,
        backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        labelStyle: TextStyle(
          color: isSelected
              ? (isDark ? Colors.black : Colors.white)
              : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction, double balanceAfter) {
    final theme = Theme.of(context);
    final isIncome = transaction.type == TransactionType.income;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => TransactionDetailScreen.show(
          context,
          transaction,
          balanceAfter: balanceAfter,
        ),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isIncome
                      ? Icons.add_circle_outline
                      : Icons.remove_circle_outline,
                  size: 20,
                  color: isIncome ? const Color(0xFF10B981) : Colors.redAccent,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      transaction.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          transaction.category,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.3,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('MMM d, yyyy').format(transaction.date),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (transaction.relatedPerson != null &&
                        transaction.relatedPerson!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            transaction.relatedPerson!,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${isIncome ? "+" : "-"}\$${transaction.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: -1,
                      color: isIncome
                          ? const Color(0xFF10B981)
                          : Colors.redAccent,
                    ),
                  ),
                  Text(
                    'Balance: \$${balanceAfter.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

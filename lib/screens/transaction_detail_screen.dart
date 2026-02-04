import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:paisa_khai/hive/hive_service.dart';
import 'package:paisa_khai/models/transaction.dart';
import 'package:universal_platform/universal_platform.dart';

class TransactionDetailScreen extends StatelessWidget {
  final Transaction transaction;
  final double? balanceAfter;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
    this.balanceAfter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder(
      valueListenable: HiveService.transactionsBoxInstance.listenable(
        keys: [transaction.id],
      ),
      builder: (context, box, child) {
        final currentTx = box.get(transaction.id);

        if (currentTx == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            }
          });
          return const Scaffold(body: SizedBox.shrink());
        }

        final isIncome = currentTx.type == TransactionType.income;
        final finalBalanceAfter =
            balanceAfter ?? HiveService.calculateBalanceAfter(currentTx.id);

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('DETAILS'),
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  if (UniversalPlatform.isWeb) {
                    context.go('/add?editId=${currentTx.id}');
                  } else {
                    context.push('/add?editId=${currentTx.id}');
                  }
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Transaction?'),
                      content: const Text('This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await HiveService.transactionsBoxInstance.delete(
                      currentTx.id,
                    );
                    if (context.mounted) {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    }
                  }
                },
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              final hPadding = isNarrow ? 16.0 : 24.0;
              final vPadding = isNarrow ? 20.0 : 24.0;
              final spacing = isNarrow ? 24.0 : 32.0;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: hPadding,
                  vertical: vPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTypeHeader(theme, isIncome, currentTx),
                    SizedBox(height: spacing),
                    _buildMainInfo(theme, currentTx),
                    SizedBox(height: spacing),
                    _buildSectionTitle('METRICS'),
                    const SizedBox(height: 16),
                    _buildMetricsCard(theme, finalBalanceAfter, currentTx),
                    SizedBox(height: spacing),
                    _buildSectionTitle('FUNDING SOURCES'),
                    const SizedBox(height: 16),
                    _buildSourcesList(theme, currentTx),
                    if (currentTx.description != null &&
                        currentTx.description!.isNotEmpty) ...[
                      SizedBox(height: spacing),
                      _buildSectionTitle('DESCRIPTION'),
                      const SizedBox(height: 16),
                      _buildDescriptionCard(theme, currentTx),
                    ],
                    if (currentTx.receiptPath != null) ...[
                      SizedBox(height: spacing),
                      _buildSectionTitle('RECEIPT SCAN'),
                      const SizedBox(height: 16),
                      _buildReceiptCard(theme, currentTx),
                    ],
                    SizedBox(height: spacing + 16),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTypeHeader(
    ThemeData theme,
    bool isIncome,
    Transaction currentTx,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: (isIncome ? const Color(0xFF10B981) : Colors.redAccent)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isIncome ? const Color(0xFF10B981) : Colors.redAccent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isIncome ? 'INCOME' : 'EXPENSE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color:
                        (isIncome ? const Color(0xFF10B981) : Colors.redAccent)
                            .withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentTx.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainInfo(ThemeData theme, Transaction currentTx) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoItem(
            'DATE',
            DateFormat('MMMM d, yyyy').format(currentTx.date).toUpperCase(),
            Icons.calendar_today_rounded,
            theme,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoItem(
            'TIME',
            DateFormat('hh:mm a').format(currentTx.date).toUpperCase(),
            Icons.access_time_rounded,
            theme,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    String label,
    String value,
    IconData icon,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildMetricsCard(
    ThemeData theme,
    double balanceAfter,
    Transaction currentTx,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          _buildMetricRow(
            'TRANSACTION AMOUNT',
            '\$${currentTx.amount.toStringAsFixed(2)}',
            currentTx.type == TransactionType.income
                ? const Color(0xFF10B981)
                : Colors.redAccent,
            theme,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          _buildMetricRow(
            'BALANCE AFTER',
            '\$${balanceAfter.toStringAsFixed(2)}',
            theme.colorScheme.onSurface,
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(
    String label,
    String value,
    Color valueColor,
    ThemeData theme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: valueColor,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSourcesList(ThemeData theme, Transaction currentTx) {
    final splits = currentTx.sources ?? [];
    if (splits.isEmpty) {
      return const Text('No sources assigned');
    }

    return Column(
      children: splits.map((split) {
        final source = HiveService.sourcesBoxInstance.get(split.sourceId);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              if (source != null) ...[
                Text(source.icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    source.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ] else ...[
                const Expanded(child: Text('UNKNOWN SOURCE')),
              ],
              Text(
                '\$${split.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDescriptionCard(ThemeData theme, Transaction currentTx) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Text(
        currentTx.description!,
        style: TextStyle(
          fontSize: 14,
          height: 1.6,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildReceiptCard(ThemeData theme, Transaction currentTx) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.file(
        File(currentTx.receiptPath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: Text('Receipt image not found')),
        ),
      ),
    );
  }
}

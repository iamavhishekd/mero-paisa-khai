import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paisa_khai/blocs/source/source_bloc.dart';
import 'package:paisa_khai/blocs/transaction/transaction_bloc.dart';
import 'package:paisa_khai/models/source.dart';
import 'package:paisa_khai/models/transaction.dart';
import 'package:universal_platform/universal_platform.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen>
    with SingleTickerProviderStateMixin {
  TransactionType? _selectedType;
  String? _selectedSourceId;
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
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
    _searchController.dispose();
    super.dispose();
  }

  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    return transactions.where((t) {
      // Type filter
      if (_selectedType != null && t.type != _selectedType) {
        return false;
      }
      // Source filter
      if (_selectedSourceId != null) {
        if (t.sources == null || t.sources!.isEmpty) return false;
        final hasSource = t.sources!.any(
          (s) => s.sourceId == _selectedSourceId,
        );
        if (!hasSource) return false;
      }
      // Date range filter
      if (_selectedDateRange != null) {
        final startDate = DateTime(
          _selectedDateRange!.start.year,
          _selectedDateRange!.start.month,
          _selectedDateRange!.start.day,
        );
        final endDate = DateTime(
          _selectedDateRange!.end.year,
          _selectedDateRange!.end.month,
          _selectedDateRange!.end.day,
          23,
          59,
          59,
        );
        if (t.date.isBefore(startDate) || t.date.isAfter(endDate)) {
          return false;
        }
      }
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = t.title.toLowerCase().contains(query);
        final matchesCategory = t.category.toLowerCase().contains(query);
        final matchesPerson =
            t.relatedPerson?.toLowerCase().contains(query) ?? false;
        if (!matchesTitle && !matchesCategory && !matchesPerson) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _showDateRangePicker() async {
    final now = DateTime.now();
    final initialRange =
        _selectedDateRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: initialRange,
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.onSurface,
              onPrimary: theme.colorScheme.surface,
              surface: theme.colorScheme.surface,
              onSurface: theme.colorScheme.onSurface,
              secondaryContainer: theme.colorScheme.onSurface.withValues(
                alpha: 0.12,
              ),
              onSecondaryContainer: theme.colorScheme.onSurface,
            ),
            datePickerTheme: DatePickerThemeData(
              headerBackgroundColor: theme.colorScheme.surface,
              headerForegroundColor: theme.colorScheme.onSurface,
              rangeSelectionBackgroundColor: theme.colorScheme.onSurface
                  .withValues(alpha: 0.12),
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return theme.colorScheme.surface;
                }
                return theme.colorScheme.onSurface;
              }),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedType != null) count++;
    if (_selectedSourceId != null) count++;
    if (_selectedDateRange != null) count++;
    if (_searchQuery.isNotEmpty) count++;
    return count;
  }

  void _clearAllFilters() {
    setState(() {
      _selectedType = null;
      _selectedSourceId = null;
      _selectedDateRange = null;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  bool _isFilterExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: BlocBuilder<TransactionBloc, TransactionState>(
          builder: (context, txState) {
            return BlocBuilder<SourceBloc, SourceState>(
              builder: (context, sourceState) {
                final allTransactions = txState.transactions;
                final filteredTransactions = _filterTransactions(
                  allTransactions,
                );

                // Calculate running balances
                final allForBalance = List<Transaction>.from(allTransactions)
                  ..sort((a, b) => a.date.compareTo(b.date));

                final runningBalances = <String, double>{};
                double currentBalance = sourceState.sources.fold(
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

                // Calculate stats for filtered transactions
                final filteredIncome = filteredTransactions
                    .where((t) => t.type == TransactionType.income)
                    .fold(0.0, (sum, t) => sum + t.amount);
                final filteredExpense = filteredTransactions
                    .where((t) => t.type == TransactionType.expense)
                    .fold(0.0, (sum, t) => sum + t.amount);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    _buildSearchBar(),
                    _buildFilterSection(sourceState.sources),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildStatsBar(
                            filteredTransactions.length,
                            filteredIncome,
                            filteredExpense,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                            ),
                            child: Divider(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.05,
                              ),
                            ),
                          ),
                          Expanded(
                            child: filteredTransactions.isEmpty
                                ? _buildEmptyState()
                                : _buildTransactionsList(
                                    filteredTransactions,
                                    runningBalances,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isNarrow = screenWidth < 600;
        final hPadding = isNarrow ? 16.0 : 24.0;

        return Padding(
          padding: EdgeInsets.fromLTRB(hPadding, 24, hPadding, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'RECORDS',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Transaction History',
                      style: theme.textTheme.displayLarge?.copyWith(
                        letterSpacing: -1,
                        fontSize: isNarrow ? 26 : 36,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildAddButton(isNarrow),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddButton(bool isNarrow) {
    final theme = Theme.of(context);
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
            horizontal: isNarrow ? 14 : 24,
            vertical: isNarrow ? 14 : 18,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, size: 20),
            if (!isNarrow) ...[
              const SizedBox(width: 10),
              const Text(
                'NEW RECORD',
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
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    final isNarrow = MediaQuery.of(context).size.width < 600;
    final hPadding = isNarrow ? 16.0 : 24.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(hPadding, 0, hPadding, 12),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(
              Icons.search_rounded,
              size: 20,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  filled: false,
                  fillColor: Colors.transparent,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: 'Search by title, category, or person...',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(List<Source> sources) {
    final theme = Theme.of(context);
    final isNarrow = MediaQuery.of(context).size.width < 600;
    final hPadding = isNarrow ? 16.0 : 24.0;
    final isWide = MediaQuery.of(context).size.width > 800;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filter toggle header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPadding),
          child: Row(
            children: [
              InkWell(
                onTap: () =>
                    setState(() => _isFilterExpanded = !_isFilterExpanded),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 18,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'FILTERS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      if (_activeFilterCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$_activeFilterCount',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: _isFilterExpanded ? 0 : -0.25,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.expand_more_rounded,
                          size: 20,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              if (_activeFilterCount > 0)
                TextButton(
                  onPressed: _clearAllFilters,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Clear all',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Animated filter content
        AnimatedCrossFade(
          alignment: Alignment.centerLeft,
          firstChild: Padding(
            padding: EdgeInsets.fromLTRB(hPadding, 12, hPadding, 12),
            child: isWide
                ? Row(
                    children: [
                      Expanded(
                        child: _buildFilterDropdown<TransactionType?>(
                          value: _selectedType,
                          hint: 'All Types',
                          icon: Icons.swap_vert_rounded,
                          items: [
                            const DropdownMenuItem(child: Text('All Types')),
                            const DropdownMenuItem(
                              value: TransactionType.income,
                              child: Text('Income'),
                            ),
                            const DropdownMenuItem(
                              value: TransactionType.expense,
                              child: Text('Expense'),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => _selectedType = value),
                          selectedColor: _selectedType != null
                              ? (_selectedType == TransactionType.income
                                    ? const Color(0xFF10B981)
                                    : Colors.redAccent)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFilterDropdown<String?>(
                          value: _selectedSourceId,
                          hint: 'All Sources',
                          icon: Icons.account_balance_wallet_outlined,
                          items: [
                            const DropdownMenuItem(child: Text('All Sources')),
                            ...sources.map(
                              (s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.name),
                              ),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => _selectedSourceId = value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _buildDateRangeButton()),
                    ],
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Type Filter
                        SizedBox(
                          width: 140,
                          child: _buildFilterDropdown<TransactionType?>(
                            value: _selectedType,
                            hint: 'All Types',
                            icon: Icons.swap_vert_rounded,
                            items: [
                              const DropdownMenuItem(child: Text('All Types')),
                              const DropdownMenuItem(
                                value: TransactionType.income,
                                child: Text('Income'),
                              ),
                              const DropdownMenuItem(
                                value: TransactionType.expense,
                                child: Text('Expense'),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => _selectedType = value),
                            selectedColor: _selectedType != null
                                ? (_selectedType == TransactionType.income
                                      ? const Color(0xFF10B981)
                                      : Colors.redAccent)
                                : null,
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Source Filter
                        SizedBox(
                          width: 140,
                          child: _buildFilterDropdown<String?>(
                            value: _selectedSourceId,
                            hint: 'All Sources',
                            icon: Icons.account_balance_wallet_outlined,
                            items: [
                              const DropdownMenuItem(
                                child: Text('All Sources'),
                              ),
                              ...sources.map(
                                (s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(s.name),
                                ),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => _selectedSourceId = value),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Date Range Filter
                        SizedBox(width: 140, child: _buildDateRangeButton()),
                      ],
                    ),
                  ),
          ),
          secondChild: const SizedBox(height: 8),
          crossFadeState: _isFilterExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown<T>({
    required T value,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    Color? selectedColor,
  }) {
    final theme = Theme.of(context);
    final bool isActive = value != null;

    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? (selectedColor ?? theme.colorScheme.primary).withValues(
                alpha: 0.1,
              )
            : theme.colorScheme.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? (selectedColor ?? theme.colorScheme.primary).withValues(
                  alpha: 0.3,
                )
              : theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  hint,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          items: items,
          onChanged: onChanged,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: isActive
                ? (selectedColor ?? theme.colorScheme.primary)
                : theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          dropdownColor: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive
                ? (selectedColor ?? theme.colorScheme.primary)
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangeButton() {
    final theme = Theme.of(context);
    final bool isActive = _selectedDateRange != null;

    String label = 'All Dates';
    if (_selectedDateRange != null) {
      final start = DateFormat('MMM d').format(_selectedDateRange!.start);
      final end = DateFormat('MMM d').format(_selectedDateRange!.end);
      label = '$start - $end';
    }

    return InkWell(
      onTap: _showDateRangePicker,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? theme.colorScheme.primary.withValues(alpha: 0.3)
                : theme.colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isActive)
              GestureDetector(
                onTap: () => setState(() => _selectedDateRange = null),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              )
            else
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBar(int count, double income, double expense) {
    final theme = Theme.of(context);
    final isNarrow = MediaQuery.of(context).size.width < 600;
    final hPadding = isNarrow ? 16.0 : 24.0;
    final isWide = MediaQuery.of(context).size.width > 800;

    return Padding(
      padding: EdgeInsets.fromLTRB(hPadding, 8, hPadding, 16),
      child: isWide
          ? Row(
              children: [
                Expanded(
                  child: _buildStatChip(
                    '$count',
                    'records',
                    Icons.receipt_long_outlined,
                    theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatChip(
                    '+\$${income.toStringAsFixed(0)}',
                    'income',
                    Icons.trending_up_rounded,
                    const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatChip(
                    '-\$${expense.toStringAsFixed(0)}',
                    'expense',
                    Icons.trending_down_rounded,
                    Colors.redAccent,
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: _buildStatChip(
                      '$count',
                      'records',
                      Icons.receipt_long_outlined,
                      theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    child: _buildStatChip(
                      '+\$${income.toStringAsFixed(0)}',
                      'income',
                      Icons.trending_up_rounded,
                      const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    child: _buildStatChip(
                      '-\$${expense.toStringAsFixed(0)}',
                      'expense',
                      Icons.trending_down_rounded,
                      Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatChip(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                _activeFilterCount > 0
                    ? Icons.filter_alt_off_outlined
                    : Icons.receipt_long_outlined,
                size: 48,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _activeFilterCount > 0 ? 'No matching records' : 'No records yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _activeFilterCount > 0
                  ? 'Try adjusting your filters to see more results'
                  : 'Add your first transaction to get started',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              textAlign: TextAlign.center,
            ),
            if (_activeFilterCount > 0) ...[
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: _clearAllFilters,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Clear filters'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList(
    List<Transaction> transactions,
    Map<String, double> runningBalances,
  ) {
    // Sort by date descending
    transactions.sort((a, b) => b.date.compareTo(a.date));

    // Group by date
    final groupedTransactions = <String, List<Transaction>>{};
    for (final tx in transactions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(tx.date);
      groupedTransactions.putIfAbsent(dateKey, () => []).add(tx);
    }

    final sortedKeys = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        final isNarrow = constraints.maxWidth < 600;
        final hPadding = isNarrow ? 16.0 : 24.0;

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(hPadding, 8, hPadding, 100),
          itemCount: sortedKeys.length,
          itemBuilder: (context, index) {
            final dateKey = sortedKeys[index];
            final dayTransactions = groupedTransactions[dateKey]!;
            final date = DateTime.parse(dateKey);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateHeader(date),
                if (isWide)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 110,
                        ),
                    itemCount: dayTransactions.length,
                    itemBuilder: (context, idx) {
                      final tx = dayTransactions[idx];
                      return _buildTransactionCard(
                        tx,
                        runningBalances[tx.id] ?? 0.0,
                      );
                    },
                  )
                else
                  ...dayTransactions.map(
                    (tx) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildTransactionCard(
                        tx,
                        runningBalances[tx.id] ?? 0.0,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDateHeader(DateTime date) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final txDate = DateTime(date.year, date.month, date.day);

    String dateLabel;
    if (txDate == today) {
      dateLabel = 'Today';
    } else if (txDate == yesterday) {
      dateLabel = 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      dateLabel = DateFormat('EEEE').format(date);
    } else {
      dateLabel = DateFormat('MMMM d, yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        children: [
          Text(
            dateLabel.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction, double balanceAfter) {
    final theme = Theme.of(context);
    final isIncome = transaction.type == TransactionType.income;
    final accentColor = isIncome ? const Color(0xFF10B981) : Colors.redAccent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (UniversalPlatform.isWeb) {
            context.go('/transaction/${transaction.id}');
          } else {
            unawaited(context.push('/transaction/${transaction.id}'));
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              // Icon with gradient background
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accentColor.withValues(alpha: 0.15),
                      accentColor.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isIncome
                      ? Icons.south_west_rounded
                      : Icons.north_east_rounded,
                  size: 18,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      transaction.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.05,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            transaction.category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.45,
                              ),
                            ),
                          ),
                        ),
                        if (transaction.relatedPerson != null &&
                            transaction.relatedPerson!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.person_outline_rounded,
                            size: 12,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              transaction.relatedPerson!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Amount and time
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${isIncome ? "+" : "-"}\$${transaction.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: -0.5,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('h:mm a').format(transaction.date),
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

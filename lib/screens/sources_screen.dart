import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paisa_khai/blocs/source/source_bloc.dart';
import 'package:paisa_khai/blocs/transaction/transaction_bloc.dart';
import 'package:paisa_khai/models/source.dart';
import 'package:paisa_khai/models/transaction.dart';
import 'package:uuid/uuid.dart';

class SourcesScreen extends StatefulWidget {
  const SourcesScreen({super.key});

  @override
  State<SourcesScreen> createState() => _SourcesScreenState();
}

class _SourcesScreenState extends State<SourcesScreen> {
  final List<String> _availableIcons = [
    '🏦',
    '📱',
    '💵',
    '💳',
    '🪙',
    '💰',
    '💼',
    '🏠',
    '🏥',
    '🚗',
  ];

  double _calculateSourceBalance(
    Source source,
    List<Transaction> transactions,
  ) {
    double balance = source.initialBalance;
    for (final tx in transactions) {
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SourceBloc, SourceState>(
      builder: (context, sourceState) {
        return BlocBuilder<TransactionBloc, TransactionState>(
          builder: (context, txState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildSourceList(
                    sourceState.sources,
                    txState.transactions,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        final isNarrow = constraints.maxWidth < 600;
        final hPadding = isNarrow ? 16.0 : 24.0;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 24),
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
                            'COLLECTION',
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
                      'Sources',
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
                onPressed: () => _showAddSourceDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 2,
                  shadowColor: theme.colorScheme.primary.withValues(alpha: 0.3),
                  padding: EdgeInsets.symmetric(
                    horizontal: isNarrow ? 16 : 28,
                  ),
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, size: 20),
                    if (constraints.maxWidth > 400) ...[
                      const SizedBox(width: 8),
                      const Text(
                        'NEW SOURCE',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
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

  Widget _buildSourceList(
    List<Source> sources,
    List<Transaction> transactions,
  ) {
    if (sources.isEmpty) {
      return const Center(
        child: Text('No sources found. Add one to start tracking!'),
      );
    }

    final isNarrow = MediaQuery.of(context).size.width < 600;
    final hPadding = isNarrow ? 16.0 : 24.0;
    final isWide =
        MediaQuery.of(context).size.width >
        800; // Assuming this was intended to be used

    if (isWide) {
      return GridView.builder(
        padding: EdgeInsets.all(hPadding),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio: 1.5,
        ),
        itemCount: sources.length,
        itemBuilder: (context, index) => _buildSourceItem(
          sources[index],
          _calculateSourceBalance(sources[index], transactions),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(hPadding),
      itemCount: sources.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildSourceItem(
        sources[index],
        _calculateSourceBalance(sources[index], transactions),
      ),
    );
  }

  Widget _buildSourceItem(Source source, double balance) {
    final theme = Theme.of(context);
    return Container(
      height: 210,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(source.icon, style: const TextStyle(fontSize: 24)),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                onPressed: () => _deleteSource(source),
                style: IconButton.styleFrom(
                  foregroundColor: Colors.red,
                  backgroundColor: Colors.red.withValues(alpha: 0.05),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            source.name,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            source.type.name.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '\$${balance.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              color: balance < 0 ? Colors.red : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSource(Source source) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Source?'),
        content: const Text(
          'This will remove the source. Past transactions remain but will no longer be linked visually.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<SourceBloc>().add(DeleteSource(source.id));
    }
  }

  Future<void> _showAddSourceDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final balanceController = TextEditingController(text: '0');
    SourceType selectedType = SourceType.bank;
    String selectedIcon = '🏦';
    final uuid = const Uuid();
    final theme = Theme.of(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isWide = MediaQuery.of(context).size.width > 800;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWide ? 600 : double.infinity,
              ),
              child: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 32,
                  top: 32,
                  left: 32,
                  right: 32,
                ),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'NEW SOURCE',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                if (nameController.text.isNotEmpty) {
                                  final sourceId = uuid.v4();
                                  final initialAmount =
                                      double.tryParse(balanceController.text) ??
                                      0.0;

                                  final source = Source(
                                    id: sourceId,
                                    name: nameController.text,
                                    type: selectedType,
                                    icon: selectedIcon,
                                    color: '0xFF000000',
                                  );

                                  context.read<SourceBloc>().add(
                                    AddSource(source),
                                  );

                                  if (initialAmount != 0) {
                                    final initialTx = Transaction(
                                      id: uuid.v4(),
                                      title: 'Initial Balance - ${source.name}',
                                      amount: initialAmount.abs(),
                                      date: DateTime.now(),
                                      type: initialAmount > 0
                                          ? TransactionType.income
                                          : TransactionType.expense,
                                      category: 'Initial Balance',
                                      sources: [
                                        TransactionSourceSplit(
                                          sourceId: sourceId,
                                          amount: initialAmount.abs(),
                                        ),
                                      ],
                                    );
                                    context.read<TransactionBloc>().add(
                                      AddTransaction(initialTx),
                                    );
                                  }

                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                }
                              },
                              child: const Text('CREATE'),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.pop(context),
                              style: IconButton.styleFrom(
                                backgroundColor: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.05),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildModalTextField(
                      nameController,
                      'SOURCE NAME',
                      'e.g., HBL Bank',
                      Icons.account_balance_rounded,
                      theme,
                    ),
                    const SizedBox(height: 24),
                    _buildModalTextField(
                      balanceController,
                      'INITIAL BALANCE',
                      '0.00',
                      Icons.attach_money_rounded,
                      theme,
                      isNumber: true,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'TYPE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: SourceType.values.map((type) {
                        final isSelected = selectedType == type;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(type.name.toUpperCase()),
                            selected: isSelected,
                            onSelected: (val) =>
                                setModalState(() => selectedType = type),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'ICON',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _availableIcons.map((icon) {
                        final isSelected = selectedIcon == icon;
                        return InkWell(
                          onTap: () => setModalState(() => selectedIcon = icon),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withValues(
                                      alpha: 0.05,
                                    ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              icon,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModalTextField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon,
    ThemeData theme, {
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18),
            filled: true,
            fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

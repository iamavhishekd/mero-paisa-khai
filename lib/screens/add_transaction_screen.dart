import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:paisa_khai/blocs/category/category_bloc.dart';
import 'package:paisa_khai/blocs/source/source_bloc.dart';
import 'package:paisa_khai/blocs/transaction/transaction_bloc.dart';
import 'package:paisa_khai/models/category.dart';
import 'package:paisa_khai/models/source.dart';
import 'package:paisa_khai/models/transaction.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:uuid/uuid.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? transactionToEdit;

  const AddTransactionScreen({super.key, this.transactionToEdit});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  TransactionType _selectedType = TransactionType.expense;
  Category? _selectedCategory;
  String _title = '';
  double _amount = 0;
  String? _description;
  String? _relatedPerson;
  DateTime _selectedDate = DateTime.now();
  bool _isUrgent = false;
  String? _receiptPath;

  List<Category> _availableCategories = [];
  List<Source> _availableSources = [];
  final Map<String, double> _sourceSplits = {};
  final Map<String, TextEditingController> _sourceControllers = {};

  @override
  void initState() {
    super.initState();
    final sourceState = context.read<SourceBloc>().state;
    final categoryState = context.read<CategoryBloc>().state;
    _loadSources(sourceState.sources);
    if (widget.transactionToEdit != null) {
      final tx = widget.transactionToEdit!;
      _selectedType = tx.type;
      _title = tx.title;
      _amount = tx.amount;
      _description = tx.description;
      _relatedPerson = tx.relatedPerson;
      _selectedDate = tx.date;
      _isUrgent = tx.isUrgent ?? false;
      _receiptPath = tx.receiptPath;

      if (tx.sources != null) {
        for (final split in tx.sources!) {
          _sourceSplits[split.sourceId] = split.amount;
          _sourceControllers[split.sourceId]?.text = split.amount
              .toStringAsFixed(2);
        }
        _autoBalanceSources();
      }
    }
    _loadCategories(categoryState.categories);
  }

  void _loadSources(List<Source> sources) {
    _availableSources = sources;
    for (final source in _availableSources) {
      if (!_sourceControllers.containsKey(source.id)) {
        _sourceControllers[source.id] = TextEditingController();
      }
    }
  }

  void _loadCategories(List<Category> categories) {
    _availableCategories = categories
        .where(
          (category) =>
              category.type == _selectedType ||
              category.type == TransactionType.both,
        )
        .toList();

    if (widget.transactionToEdit != null && _selectedCategory == null) {
      _selectedCategory = _availableCategories.firstWhere(
        (c) => c.name == widget.transactionToEdit!.category,
        orElse: () => _availableCategories.isNotEmpty
            ? _availableCategories.first
            : Category(
                id: 'dummy',
                name: widget.transactionToEdit!.category,
                type: widget.transactionToEdit!.type,
                icon: '❓',
                color: '0xFF808080',
              ),
      );
    } else if (_selectedCategory == null && _availableCategories.isNotEmpty) {
      _selectedCategory = _availableCategories.first;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _autoBalanceSources([String? editedSourceId]) {
    if (_sourceSplits.length == 1) {
      final sourceId = _sourceSplits.keys.first;
      _sourceSplits[sourceId] = _amount;
      // Update controller only if it exists and we're not currently editing it from its own field
      if (editedSourceId == null) {
        _sourceControllers[sourceId]?.text = _amount > 0
            ? _amount.toStringAsFixed(2)
            : '';
      }
    }
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate() && _selectedCategory != null) {
      _formKey.currentState!.save();

      if (_sourceSplits.length == 1) {
        _sourceSplits[_sourceSplits.keys.first] = _amount;
      }

      if (_sourceSplits.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one funding source'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validate source splits (re-check just in case)
      final totalSplits = _sourceSplits.values.fold(
        0.0,
        (sum, amount) => sum + amount,
      );
      if ((totalSplits - _amount).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Total source amounts (\$${totalSplits.toStringAsFixed(2)}) must equal transaction amount (\$${_amount.toStringAsFixed(2)})',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final splits = _sourceSplits.entries
          .where((e) => e.value > 0)
          .map(
            (e) => TransactionSourceSplit(sourceId: e.key, amount: e.value),
          )
          .toList();

      final transaction = Transaction(
        id: widget.transactionToEdit?.id ?? _uuid.v4(),
        title: _title,
        amount: _amount,
        date: _selectedDate,
        type: _selectedType,
        category: _selectedCategory!.name,
        description: _description,
        relatedPerson: _relatedPerson,
        sources: splits,
        isUrgent: _isUrgent,
        receiptPath: _receiptPath,
      );

      if (widget.transactionToEdit != null) {
        context.read<TransactionBloc>().add(UpdateTransaction(transaction));
      } else {
        context.read<TransactionBloc>().add(AddTransaction(transaction));
      }

      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<SourceBloc, SourceState>(
      builder: (context, sourceState) {
        return BlocBuilder<CategoryBloc, CategoryState>(
          builder: (context, categoryState) {
            _loadSources(sourceState.sources);
            _loadCategories(categoryState.categories);

            return Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              body: SafeArea(
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 600;
                          final hPadding = isNarrow ? 16.0 : 32.0;

                          return SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              hPadding,
                              0,
                              hPadding,
                              80,
                            ),
                            child: Form(
                              key: _formKey,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final isWide = constraints.maxWidth > 800;
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: isWide ? 6 : 1,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildIdentificationSection(),
                                            SizedBox(
                                              height: isNarrow ? 16 : 24,
                                            ),
                                            _buildPreferencesSection(),
                                            SizedBox(
                                              height: isNarrow ? 16 : 24,
                                            ),
                                            _buildSourcesSection(),
                                            if (!isWide) ...[
                                              SizedBox(
                                                height: isNarrow ? 16 : 24,
                                              ),
                                              _buildAmountAndDateSection(),
                                            ],
                                          ],
                                        ),
                                      ),
                                      if (isWide) ...[
                                        const SizedBox(width: 32),
                                        Expanded(
                                          flex: 4,
                                          child: _buildAmountAndDateSection(),
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isNarrow = screenWidth < 600;
        final isVeryNarrow = screenWidth < 400;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isNarrow ? 16 : 32,
            vertical: isNarrow ? 12 : 16,
          ),
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
                      widget.transactionToEdit != null
                          ? 'Edit Transaction'
                          : 'New Transaction',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: isNarrow ? (isVeryNarrow ? 20 : 24) : 32,
                        letterSpacing: -1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed:
                    _amount > 0 &&
                        _sourceSplits.isNotEmpty &&
                        (_sourceSplits.length == 1 ||
                            (_sourceSplits.values.fold(0.0, (s, a) => s + a) -
                                        _amount)
                                    .abs() <
                                0.01)
                    ? _saveTransaction
                    : null,
                style:
                    ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      disabledBackgroundColor: theme.colorScheme.onSurface
                          .withValues(alpha: 0.05),
                      disabledForegroundColor: theme.colorScheme.onSurface
                          .withValues(alpha: 0.2),
                      elevation: 0,
                      shadowColor: theme.colorScheme.primary.withValues(
                        alpha: 0.4,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isVeryNarrow ? 20 : 32,
                      ),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ).copyWith(
                      elevation: WidgetStateProperty.resolveWith<double>((
                        states,
                      ) {
                        if (states.contains(WidgetState.disabled)) return 0;
                        if (states.contains(WidgetState.hovered) ||
                            states.contains(WidgetState.pressed)) {
                          return 8;
                        }
                        return 2;
                      }),
                    ),
                child: Text(
                  widget.transactionToEdit != null ? 'SAVE' : 'CREATE',
                  style: TextStyle(
                    fontSize: isVeryNarrow ? 12 : 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.onSurface.withValues(
                    alpha: 0.05,
                  ),
                  foregroundColor: theme.colorScheme.onSurface,
                  minimumSize: const Size(48, 48),
                  fixedSize: const Size(48, 48),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIdentificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('IDENTIFICATION'),
        const SizedBox(height: 16),
        _buildContentCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TRANSACTION TYPE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              _buildTypeIconSelector(),
              const SizedBox(height: 32),
              _buildCustomTextField(
                label: 'TRANSACTION TITLE',
                hint: 'e.g., Grocery Shopping',
                initialValue: _title,
                icon: Icons.edit_outlined,
                onSaved: (v) => _title = v!,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              _buildCustomTextField(
                label: 'DESCRIPTION (OPTIONAL)',
                hint: 'Add some details...',
                initialValue: _description,
                icon: Icons.notes_outlined,
                onSaved: (v) => _description = v,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('PREFERENCES'),
        const SizedBox(height: 16),
        _buildContentCard(
          child: Column(
            children: [
              _buildSwitchItem(
                label: 'MARK AS URGENT',
                icon: Icons.warning_amber_rounded,
                value: _isUrgent,
                onChanged: (v) => setState(() => _isUrgent = v),
              ),
              const Divider(height: 32),
              _buildSwitchItem(
                label: 'ATTACH RECEIPT SCAN',
                icon: Icons.document_scanner_outlined,
                value: _receiptPath != null,
                onChanged: _handleReceiptToggle,
              ),
              if (_receiptPath != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.image_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _receiptPath!.split('/').last,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => setState(() => _receiptPath = null),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleReceiptToggle(bool value) async {
    if (value) {
      // Desktop: Skip bottom sheet and pick file directly
      if (!UniversalPlatform.isWeb &&
          (UniversalPlatform.isMacOS ||
              UniversalPlatform.isWindows ||
              UniversalPlatform.isLinux)) {
        await _pickFile();
        return;
      }

      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('ATTACH RECEIPT'),
                const SizedBox(height: 24),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: const Text(
                    'Scan with Camera',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImage(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.photo_library_rounded,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  title: const Text(
                    'Pick from Gallery',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      setState(() {
        _receiptPath = null;
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (!mounted) return;
      if (result != null && result.files.single.path != null) {
        final savedPath = await _saveFileLocally(result.files.single.path!);
        if (savedPath != null && mounted) {
          setState(() {
            _receiptPath = savedPath;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      if (!mounted) return;
      if (image != null) {
        final savedPath = await _saveFileLocally(image.path);
        if (savedPath != null && mounted) {
          setState(() {
            _receiptPath = savedPath;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<String?> _saveFileLocally(String sourcePath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory(path.join(directory.path, 'receipts'));
      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }

      final fileName = path.basename(sourcePath);
      final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final destinationPath = path.join(receiptsDir.path, uniqueName);

      await File(sourcePath).copy(destinationPath);
      return destinationPath;
    } catch (e) {
      debugPrint('Error saving file locally: $e');
      return null;
    }
  }

  Widget _buildAmountAndDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('TRANSATION DATA'),
        const SizedBox(height: 16),
        _buildContentCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCustomTextField(
                label: 'AMOUNT',
                hint: '0.00',
                initialValue: _amount > 0 ? _amount.toStringAsFixed(2) : null,
                icon: Icons.attach_money_rounded,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onSaved: (v) => _amount = double.tryParse(v ?? '') ?? 0,
                onChanged: (v) {
                  setState(() {
                    _amount = double.tryParse(v) ?? 0;
                    _autoBalanceSources();
                  });
                },
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildCategorySelector(),
              const SizedBox(height: 24),
              const Text(
                'DATE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _selectDate(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('MMM d, yyyy').format(_selectedDate),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildCustomTextField(
                label: 'RELATED PERSON',
                hint: 'e.g., John Doe',
                initialValue: _relatedPerson,
                icon: Icons.person_outline_rounded,
                onSaved: (v) => _relatedPerson = v,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
      ),
    );
  }

  Widget _buildContentCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: child,
    );
  }

  Widget _buildTypeIconSelector() {
    return Row(
      children: [
        _buildTypeIconItem(
          TransactionType.expense,
          Icons.upload_rounded,
          'EXPENSE',
        ),
        const SizedBox(width: 16),
        _buildTypeIconItem(
          TransactionType.income,
          Icons.download_rounded,
          'INCOME',
        ),
      ],
    );
  }

  Widget _buildTypeIconItem(TransactionType type, IconData icon, String label) {
    final isSelected = _selectedType == type;
    final theme = Theme.of(context);
    final isNarrow = MediaQuery.of(context).size.width < 600;

    return Expanded(
      child: GestureDetector(
        onTap: widget.transactionToEdit != null
            ? null
            : () => setState(() {
                _selectedType = type;
                _loadCategories(context.read<CategoryBloc>().state.categories);
              }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: isNarrow ? 12 : 16),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: widget.transactionToEdit != null && isSelected
                ? Border.all(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  )
                : null,
          ),
          child: Opacity(
            opacity: widget.transactionToEdit != null && !isSelected
                ? 0.3
                : 1.0,
            child: Column(
              children: [
                Icon(
                  icon,
                  size: isNarrow ? 20 : 24,
                  color: isSelected
                      ? theme.colorScheme.surface
                      : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                SizedBox(height: isNarrow ? 4 : 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isNarrow ? 9 : 10,
                    fontWeight: FontWeight.w900,
                    color: isSelected
                        ? theme.colorScheme.surface
                        : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTextField({
    required String label,
    required String hint,
    required IconData icon,
    String? initialValue,
    TextInputType keyboardType = TextInputType.text,
    FormFieldSetter<String>? onSaved,
    FormFieldValidator<String>? validator,
    ValueChanged<String>? onChanged,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: initialValue,
          style: const TextStyle(fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              size: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          keyboardType: keyboardType,
          onSaved: onSaved,
          validator: validator,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSwitchItem({
    required String label,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Switch.adaptive(value: value, onChanged: onChanged),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CATEGORY TAG',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<Category>(
          initialValue: _selectedCategory,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.tag_rounded, size: 18),
            filled: true,
            fillColor: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          items: _availableCategories
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Row(
                    children: [
                      Text(c.icon),
                      const SizedBox(width: 8),
                      Text(
                        c.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _selectedCategory = v),
        ),
      ],
    );
  }

  Widget _buildSourcesSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('FUNDING SOURCES'),
        const SizedBox(height: 16),
        _buildContentCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_availableSources.isEmpty)
                const Text(
                  'No sources available. Please add one in Sources screen.',
                )
              else
                ..._availableSources.map((source) {
                  final isSelected = _sourceSplits.containsKey(source.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      children: [
                        CheckboxListTile(
                          title: Row(
                            children: [
                              Text(source.icon),
                              const SizedBox(width: 12),
                              Text(
                                source.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _sourceSplits[source.id] = 0.0;
                                _sourceControllers[source.id]?.text = '';

                                // If we now have multiple sources, clear all previous auto-fills
                                if (_sourceSplits.length > 1) {
                                  for (final id in _sourceSplits.keys) {
                                    _sourceSplits[id] = 0.0;
                                    _sourceControllers[id]?.text = '';
                                  }
                                }
                              } else {
                                _sourceSplits.remove(source.id);
                                _sourceControllers[source.id]?.clear();
                              }
                              _autoBalanceSources();
                            });
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          checkboxShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        if (isSelected)
                          Padding(
                            padding: const EdgeInsets.only(left: 48),
                            child: _sourceSplits.length == 1
                                ? Text(
                                    '100% will be deducted from this source',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.primary,
                                    ),
                                  )
                                : TextFormField(
                                    controller: _sourceControllers[source.id],
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: InputDecoration(
                                      prefixText: '\$ ',
                                      hintText: '0.00',
                                      isDense: true,
                                      filled: true,
                                      fillColor: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.05),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    onChanged: (v) {
                                      final parsed = double.tryParse(v) ?? 0.0;

                                      // Calculate total of other selected sources
                                      double otherTotal = 0;
                                      for (var entry in _sourceSplits.entries) {
                                        if (entry.key != source.id) {
                                          otherTotal += entry.value;
                                        }
                                      }

                                      double finalVal = parsed;
                                      if (otherTotal + finalVal > _amount) {
                                        finalVal = _amount - otherTotal;
                                        if (finalVal < 0) finalVal = 0;

                                        // Update text field to capped value
                                        _sourceControllers[source.id]?.text =
                                            finalVal.toStringAsFixed(2);
                                        _sourceControllers[source.id]
                                                ?.selection =
                                            TextSelection.fromPosition(
                                              TextPosition(
                                                offset:
                                                    _sourceControllers[source
                                                            .id]!
                                                        .text
                                                        .length,
                                              ),
                                            );
                                      }

                                      setState(() {
                                        _sourceSplits[source.id] = finalVal;
                                      });
                                      _autoBalanceSources(source.id);
                                    },
                                  ),
                          ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL ASSIGNED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '\$${_sourceSplits.values.fold(0.0, (s, a) => s + a).toStringAsFixed(2)} / \$${_amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color:
                          (_sourceSplits.values.fold(0.0, (s, a) => s + a) -
                                      _amount)
                                  .abs() >
                              0.01
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

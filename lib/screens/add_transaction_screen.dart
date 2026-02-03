import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paisa_khai/hive/hive_service.dart';
import 'package:paisa_khai/models/category.dart';
import 'package:paisa_khai/models/transaction.dart';
import 'package:uuid/uuid.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

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

  List<Category> _availableCategories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    _availableCategories = HiveService.categoriesBoxInstance.values
        .where((category) => category.type == _selectedType)
        .toList();

    if (_availableCategories.isNotEmpty) {
      _selectedCategory = _availableCategories.first;
    } else {
      _selectedCategory = null;
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

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate() && _selectedCategory != null) {
      _formKey.currentState!.save();

      final transaction = Transaction(
        id: _uuid.v4(),
        title: _title,
        amount: _amount,
        date: _selectedDate,
        type: _selectedType,
        category: _selectedCategory!.name,
        description: _description,
        relatedPerson: _relatedPerson,
      );

      await HiveService.transactionsBoxInstance.put(
        transaction.id,
        transaction,
      );

      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Record'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypeSelector(),
              const SizedBox(height: 32),
              _buildSectionHeader('Transaction Details'),
              const SizedBox(height: 16),
              TextFormField(
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  labelText: 'Entry Title',
                  hintText: 'e.g., Grocery Shopping',
                  prefixIcon: Icon(Icons.title_outlined),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please enter a title'
                    : null,
                onSaved: (value) => _title = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.attach_money_outlined),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please enter an amount';
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0)
                    return 'Please enter a valid amount';
                  return null;
                },
                onSaved: (value) => _amount = double.parse(value!),
              ),
              const SizedBox(height: 16),
              _buildCategorySelector(),
              const SizedBox(height: 16),
              _buildDatePicker(),
              const SizedBox(height: 32),
              _buildSectionHeader('Additional Information'),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Who is involved?',
                  hintText: 'e.g., John Doe',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                onSaved: (value) => _relatedPerson = value,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Add a description...',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                maxLines: 3,
                onSaved: (value) => _description = value,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveTransaction,
                  child: const Text('SUBMIT TRANSACTION'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _buildTypeButton(
            TransactionType.expense,
            'EXPENSE',
            Icons.arrow_outward,
          ),
          _buildTypeButton(
            TransactionType.income,
            'INCOME',
            Icons.arrow_downward,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(TransactionType type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
            _loadCategories();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? Colors.white : Colors.black)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(
                        0.1,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? (isDark ? Colors.black : Colors.white)
                    : theme.colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.5,
                  color: isSelected
                      ? (isDark ? Colors.black : Colors.white)
                      : theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    if (_availableCategories.isEmpty) return const SizedBox.shrink();

    return DropdownButtonFormField<Category>(
      initialValue: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Category Tag',
        prefixIcon: Icon(Icons.tag_outlined),
      ),
      items: _availableCategories
          .map(
            (category) => DropdownMenuItem<Category>(
              value: category,
              child: Row(
                children: [
                  Text(category.icon, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  Text(
                    category.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value;
        });
      },
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () => _selectDate(context),
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date of Activity',
          prefixIcon: Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          DateFormat('EEEE, d MMMM yyyy').format(_selectedDate),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }
}

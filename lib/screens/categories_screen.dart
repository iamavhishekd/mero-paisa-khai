import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:paisa_khai/hive/hive_service.dart';
import 'package:paisa_khai/models/category.dart';
import 'package:paisa_khai/models/transaction.dart';
import 'package:uuid/uuid.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final List<String> _availableIcons = [
    '💰',
    '💼',
    '🍔',
    '🚗',
    '🛍️',
    '🏠',
    '🏥',
    '🎓',
    '🎮',
    '✈️',
    '🍎',
    '📱',
    '🎭',
    '🏋️',
    '🐈',
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Tags'),
          bottom: const TabBar(
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 4,
            tabs: [
              Tab(text: 'EXPENSES'),
              Tab(text: 'INCOME'),
            ],
          ),
        ),
        body: ValueListenableBuilder<Box<Category>>(
          valueListenable: HiveService.categoriesBoxInstance.listenable(),
          builder: (context, box, _) {
            final categories = box.values.toList();

            return TabBarView(
              children: [
                _buildCategoryList(
                  categories
                      .where((c) => c.type == TransactionType.expense)
                      .toList(),
                ),
                _buildCategoryList(
                  categories
                      .where((c) => c.type == TransactionType.income)
                      .toList(),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddCategoryDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildCategoryList(List<Category> categories) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.tag_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            ),
            const SizedBox(height: 16),
            Text(
              'No tags here',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  category.icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  category.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.3),
                ),
                onPressed: () => _deleteCategory(category.id),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteCategory(String id) async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tag'),
        content: const Text(
          'All records using this tag will remain, but the tag itself will be removed. Proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'CANCEL',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'DELETE',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await HiveService.categoriesBoxInstance.delete(id);
    }
  }

  Future<void> _showAddCategoryDialog(BuildContext context) async {
    final nameController = TextEditingController();
    TransactionType selectedType = TransactionType.expense;
    String selectedIcon = '💰';
    final uuid = const Uuid();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 24,
              left: 24,
              right: 24,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'New Category Tag',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Tag Name',
                    hintText: 'e.g., Subscriptions',
                  ),
                ),
                const SizedBox(height: 16),
                _buildModalTypeSelector(selectedType, (type) {
                  setModalState(() => selectedType = type);
                }),
                const SizedBox(height: 24),
                const Text(
                  'SELECT ICON',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _availableIcons.length,
                    itemBuilder: (context, index) {
                      final icon = _availableIcons[index];
                      final isSelected = selectedIcon == icon;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedIcon = icon),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 48,
                          height: 48,
                          margin: const EdgeInsets.only(right: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            icon,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isNotEmpty) {
                        final category = Category(
                          id: uuid.v4(),
                          name: nameController.text,
                          type: selectedType,
                          icon: selectedIcon,
                          color: '0xFF000000',
                        );
                        await HiveService.categoriesBoxInstance.put(
                          category.id,
                          category,
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('CREATE TAG'),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModalTypeSelector(
    TransactionType current,
    void Function(TransactionType) onTypeChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildModalTypeButton(
            TransactionType.expense,
            'EXPENSE',
            current == TransactionType.expense,
            onTypeChanged,
          ),
          _buildModalTypeButton(
            TransactionType.income,
            'INCOME',
            current == TransactionType.income,
            onTypeChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildModalTypeButton(
    TransactionType type,
    String label,
    bool isSelected,
    void Function(TransactionType) onTypeChanged,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTypeChanged(type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? Colors.white : Colors.black)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                color: isSelected
                    ? (isDark ? Colors.black : Colors.white)
                    : theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

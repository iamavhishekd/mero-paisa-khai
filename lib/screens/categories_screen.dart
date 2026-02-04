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
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              final hPadding = isNarrow ? 16.0 : 24.0;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: hPadding),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TabBar(
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: theme.colorScheme.onSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: theme.colorScheme.surface,
                    unselectedLabelColor: theme.colorScheme.onSurface
                        .withValues(
                          alpha: 0.5,
                        ),
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                    tabs: const [
                      Tab(text: 'EXPENSES'),
                      Tab(text: 'INCOME'),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ValueListenableBuilder<Box<Category>>(
              valueListenable: HiveService.categoriesBoxInstance.listenable(),
              builder: (context, box, _) {
                final categories = box.values.toList();

                return TabBarView(
                  children: [
                    _buildCategoryList(
                      categories
                          .where(
                            (c) =>
                                c.type == TransactionType.expense ||
                                c.type == TransactionType.both,
                          )
                          .toList(),
                    ),
                    _buildCategoryList(
                      categories
                          .where(
                            (c) =>
                                c.type == TransactionType.income ||
                                c.type == TransactionType.both,
                          )
                          .toList(),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        final isNarrow = constraints.maxWidth < 600;
        final hPadding = isNarrow ? 16.0 : 24.0;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: hPadding,
            vertical: 24,
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
                      'Categories',
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
                onPressed: () => _showAddCategoryDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 2,
                  shadowColor: theme.colorScheme.primary.withValues(alpha: 0.3),
                  padding: EdgeInsets.symmetric(
                    horizontal: isNarrow ? 16 : 28,
                    vertical: isNarrow ? 14 : 18,
                  ),
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
                        'NEW TAG',
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

  Widget _buildCategoryList(List<Category> categories) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.tag_outlined,
              size: 48,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 16),
            Text(
              'No tags here',
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800
            ? 3
            : (constraints.maxWidth > 600 ? 2 : 1);

        if (crossAxisCount > 1) {
          return GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              mainAxisExtent: 80,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryItem(category);
            },
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildCategoryItem(category),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryItem(Category category) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.08),
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
              ).colorScheme.onSurface.withValues(alpha: 0.05),
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
              ).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            onPressed: () => _deleteCategory(category.id),
          ),
        ],
      ),
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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 40,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'COLLECTIVE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                            const Text(
                              'NEW TAG',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            ElevatedButton(
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
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('CREATE'),
                            ),
                            const SizedBox(width: 12),
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
                    Text(
                      'IDENTIFICATION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.05,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TAG NAME',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: nameController,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'e.g., Subscriptions',
                              prefixIcon: const Icon(
                                Icons.tag_rounded,
                                size: 18,
                              ),
                              filled: true,
                              fillColor: theme.colorScheme.onSurface.withValues(
                                alpha: 0.05,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildModalTypeSelector(selectedType, (type) {
                            setModalState(() => selectedType = type);
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'VISUALS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.05,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SELECT ICON',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 56,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _availableIcons.length,
                              itemBuilder: (context, index) {
                                final icon = _availableIcons[index];
                                final isSelected = selectedIcon == icon;
                                return GestureDetector(
                                  onTap: () =>
                                      setModalState(() => selectedIcon = icon),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 56,
                                    height: 56,
                                    margin: const EdgeInsets.only(right: 12),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? theme.colorScheme.onSurface
                                          : theme.colorScheme.onSurface
                                                .withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      icon,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildModalTypeSelector(
    TransactionType current,
    void Function(TransactionType) onTypeChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
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
          _buildModalTypeButton(
            TransactionType.both,
            'BOTH',
            current == TransactionType.both,
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
                    : theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

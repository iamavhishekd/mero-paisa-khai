import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:paisa_khai/hive/hive_service.dart';
import 'package:paisa_khai/main.dart';
import 'package:paisa_khai/services/csv_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;
  bool _isImporting = false;

  Future<void> _requestStoragePermission() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final status = await Permission.storage.request();
      if (status != PermissionStatus.granted) {
        if (status == PermissionStatus.permanentlyDenied) {
          await openAppSettings();
        }
        throw Exception('Storage permission denied');
      }
    }
  }

  Future<void> _requestManageStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.request().isGranted) {
        return;
      }
    }
    await _requestStoragePermission();
  }

  Future<void> _exportData() async {
    try {
      setState(() => _isExporting = true);

      await _requestManageStoragePermission();

      final csvData = await CSVService.exportToCSV();
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'expense_tracker_${DateTime.now().millisecondsSinceEpoch}.csv';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsString(csvData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data exported to: $filePath'),
          backgroundColor: Theme.of(context).colorScheme.onSurface,
          action: SnackBarAction(
            label: 'Open',
            onPressed: () async {
              await _showFileInfoDialog(filePath);
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.onSurface,
        ),
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _importData() async {
    try {
      setState(() => _isImporting = true);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isImporting = false);
        return;
      }

      final file = File(result.files.single.path!);
      final fileSize = await file.length();

      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('File too large. Maximum size is 10MB');
      }

      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import Confirmation'),
          content: const Text(
            'This will import transactions from the CSV file. Existing transactions will remain. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Import'),
            ),
          ],
        ),
      );

      if (confirm != true) {
        setState(() => _isImporting = false);
        return;
      }

      await CSVService.importFromCSV(file.path);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Data imported successfully'),
          backgroundColor: Theme.of(context).colorScheme.onSurface,
        ),
      );

      HiveService.transactionsBoxInstance.listenable();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.onSurface,
        ),
      );
    } finally {
      setState(() => _isImporting = false);
    }
  }

  Future<void> _backupData() async {
    try {
      setState(() => _isExporting = true);

      await _requestManageStoragePermission();

      final transactions = HiveService.transactionsBoxInstance.values.toList();
      final categories = HiveService.categoriesBoxInstance.values.toList();

      if (transactions.isEmpty && categories.isEmpty) {
        throw Exception('No data to backup');
      }

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupDir = Directory(
        '${directory.path}/expense_tracker_backup_$timestamp',
      );
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final transactionsCsv = await CSVService.exportToCSV();
      final transactionsFile = File('${backupDir.path}/transactions.csv');
      await transactionsFile.writeAsString(transactionsCsv);

      final categoriesData = categories.map((c) => c.toJson()).toList();
      final categoriesFile = File('${backupDir.path}/categories.json');
      await categoriesFile.writeAsString(jsonEncode(categoriesData));

      final metadata = {
        'backup_date': DateTime.now().toIso8601String(),
        'transaction_count': transactions.length,
        'category_count': categories.length,
        'app_version': '1.0.0',
      };

      final metadataFile = File('${backupDir.path}/metadata.json');
      await metadataFile.writeAsString(jsonEncode(metadata));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup created: ${backupDir.path}'),
          backgroundColor: Theme.of(context).colorScheme.onSurface,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'View',
            onPressed: () async {
              await _showBackupInfoDialog(backupDir.path);
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.onSurface,
        ),
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _showFileInfoDialog(String filePath) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your data has been exported to:'),
            const SizedBox(height: 10),
            Text(
              filePath,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showBackupInfoDialog(String backupPath) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup Created'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your backup has been created in:'),
            const SizedBox(height: 10),
            Text(
              backupPath,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllData() async {
    final confirm1 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data?'),
        content: const Text(
          'This will permanently remove all your transactions, categories, and sources. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirm1 != true) return;

    if (!mounted) return;
    final confirm2 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Are you absolutely sure?'),
        content: const Text(
          'This is your last chance. All data will be wiped and reset to defaults.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('I changed my mind'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Wipe Everything'),
          ),
        ],
      ),
    );

    if (confirm2 == true) {
      await HiveService.clearAndReset();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All data has been wiped and reset.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'SETTINGS',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Appearance'),
                  const SizedBox(height: 16),
                  _buildThemeSelector(),
                  const SizedBox(height: 40),
                  _buildSectionHeader('Data Management'),
                  const SizedBox(height: 16),
                  _buildActionCard(
                    'Export to CSV',
                    'Download all transactions as a CSV file',
                    Icons.upload_rounded,
                    _exportData,
                    _isExporting,
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    'Import from CSV',
                    'Restore data from an external backup file',
                    Icons.download_rounded,
                    _importData,
                    _isImporting,
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    'Full Backup',
                    'Create a complete snapshot of categories & data',
                    Icons.cloud_upload_rounded,
                    _backupData,
                    _isExporting,
                  ),
                  const SizedBox(height: 48),
                  _buildSectionHeader('Danger Zone'),
                  const SizedBox(height: 16),
                  _buildDangerCard(
                    'Delete All Data',
                    'Permanently wipe all transactions and reset the app',
                    Icons.delete_forever_rounded,
                    _deleteAllData,
                  ),
                  const SizedBox(height: 48),
                  _buildSectionHeader('About'),
                  const SizedBox(height: 16),
                  _buildInfoCard(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerCard(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 20, color: Colors.red),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Colors.red.withValues(alpha: 0.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildThemeSelector() {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeMode,
      builder: (context, currentMode, _) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _ThemeOption(
                  label: 'Light',
                  icon: Icons.light_mode_rounded,
                  isSelected: currentMode == ThemeMode.light,
                  onTap: () => ThemeManager.setThemeMode(ThemeMode.light),
                ),
              ),
              Expanded(
                child: _ThemeOption(
                  label: 'Dark',
                  icon: Icons.dark_mode_rounded,
                  isSelected: currentMode == ThemeMode.dark,
                  onTap: () => ThemeManager.setThemeMode(ThemeMode.dark),
                ),
              ),
              Expanded(
                child: _ThemeOption(
                  label: 'System',
                  icon: Icons.settings_suggest_rounded,
                  isSelected: currentMode == ThemeMode.system,
                  onTap: () => ThemeManager.setThemeMode(ThemeMode.system),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
    bool isLoading,
  ) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onSurface,
                          ),
                        )
                      : Icon(
                          icon,
                          size: 20,
                          color: theme.colorScheme.onSurface,
                        ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
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
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paisa Khai',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          Text(
            'A minimalist expense tracker designed for clarity and speed. Your data is stored locally and never leaves your device.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.onSurface.withValues(alpha: 0.07)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                color: isSelected
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

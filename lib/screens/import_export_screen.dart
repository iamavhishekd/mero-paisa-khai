import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:paisa_khai/hive/hive_service.dart';
import 'package:paisa_khai/services/csv_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ImportExportScreen extends StatefulWidget {
  const ImportExportScreen({super.key});

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> {
  bool _isExporting = false;
  bool _isImporting = false;
  String? _exportPath;
  String? _lastBackupPath;

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

      setState(() => _exportPath = filePath);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data exported to: $filePath'),
          backgroundColor: Theme.of(context).colorScheme.onSurface,
          action: SnackBarAction(
            label: 'Open',
            onPressed: () async {
              // Show file info dialog
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
        // 10MB limit
        throw Exception('File too large. Maximum size is 10MB');
      }
      // Show confirmation dialog
      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import Confirmation'),
          content: const Text(
            'This will import transactions from the CSV file. '
            'Existing transactions will remain. Continue?',
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

      // Force UI refresh
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

      // Get all data
      final transactions = HiveService.transactionsBoxInstance.values.toList();
      final categories = HiveService.categoriesBoxInstance.values.toList();

      if (transactions.isEmpty && categories.isEmpty) {
        throw Exception('No data to backup');
      }

      // Create backup directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupDir = Directory(
        '${directory.path}/expense_tracker_backup_$timestamp',
      );
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // Backup transactions as CSV
      final transactionsCsv = await CSVService.exportToCSV();
      final transactionsFile = File('${backupDir.path}/transactions.csv');
      await transactionsFile.writeAsString(transactionsCsv);

      // Backup categories as JSON
      final categoriesData = categories.map((c) => c.toJson()).toList();
      final categoriesFile = File('${backupDir.path}/categories.json');
      await categoriesFile.writeAsString(jsonEncode(categoriesData));

      // Backup metadata
      final metadata = {
        'backup_date': DateTime.now().toIso8601String(),
        'transaction_count': transactions.length,
        'category_count': categories.length,
        'app_version': '1.0.0',
      };

      final metadataFile = File('${backupDir.path}/metadata.json');
      await metadataFile.writeAsString(jsonEncode(metadata));

      setState(() => _lastBackupPath = backupDir.path);

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
            const SizedBox(height: 20),
            const Text(
              'You can find this file in your device\'s storage.',
              style: TextStyle(fontSize: 12),
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
            const SizedBox(height: 20),
            const Text(
              'Backup contains:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            FutureBuilder<Directory>(
              future: Future.value(Directory(backupPath)),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return FutureBuilder<List<FileSystemEntity>>(
                    future: snapshot.data!.list().toList(),
                    builder: (context, filesSnapshot) {
                      if (filesSnapshot.hasData) {
                        final files = filesSnapshot.data!
                            .whereType<File>()
                            .map((f) => f.path.split('/').last)
                            .toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: files
                              .map((file) => Text('• $file'))
                              .toList(),
                        );
                      }
                      return const CircularProgressIndicator();
                    },
                  );
                }
                return const CircularProgressIndicator();
              },
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

  Future<void> _restoreFromBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'json'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      final fileName = file.path.split('/').last;

      if (fileName.endsWith('.csv')) {
        await _importData();
      } else if (fileName.endsWith('.json') &&
          fileName.contains('categories')) {
        // Restore categories from JSON
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content) as List<dynamic>;
        if (!mounted) return;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Restore Categories'),
            content: Text(
              'This will restore ${jsonList.length} categories. '
              'Existing categories will be preserved. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Restore'),
              ),
            ],
          ),
        );

        if (confirm == true && mounted) {
          // Implement category restore logic here
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Category restore feature coming soon'),
              backgroundColor: Theme.of(context).colorScheme.onSurface,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restore failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.onSurface,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export & Backups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () async {
              await showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Data Management'),
                  content: const SingleChildScrollView(
                    child: Text(
                      'Export: Saves all transactions to a CSV file\n\n'
                      'Import: Loads transactions from a CSV file\n\n'
                      'Backup: Creates a complete backup of all data\n\n'
                      'Restore: Restores data from a previous backup\n\n'
                      'Note: CSV files should have the following columns:\n'
                      'ID, Title, Amount, Date, Type, Category, Description, Related Person',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Data Statistics'),
            const SizedBox(height: 16),
            _buildStatsCard(),
            const SizedBox(height: 32),
            _buildSectionHeader('Operations'),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 500 ? 2 : 1;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: crossAxisCount == 2 ? 1.4 : 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildActionCard(
                      'Export to CSV',
                      'Download data as an editable file',
                      Icons.upload_outlined,
                      _exportData,
                      _isExporting,
                    ),
                    _buildActionCard(
                      'Import from CSV',
                      'Restore data from an external file',
                      Icons.download_outlined,
                      _importData,
                      _isImporting,
                    ),
                    _buildActionCard(
                      'Create Backup',
                      'Save a secure copy of everything',
                      Icons.backup_outlined,
                      _backupData,
                      _isExporting,
                    ),
                    _buildActionCard(
                      'Restore Backup',
                      'Recover data from a secure copy',
                      Icons.restore_outlined,
                      _restoreFromBackup,
                      false,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('Recent Activity'),
            const SizedBox(height: 16),
            _buildRecentActivityCard(),
            const SizedBox(height: 100),
          ],
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
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
      ),
    );
  }

  Widget _buildStatsCard() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Records',
            HiveService.transactionsBoxInstance.length.toString(),
            Icons.receipt_long_outlined,
          ),
          _buildStatItem(
            'Tags',
            HiveService.categoriesBoxInstance.length.toString(),
            Icons.category_outlined,
          ),
          _buildStatItem(
            'Storage',
            '${(HiveService.transactionsBoxInstance.length * 0.1).toStringAsFixed(1)} KB',
            Icons.storage_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_exportPath == null && _lastBackupPath == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No recent export or backup activity',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          if (_exportPath != null)
            _buildActivityItem(
              'Last Export',
              _exportPath!,
              Icons.upload_outlined,
            ),
          if (_lastBackupPath != null)
            _buildActivityItem(
              'Last Backup',
              _lastBackupPath!,
              Icons.backup_outlined,
            ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'TIPS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '• Regular backups protect your data from loss\n'
                  '• CSV files can be edited in Excel or Google Sheets\n'
                  '• Export your data before clearing app storage\n'
                  '• Keep backup files in a separate, safe location',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.6,
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

  Widget _buildStatItem(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          size: 20,
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onPressed,
    bool isLoading,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.05,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            )
                          : Icon(
                              icon,
                              color: theme.colorScheme.onSurface,
                              size: 20,
                            ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String path, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  path.split('/').last,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
            onPressed: () {
              // Show file info dialog
              _showFileInfoDialog(filePath);
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
            onPressed: () {
              _showBackupInfoDialog(backupDir.path);
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

  void _showFileInfoDialog(String filePath) {
    showDialog(
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

  void _showBackupInfoDialog(String backupPath) {
    showDialog(
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
        title: const Text('Import & Export'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Help'),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Data Stats Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      '📊 Data Statistics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          'Transactions',
                          HiveService.transactionsBoxInstance.length.toString(),
                          Icons.receipt_long,
                          Theme.of(context).colorScheme.onSurface,
                        ),
                        _buildStatItem(
                          'Categories',
                          HiveService.categoriesBoxInstance.length.toString(),
                          Icons.category,
                          Theme.of(context).colorScheme.onSurface,
                        ),
                        _buildStatItem(
                          'Data Size',
                          '${(HiveService.transactionsBoxInstance.length * 0.1).toStringAsFixed(1)} KB',
                          Icons.storage,
                          Theme.of(context).colorScheme.onSurface,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildActionCard(
                  'Export to CSV',
                  Icons.upload_outlined,
                  Theme.of(context).colorScheme.onSurface,
                  _exportData,
                  _isExporting,
                ),
                _buildActionCard(
                  'Import from CSV',
                  Icons.download_outlined,
                  Theme.of(context).colorScheme.onSurface,
                  _importData,
                  _isImporting,
                ),
                _buildActionCard(
                  'Create Backup',
                  Icons.backup_outlined,
                  Theme.of(context).colorScheme.onSurface,
                  _backupData,
                  _isExporting,
                ),
                _buildActionCard(
                  'Restore Backup',
                  Icons.restore_outlined,
                  Theme.of(context).colorScheme.onSurface,
                  _restoreFromBackup,
                  false,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Recent Activity
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_exportPath != null)
                      _buildActivityItem(
                        'Last Export',
                        _exportPath!,
                        Icons.upload_outlined,
                        Theme.of(context).colorScheme.onSurface,
                      ),
                    if (_lastBackupPath != null)
                      _buildActivityItem(
                        'Last Backup',
                        _lastBackupPath!,
                        Icons.backup_outlined,
                        Theme.of(context).colorScheme.onSurface,
                      ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 10),
                    const Text(
                      '💡 Tips:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Regular backups protect your data\n'
                      '• CSV files can be opened in Excel/Sheets\n'
                      '• Export before clearing app data\n'
                      '• Keep backup files in a safe location',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
    bool isLoading,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              isLoading
                  ? SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    )
                  : Icon(icon, color: color, size: 30),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isLoading ? Colors.grey : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String path,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  path.split('/').last,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
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

import 'dart:io';

import 'package:csv/csv.dart';
import 'package:paisa_khai/hive/hive_service.dart';
import 'package:paisa_khai/models/transaction.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class CSVService {
  static const _uuid = Uuid();

  static Future<String> exportToCSV() async {
    try {
      final transactions = HiveService.transactionsBoxInstance.values.toList();

      if (transactions.isEmpty) {
        throw Exception('No transactions to export');
      }

      final List<List<dynamic>> csvData = [];

      // Add headers
      csvData.add([
        'ID',
        'Title',
        'Amount',
        'Date',
        'Type',
        'Category',
        'Description',
        'Related Person',
      ]);

      // Sort by date
      transactions.sort((a, b) => b.date.compareTo(a.date));

      // Add transaction data
      for (final transaction in transactions) {
        csvData.add([
          transaction.id,
          transaction.title,
          transaction.amount.toStringAsFixed(2),
          transaction.date.toIso8601String(),
          transaction.type.toString().split('.').last,
          transaction.category,
          transaction.description ?? '',
          transaction.relatedPerson ?? '',
        ]);
      }

      final csv = const ListToCsvConverter().convert(csvData);
      return csv;
    } catch (e) {
      rethrow;
    }
  }

  static Future<int> importFromCSV(String filePath) async {
    try {
      final file = File(filePath);
      final csvString = await file.readAsString();

      if (csvString.isEmpty) {
        throw Exception('CSV file is empty');
      }

      final csvTable = const CsvToListConverter().convert(csvString);

      if (csvTable.length < 2) {
        throw Exception('CSV file has no data rows');
      }

      final headers = csvTable[0];

      // Validate headers
      final expectedHeaders = [
        'ID',
        'Title',
        'Amount',
        'Date',
        'Type',
        'Category',
        'Description',
        'Related Person',
      ];
      for (int i = 0; i < expectedHeaders.length; i++) {
        if (i >= headers.length || headers[i] != expectedHeaders[i]) {
          throw Exception(
            'Invalid CSV format. Expected headers: ${expectedHeaders.join(", ")}',
          );
        }
      }

      int importedCount = 0;

      // Skip header row
      for (int i = 1; i < csvTable.length; i++) {
        try {
          final row = csvTable[i];

          if (row.length < 8) {
            continue; // Skip incomplete rows
          }

          // Parse amount
          final amountStr = row[2].toString().replaceAll(',', '');
          final amount = double.tryParse(amountStr) ?? 0.0;

          if (amount <= 0) {
            continue; // Skip invalid amounts
          }

          // Parse date
          DateTime date;
          try {
            date = DateTime.parse(row[3].toString());
          } catch (_) {
            date = DateTime.now();
          }

          // Parse transaction type
          final typeStr = row[4].toString().toLowerCase();
          TransactionType type;
          switch (typeStr) {
            case 'income':
            case 'borrowing':
              type = TransactionType.income;
              break;
            case 'expense':
            case 'lending':
            default:
              type = TransactionType.expense;
          }

          // Generate new ID to avoid conflicts
          final transactionId = _uuid.v4();

          final transaction = Transaction(
            id: transactionId,
            title: row[1].toString().trim(),
            amount: amount,
            date: date,
            type: type,
            category: row[5].toString().trim(),
            description: row[6].toString().trim().isNotEmpty
                ? row[6].toString().trim()
                : null,
            relatedPerson: row[7].toString().trim().isNotEmpty
                ? row[7].toString().trim()
                : null,
          );

          await HiveService.transactionsBoxInstance.put(
            transaction.id,
            transaction,
          );
          importedCount++;
        } catch (_) {
          // Skip individual rows that fail to parse
          continue;
        }
      }

      return importedCount;
    } catch (e) {
      rethrow;
    }
  }

  static Future<String> getDownloadPath() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final directory = await getExternalStorageDirectory();
        return directory?.path ??
            (await getApplicationDocumentsDirectory()).path;
      } else {
        return (await getApplicationDocumentsDirectory()).path;
      }
    } catch (e) {
      return (await getApplicationDocumentsDirectory()).path;
    }
  }
}

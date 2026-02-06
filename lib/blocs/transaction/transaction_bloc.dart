import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:paisa_khai/hive/hive_service.dart';
import 'package:paisa_khai/models/transaction.dart';
import 'package:paisa_khai/services/notification_service.dart';

part 'transaction_event.dart';
part 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  StreamSubscription<BoxEvent>? _transactionsSubscription;

  TransactionBloc() : super(const TransactionState()) {
    on<LoadTransactions>(_onLoadTransactions);
    on<AddTransaction>(_onAddTransaction);
    on<UpdateTransaction>(_onUpdateTransaction);
    on<DeleteTransaction>(_onDeleteTransaction);

    _transactionsSubscription = HiveService.transactionsBoxInstance
        .watch()
        .listen((_) {
          add(LoadTransactions());
        });

    add(LoadTransactions());
  }

  Future<void> _onLoadTransactions(
    LoadTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    emit(state.copyWith(status: TransactionStatus.loading));
    try {
      final transactions = HiveService.transactionsBoxInstance.values.toList();
      emit(
        state.copyWith(
          transactions: transactions,
          status: TransactionStatus.success,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: TransactionStatus.failure));
    }
  }

  Future<void> _onAddTransaction(
    AddTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    await HiveService.transactionsBoxInstance.put(
      event.transaction.id,
      event.transaction,
    );
    // Update notification content for the day
    try {
      await NotificationService().updateDailyNotificationContent();
    } catch (_) {}
  }

  Future<void> _onUpdateTransaction(
    UpdateTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    await HiveService.transactionsBoxInstance.put(
      event.transaction.id,
      event.transaction,
    );
  }

  Future<void> _onDeleteTransaction(
    DeleteTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    await HiveService.transactionsBoxInstance.delete(event.transactionId);
  }

  @override
  Future<void> close() async {
    await _transactionsSubscription?.cancel();
    return super.close();
  }
}

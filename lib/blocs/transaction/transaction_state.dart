part of 'transaction_bloc.dart';

enum TransactionStatus { initial, loading, success, failure }

class TransactionState extends Equatable {
  final List<Transaction> transactions;
  final TransactionStatus status;

  const TransactionState({
    this.transactions = const [],
    this.status = TransactionStatus.initial,
  });

  TransactionState copyWith({
    List<Transaction>? transactions,
    TransactionStatus? status,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [transactions, status];
}

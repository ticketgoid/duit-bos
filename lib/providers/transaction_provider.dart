import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import '../models/transaction_model.dart';
import 'wallet_provider.dart';

// ── Transaction list providers ────────────────────────────────

final allTransactionsProvider =
FutureProvider<List<TransactionModel>>((ref) async {
  return await DatabaseHelper.instance.getAllTransactions();
});

final expenseTransactionsProvider =
FutureProvider<List<TransactionModel>>((ref) async {
  return await DatabaseHelper.instance
      .getTransactionsByType(TransactionType.expense);
});

final incomeTransactionsProvider =
FutureProvider<List<TransactionModel>>((ref) async {
  return await DatabaseHelper.instance
      .getTransactionsByType(TransactionType.income);
});

// ── Total providers ───────────────────────────────────────────

final totalIncomeProvider = FutureProvider<double>((ref) async {
  ref.watch(incomeTransactionsProvider);
  return await DatabaseHelper.instance.getTotalByType(TransactionType.income);
});

final totalExpenseProvider = FutureProvider<double>((ref) async {
  ref.watch(expenseTransactionsProvider);
  return await DatabaseHelper.instance.getTotalByType(TransactionType.expense);
});

// ── Notifier ──────────────────────────────────────────────────

final transactionNotifierProvider =
StateNotifierProvider<TransactionNotifier, AsyncValue<void>>((ref) {
  return TransactionNotifier(ref);
});

class TransactionNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  TransactionNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> addTransaction(TransactionModel transaction) async {
    state = const AsyncValue.loading();
    try {
      await DatabaseHelper.instance.insertTransaction(transaction);
      _invalidateAll();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTransaction(int id) async {
    state = const AsyncValue.loading();
    try {
      await DatabaseHelper.instance.deleteTransaction(id);
      _invalidateAll();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // ✅ Satu method invalidate untuk semua provider terkait
  void _invalidateAll() {
    _ref.invalidate(allTransactionsProvider);
    _ref.invalidate(expenseTransactionsProvider);
    _ref.invalidate(incomeTransactionsProvider);
    _ref.invalidate(totalIncomeProvider);
    _ref.invalidate(totalExpenseProvider);
    _ref.invalidate(walletNotifierProvider);
    _ref.invalidate(allWalletsProvider);
    _ref.invalidate(expenseWalletProvider);   // ✅ wallet chips expense refresh
    _ref.invalidate(incomeWalletProvider);    // ✅ wallet chips income refresh
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wallet_model.dart';
import '../database/database_helper.dart';
import 'transaction_provider.dart';

class WalletNotifier extends AsyncNotifier<List<WalletModel>> {
  @override
  Future<List<WalletModel>> build() async {
    return await DatabaseHelper.instance.getAllWallets(); // ✅ bukan getWallets()
  }
}

final walletNotifierProvider =
AsyncNotifierProvider<WalletNotifier, List<WalletModel>>(WalletNotifier.new);

final expenseWalletProvider = FutureProvider<List<WalletModel>>((ref) async {
  return await DatabaseHelper.instance.getWalletsForExpense(); // ✅
});

final incomeWalletProvider = FutureProvider<List<WalletModel>>((ref) async {
  return await DatabaseHelper.instance.getWalletsForIncome(); // ✅
});

final allWalletsProvider = FutureProvider<List<WalletModel>>((ref) async {
  ref.watch(walletNotifierProvider);
  return await DatabaseHelper.instance.getAllWallets(); // ✅
});

final totalIncomeProvider = FutureProvider<double>((ref) async {
  final transactions = await ref.watch(incomeTransactionsProvider.future);
  return transactions.fold<double>(0.0, (sum, t) => sum + t.amount); // ✅ explicit type
});

final totalExpenseProvider = FutureProvider<double>((ref) async {
  final transactions = await ref.watch(expenseTransactionsProvider.future);
  return transactions.fold<double>(0.0, (sum, t) => sum + t.amount); // ✅ explicit type
});

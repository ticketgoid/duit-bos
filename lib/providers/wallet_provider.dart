import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wallet_model.dart';
import '../database/database_helper.dart';
import 'transaction_provider.dart';

// ── Wallet notifier ──────────────────────────────────────────
class WalletNotifier extends AsyncNotifier<List<WalletModel>> {
  @override
  Future<List<WalletModel>> build() async {
    return await DatabaseHelper.instance.getWallets();
  }

  Future<void> addWallet(WalletModel wallet) async {
    await DatabaseHelper.instance.insertWallet(wallet);
    ref.invalidateSelf();
  }

  Future<void> updateBalance(int walletId, double newBalance) async {
    await DatabaseHelper.instance.updateWalletBalance(walletId, newBalance);
    ref.invalidateSelf();
  }
}

final walletNotifierProvider =
AsyncNotifierProvider<WalletNotifier, List<WalletModel>>(WalletNotifier.new);

// ── Provider untuk chips wallet di expense/income screen ─────
final expenseWalletProvider = FutureProvider<List<WalletModel>>((ref) async {
  return await DatabaseHelper.instance.getWallets();
});

final incomeWalletProvider = FutureProvider<List<WalletModel>>((ref) async {
  return await DatabaseHelper.instance.getWallets();
});

// ── Provider untuk dashboard ─────────────────────────────────
final allWalletsProvider = FutureProvider<List<WalletModel>>((ref) {
  ref.watch(walletNotifierProvider);
  return DatabaseHelper.instance.getWallets();
});

final totalIncomeProvider = FutureProvider<double>((ref) async {
  final transactions = await ref.watch(incomeTransactionsProvider.future);
  return transactions.fold(0.0, (sum, t) => sum + t.amount);
});

final totalExpenseProvider = FutureProvider<double>((ref) async {
  final transactions = await ref.watch(expenseTransactionsProvider.future);
  return transactions.fold(0.0, (sum, t) => sum + t.amount);
});

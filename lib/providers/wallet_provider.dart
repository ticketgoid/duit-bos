import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wallet_model.dart';
import '../database/database_helper.dart';

class WalletNotifier extends AsyncNotifier<List<WalletModel>> {
  @override
  Future<List<WalletModel>> build() async {
    return await DatabaseHelper.instance.getAllWallets();
  }
}

final walletNotifierProvider =
AsyncNotifierProvider<WalletNotifier, List<WalletModel>>(
    WalletNotifier.new);

final allWalletsProvider = FutureProvider<List<WalletModel>>((ref) async {
  ref.watch(walletNotifierProvider);
  return await DatabaseHelper.instance.getAllWallets();
});

final expenseWalletProvider = FutureProvider<List<WalletModel>>((ref) async {
  return await DatabaseHelper.instance.getWalletsForExpense();
});

final incomeWalletProvider = FutureProvider<List<WalletModel>>((ref) async {
  return await DatabaseHelper.instance.getWalletsForIncome();
});

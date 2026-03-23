import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import '../models/transaction_model.dart';

class MonthlySummary {
  final double totalIncome;
  final double totalExpense;
  final double totalBalance;

  MonthlySummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.totalBalance,
  });

  double get netThisMonth => totalIncome - totalExpense;
}

final summaryProvider = FutureProvider<MonthlySummary>((ref) async {
  final now = DateTime.now();
  final firstDay = DateTime(now.year, now.month, 1);
  final lastDay = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

  final income = await DatabaseHelper.instance.getTotalByType(
    TransactionType.income,
    from: firstDay,
    to: lastDay,
  );
  final expense = await DatabaseHelper.instance.getTotalByType(
    TransactionType.expense,
    from: firstDay,
    to: lastDay,
  );
  final balance = await DatabaseHelper.instance.getTotalBalance();

  return MonthlySummary(
    totalIncome: income,
    totalExpense: expense,
    totalBalance: balance,
  );
});

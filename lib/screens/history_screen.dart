import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';

enum HistoryType { all, expense, income }

class HistoryScreen extends ConsumerWidget {
  final HistoryType type;
  const HistoryScreen({super.key, required this.type});

  Color get _bgColor {
    switch (type) {
      case HistoryType.all:
        return const Color(0xFFF0E6FF);
      case HistoryType.expense:
        return const Color(0xFFFFD6E0);
      case HistoryType.income:
        return const Color(0xFFB8F0C8);
    }
  }

  String get _title {
    switch (type) {
      case HistoryType.all:
        return '📋 Semua Riwayat';
      case HistoryType.expense:
        return '💸 Riwayat Pengeluaran';
      case HistoryType.income:
        return '💰 Riwayat Pemasukan';
    }
  }

  Color get _accentColor {
    switch (type) {
      case HistoryType.all:
        return const Color(0xFF9B8AAE);
      case HistoryType.expense:
        return const Color(0xFFFF8FAB);
      case HistoryType.income:
        return const Color(0xFF4CAF50);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = switch (type) {
      HistoryType.all    => ref.watch(allTransactionsProvider),
      HistoryType.expense => ref.watch(expenseTransactionsProvider),
      HistoryType.income  => ref.watch(incomeTransactionsProvider),
    };

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Text(
                _title,
                style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF5C4A6E),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: transactionsAsync.when(
                data: (transactions) {
                  if (transactions.isEmpty) return _buildEmpty();
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) =>
                        _buildTransactionCard(context, ref, transactions[index]),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Terjadi kesalahan',
                      style: GoogleFonts.nunito(color: const Color(0xFF5C4A6E))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🌵', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('Belum ada transaksi',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF9B8AAE),
              )),
          const SizedBox(height: 8),
          Text('Yuk catat keuanganmu!',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: const Color(0xFFBBAACE),
              )),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(
      BuildContext context, WidgetRef ref, TransactionModel t) {
    final isExpense = t.type == TransactionType.expense;
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Dismissible(
      key: Key(t.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Text('🗑️', style: TextStyle(fontSize: 24)),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Hapus transaksi?',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
            content: Text('Transaksi ini akan dihapus permanen.',
                style: GoogleFonts.nunito()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Batal',
                    style: GoogleFonts.nunito(color: const Color(0xFF9B8AAE))),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Hapus',
                    style: GoogleFonts.nunito(color: Colors.white)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref
            .read(transactionNotifierProvider.notifier)
            .deleteTransaction(t.id!);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isExpense
                    ? const Color(0xFFFFD6E0)
                    : const Color(0xFFB8F0C8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  isExpense ? '💸' : '💰',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.title,
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF5C4A6E),
                      )),
                  if (t.note != null && t.note!.isNotEmpty)
                    Text(t.note!,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: const Color(0xFF9B8AAE),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  Text(dateFormat.format(t.date),
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        color: const Color(0xFFBBAACE),
                      )),
                ],
              ),
            ),
            Text(
              '${isExpense ? '-' : '+'}${currencyFormat.format(t.amount)}',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isExpense
                    ? const Color(0xFFFF8FAB)
                    : const Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

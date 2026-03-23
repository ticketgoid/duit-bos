import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';

enum HistoryType { all, expense, income }

const int _kPerPage = 10;

class HistoryScreen extends ConsumerStatefulWidget {
  final HistoryType type;
  const HistoryScreen({super.key, required this.type});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Color get _bgColor {
    switch (widget.type) {
      case HistoryType.all:     return const Color(0xFFF0E6FF);
      case HistoryType.expense: return const Color(0xFFFFD6E0);
      case HistoryType.income:  return const Color(0xFFB8F0C8);
    }
  }

  String get _title {
    switch (widget.type) {
      case HistoryType.all:     return '📋 Semua Riwayat';
      case HistoryType.expense: return '💸 Riwayat Pengeluaran';
      case HistoryType.income:  return '💰 Riwayat Pemasukan';
    }
  }

  Color get _accentColor {
    switch (widget.type) {
      case HistoryType.all:     return const Color(0xFF9B8AAE);
      case HistoryType.expense: return const Color(0xFFFF8FAB);
      case HistoryType.income:  return const Color(0xFF4CAF50);
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, TransactionModel t) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus transaksi?',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800,
                color: const Color(0xFF5C4A6E))),
        content: Text(
          'Transaksi ini akan dihapus permanen dan saldo wallet akan dikoreksi.',
          style: GoogleFonts.nunito(color: const Color(0xFF9B8AAE)),
        ),
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
                style: GoogleFonts.nunito(color: Colors.white,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref
          .read(transactionNotifierProvider.notifier)
          .deleteTransaction(t.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = switch (widget.type) {
      HistoryType.all     => ref.watch(allTransactionsProvider),
      HistoryType.expense => ref.watch(expenseTransactionsProvider),
      HistoryType.income  => ref.watch(incomeTransactionsProvider),
    };

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: transactionsAsync.when(
          data: (transactions) {
            // Hitung total halaman
            final totalPages = (transactions.length / _kPerPage).ceil();
            final pageCount = totalPages == 0 ? 1 : totalPages;

            // Jika currentPage melebihi total setelah delete, koreksi
            if (_currentPage >= pageCount && _currentPage > 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _currentPage = pageCount - 1);
              });
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_title,
                          style: GoogleFonts.nunito(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF5C4A6E),
                          )),
                      if (transactions.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${transactions.length} transaksi',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _accentColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── List (PageView horizontal) ─────────
                Expanded(
                  child: transactions.isEmpty
                      ? _buildEmpty()
                      : PageView.builder(
                    controller: _pageController,
                    itemCount: pageCount,
                    onPageChanged: (i) =>
                        setState(() => _currentPage = i),
                    itemBuilder: (context, pageIndex) {
                      final start = pageIndex * _kPerPage;
                      final end = (start + _kPerPage)
                          .clamp(0, transactions.length);
                      final pageItems =
                      transactions.sublist(start, end);

                      return ListView.builder(
                        // ✅ No scroll vertikal
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        itemCount: pageItems.length,
                        itemBuilder: (context, index) =>
                            _buildTransactionCard(
                                context, ref, pageItems[index]),
                      );
                    },
                  ),
                ),

                // ── Page Indicator ─────────────────────
                if (transactions.isNotEmpty && pageCount > 1)
                  _buildPageIndicator(pageCount),

                const SizedBox(height: 12),
              ],
            );
          },
          loading: () =>
          const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text('Terjadi kesalahan',
                style: GoogleFonts.nunito(
                    color: const Color(0xFF5C4A6E))),
          ),
        ),
      ),
    );
  }

  // ── Page Indicator dots + tombol prev/next ─────────────────
  Widget _buildPageIndicator(int pageCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Tombol prev
          GestureDetector(
            onTap: _currentPage > 0
                ? () {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
                : null,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _currentPage > 0
                    ? Colors.white
                    : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.chevron_left,
                  size: 18,
                  color: _currentPage > 0
                      ? _accentColor
                      : _accentColor.withOpacity(0.3)),
            ),
          ),

          const SizedBox(width: 8),

          // Dots
          ...List.generate(pageCount, (i) {
            final isActive = i == _currentPage;
            return GestureDetector(
              onTap: () {
                _pageController.animateToPage(i,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? _accentColor
                      : _accentColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),

          const SizedBox(width: 8),

          // Tombol next
          GestureDetector(
            onTap: _currentPage < pageCount - 1
                ? () {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
                : null,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _currentPage < pageCount - 1
                    ? Colors.white
                    : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.chevron_right,
                  size: 18,
                  color: _currentPage < pageCount - 1
                      ? _accentColor
                      : _accentColor.withOpacity(0.3)),
            ),
          ),

          const SizedBox(width: 12),

          // Label halaman
          Text(
            'Hal ${_currentPage + 1} / $pageCount',
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _accentColor,
            ),
          ),
        ],
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

  // ✅ Long press → popup konfirmasi hapus (ganti swipe)
  Widget _buildTransactionCard(
      BuildContext context, WidgetRef ref, TransactionModel t) {
    final isExpense = t.type == TransactionType.expense;
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return GestureDetector(
      onLongPress: () => _confirmDelete(context, ref, t),
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
                child: Text(isExpense ? '💸' : '💰',
                    style: const TextStyle(fontSize: 22)),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
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
                const SizedBox(height: 4),
                Text('hold to delete',
                    style: GoogleFonts.nunito(
                      fontSize: 9,
                      color: const Color(0xFFCCBBDD),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

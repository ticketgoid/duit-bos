import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0E6FF),
      body: SafeArea(
        child: PageView(
          scrollDirection: Axis.vertical,
          physics: const BouncingScrollPhysics(),
          children: [
            _DashboardPage(),
            const HistoryScreen(type: HistoryType.all),
          ],
        ),
      ),
    );
  }
}

class _DashboardPage extends ConsumerWidget {
  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalIncomeAsync = ref.watch(totalIncomeProvider);
    final totalExpenseAsync = ref.watch(totalExpenseProvider);
    final walletsAsync = ref.watch(allWalletsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Greeting ──────────────────────────────
          Text('Halo, Bos! 👋',
              style: GoogleFonts.nunito(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF5C4A6E),
              )),
          Text('Yuk cek keuanganmu hari ini',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: const Color(0xFF9B8AAE),
              )),

          const SizedBox(height: 24),

          // ── Balance Card ───────────────────────────
          _buildBalanceCard(totalIncomeAsync, totalExpenseAsync),

          const SizedBox(height: 20),

          // ── Ringkasan Pemasukan & Pengeluaran ──────
          Row(children: [
            Expanded(
                child: _buildSummaryCard(
                  '💰 Pemasukan',
                  totalIncomeAsync,
                  const Color(0xFF4CAF50),
                  const Color(0xFFB8F0C8),
                )),
            const SizedBox(width: 12),
            Expanded(
                child: _buildSummaryCard(
                  '💸 Pengeluaran',
                  totalExpenseAsync,
                  const Color(0xFFFF8FAB),
                  const Color(0xFFFFD6E0),
                )),
          ]),

          const SizedBox(height: 20),

          // ── Daftar Wallet ──────────────────────────
          Text('Dompetku 👜',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF5C4A6E),
              )),
          const SizedBox(height: 10),
          walletsAsync.when(
            data: (wallets) => Column(
              children: wallets
                  .map((w) => _buildWalletCard(w.emoji, w.name, w.balance))
                  .toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const SizedBox(),
          ),

          const SizedBox(height: 28),

          // ── Hint swipe ─────────────────────────────
          Center(
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '👆  swipe atas untuk semua riwayat',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF9B8AAE),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(totalIncomeAsync, totalExpenseAsync) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9B8AAE), Color(0xFF5C4A6E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C4A6E).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Saldo',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              )),
          const SizedBox(height: 8),
          totalIncomeAsync.when(
            data: (income) => totalExpenseAsync.when(
              data: (expense) {
                final balance = income - expense;
                return Text(
                  NumberFormat.currency(
                    locale: 'id_ID',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  ).format(balance),
                  style: GoogleFonts.nunito(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                );
              },
              loading: () => const CircularProgressIndicator(color: Colors.white),
              error: (e, _) => const SizedBox(),
            ),
            loading: () =>
            const CircularProgressIndicator(color: Colors.white),
            error: (e, _) => const SizedBox(),
          ),
          const SizedBox(height: 4),
          Text('Pemasukan − Pengeluaran',
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
              )),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String label, AsyncValue<double> asyncVal, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF5C4A6E),
              )),
          const SizedBox(height: 6),
          asyncVal.when(
            data: (val) => Text(
              NumberFormat.currency(
                locale: 'id_ID',
                symbol: 'Rp ',
                decimalDigits: 0,
              ).format(val),
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            loading: () => const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2)),
            error: (e, _) => const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(String emoji, String name, double balance) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(name,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5C4A6E),
                )),
          ),
          Text(
            NumberFormat.currency(
              locale: 'id_ID',
              symbol: 'Rp ',
              decimalDigits: 0,
            ).format(balance),
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF9B8AAE),
            ),
          ),
        ],
      ),
    );
  }
}

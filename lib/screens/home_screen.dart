import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/preferences_provider.dart';
import 'history_screen.dart';
import 'expense_screen.dart';
import 'income_screen.dart';
import 'wallet_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ✅ PageController di-dispose dengan benar
  late final PageController _verticalController;

  @override
  void initState() {
    super.initState();
    _verticalController = PageController(initialPage: 1);
  }

  @override
  void dispose() {
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _verticalController,
      scrollDirection: Axis.vertical,
      physics: const BouncingScrollPhysics(),
      children: [
        // index 0 — swipe dari atas ke bawah = Dompet
        const WalletScreen(),

        // index 1 — default = Horizontal (Expense | Dashboard | Income)
        _HorizontalRoot(),

        // index 2 — swipe dari bawah ke atas = Riwayat Semua
        const HistoryScreen(type: HistoryType.all),
      ],
    );
  }
}

class _HorizontalRoot extends StatefulWidget {
  @override
  State<_HorizontalRoot> createState() => _HorizontalRootState();
}

class _HorizontalRootState extends State<_HorizontalRoot> {
  // ✅ PageController di-dispose dengan benar
  late final PageController _horizontalController;

  @override
  void initState() {
    super.initState();
    _horizontalController = PageController(initialPage: 1);
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _horizontalController,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      children: [
        const IncomeScreen(),    // index 0 — swipe kanan ke kiri
        const _DashboardPage(),  // index 1 — default
        const ExpenseScreen(),   // index 2 — swipe kiri ke kanan
      ],
    );
  }
}

class _DashboardPage extends ConsumerWidget {
  const _DashboardPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalIncomeAsync = ref.watch(totalIncomeProvider);
    final totalExpenseAsync = ref.watch(totalExpenseProvider);
    final userNameAsync = ref.watch(userNameProvider);

    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF0E6FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Greeting + tombol Settings ──────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      userNameAsync.when(
                        data: (name) => Text('Halo, $name! 👋',
                            style: GoogleFonts.nunito(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF5C4A6E),
                            )),
                        loading: () => Text('Halo! 👋',
                            style: GoogleFonts.nunito(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF5C4A6E),
                            )),
                        error: (e, _) => Text('Halo, Bos! 👋',
                            style: GoogleFonts.nunito(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF5C4A6E),
                            )),
                      ),
                      Text('Yuk cek keuanganmu hari ini',
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: const Color(0xFF9B8AAE),
                          )),
                    ],
                  ),

                  // ✅ Tombol Settings
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text('⚙️',
                          style: TextStyle(fontSize: 22)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Balance Card ─────────────────────────
              _buildBalanceCard(totalIncomeAsync, totalExpenseAsync, fmt),

              const SizedBox(height: 20),

              // ── Ringkasan ────────────────────────────
              Row(children: [
                Expanded(
                    child: _buildSummaryCard(
                      '💰 Pemasukan',
                      totalIncomeAsync,
                      const Color(0xFF4CAF50),
                      const Color(0xFFB8F0C8),
                      fmt,
                    )),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildSummaryCard(
                      '💸 Pengeluaran',
                      totalExpenseAsync,
                      const Color(0xFFFF8FAB),
                      const Color(0xFFFFD6E0),
                      fmt,
                    )),
              ]),

              const SizedBox(height: 40),

              // ── Hint navigasi ────────────────────────
              _buildHints(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHints() {
    final hints = [
      ('👇', 'Tarik ke bawah', '👜 Dompet'),
      ('👆', 'Tarik ke atas', '📋 Riwayat Semua'),
      ('👈', 'Geser ke kiri', '💰 Pemasukan'),
      ('👉', 'Geser ke kanan', '💸 Pengeluaran'),
    ];
    return Column(
      children: hints.map((h) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            Text(h.$1, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(h.$2,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5C4A6E),
                  )),
            ),
            Text(h.$3,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: const Color(0xFF9B8AAE),
                )),
          ]),
        );
      }).toList(),
    );
  }

  Widget _buildBalanceCard(
      AsyncValue<double> totalIncomeAsync,
      AsyncValue<double> totalExpenseAsync,
      NumberFormat fmt,
      ) {
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
              data: (expense) => Text(
                fmt.format(income - expense),
                style: GoogleFonts.nunito(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              loading: () =>
              const CircularProgressIndicator(color: Colors.white),
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
      String label,
      AsyncValue<double> asyncVal,
      Color textColor,
      Color bgColor,
      NumberFormat fmt,
      ) {
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
              fmt.format(val),
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
}

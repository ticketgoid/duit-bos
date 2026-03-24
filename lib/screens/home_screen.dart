import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/preferences_provider.dart';
import '../providers/note_provider.dart';
import '../models/note_model.dart';
import 'history_screen.dart';
import 'expense_screen.dart';
import 'income_screen.dart';
import 'wallet_screen.dart';
import 'settings_screen.dart';
import 'notes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PageController _verticalController;

  // ✅ FIX Bug 1: track apakah vertical scroll luar di-enable
  bool _verticalEnabled = true;

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

  // ✅ FIX Bug 1: callback dari _HorizontalRoot
  void _onHorizontalPageChanged(int index) {
    // index 1 = Dashboard → enable vertical scroll
    // index 0 = Income, index 2 = Expense → disable vertical scroll
    setState(() {
      _verticalEnabled = index == 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _verticalController,
      scrollDirection: Axis.vertical,
      // ✅ FIX Bug 1: disable physics saat di Income/Expense
      physics: _verticalEnabled
          ? const BouncingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      children: [
        const WalletScreen(),
        _HorizontalRoot(onPageChanged: _onHorizontalPageChanged),
        const HistoryScreen(type: HistoryType.all),
      ],
    );
  }
}

class _HorizontalRoot extends StatefulWidget {
  // ✅ FIX Bug 1: terima callback dari HomeScreen
  final void Function(int index) onPageChanged;

  const _HorizontalRoot({required this.onPageChanged});

  @override
  State<_HorizontalRoot> createState() => _HorizontalRootState();
}

class _HorizontalRootState extends State<_HorizontalRoot> {
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
      // ✅ FIX Bug 1: kirim index ke HomeScreen saat halaman berubah
      onPageChanged: widget.onPageChanged,
      children: [
        const IncomeScreen(),
        const _DashboardPage(),
        const ExpenseScreen(),
      ],
    );
  }
}

// ─── Dashboard Page ───────────────────────────────────────────

class _DashboardPage extends ConsumerStatefulWidget {
  const _DashboardPage();

  @override
  ConsumerState<_DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<_DashboardPage> {

  Future<void> _openNotes() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const NotesScreen()),
    );
    if (!mounted) return;
    if (result != null && result['payNow'] == true) {
      final note = result['note'] as NoteModel;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExpenseScreen(
            prefillTitle: note.title,
            prefillAmount: note.amount,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
              // ── Header ──────────────────────────────────────
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

              // ── Balance Card (tidak diubah) ──────────────────
              _buildBalanceCard(totalIncomeAsync, totalExpenseAsync, fmt),

              const SizedBox(height: 20),

              // ── Summary Cards (tidak diubah) ─────────────────
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

              const SizedBox(height: 24),

              // ── Tombol Catatan Keuangan ───────────────────────
              _buildMenuButton(
                context,
                emoji: '📝',
                title: 'Catatan Keuangan',
                subtitle: 'Pengingat tagihan & rencana keuangan',
                color: const Color(0xFFEDE0FF),
                onTap: _openNotes,
              ),

              const SizedBox(height: 20),

              // ── Section Catatan Pinned di Dashboard ──────────
              const _NotesDashboardSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
      BuildContext context, {
        required String emoji,
        required String title,
        required String subtitle,
        required Color color,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF5C4A6E),
                    )),
                Text(subtitle,
                    style: GoogleFonts.nunito(
                        fontSize: 12, color: const Color(0xFF9B8AAE))),
              ],
            ),
          ),
          const Icon(Icons.chevron_right,
              color: Color(0xFFCCBBDD), size: 22),
        ]),
      ),
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

// ─── Notes Dashboard Section ──────────────────────────────────

class _NotesDashboardSection extends ConsumerWidget {
  const _NotesDashboardSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(pinnedNotesProvider);
    final fmt = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return notesAsync.when(
      data: (notes) {
        if (notes.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('📌 Catatan Disorot',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF5C4A6E),
                  )),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotesScreen()),
                ),
                child: Text('Semua →',
                    style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF9B8AAE))),
              ),
            ]),
            const SizedBox(height: 10),
            ...notes.map((note) => _MiniNoteCard(note: note, fmt: fmt)),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ─── Mini Note Card (di dashboard) ───────────────────────────

class _MiniNoteCard extends StatelessWidget {
  final NoteModel note;
  final NumberFormat fmt;

  const _MiniNoteCard({required this.note, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final isOverdue = note.reminderDate != null &&
        note.reminderDate!.isBefore(DateTime.now()) &&
        !note.isChecked;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isOverdue
            ? Border.all(color: Colors.redAccent.withOpacity(0.4), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(children: [
        if (note.isPinned)
          const Padding(
            padding: EdgeInsets.only(right: 6),
            child: Text('📌', style: TextStyle(fontSize: 14)),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(note.title,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5C4A6E),
                    decoration:
                    note.isChecked ? TextDecoration.lineThrough : null,
                  )),
              const SizedBox(height: 2),
              Text(fmt.format(note.amount),
                  style: GoogleFonts.nunito(
                      fontSize: 12, color: const Color(0xFF9B8AAE))),
            ],
          ),
        ),
        if (note.reminderDate != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isOverdue
                  ? const Color(0xFFFFD6E0)
                  : const Color(0xFFF0E6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              DateFormat('d MMM', 'id_ID').format(note.reminderDate!),
              style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isOverdue
                      ? Colors.redAccent
                      : const Color(0xFF9B8AAE)),
            ),
          ),
      ]),
    );
  }
}
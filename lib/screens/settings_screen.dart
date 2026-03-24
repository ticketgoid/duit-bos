import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/category_model.dart';
import '../providers/preferences_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  bool _loaded = false;
  String _currentName = 'Bos';

  // Tab controller untuk kategori
  late TabController _categoryTabController;

  final List<Map<String, String>> _allWallets = [
    {'id': 'cash',    'name': 'Tunai',     'emoji': '💵'},
    {'id': 'bca',     'name': 'BCA',       'emoji': '🏦'},
    {'id': 'bri',     'name': 'BRI',       'emoji': '🏦'},
    {'id': 'bni',     'name': 'BNI',       'emoji': '🏦'},
    {'id': 'mandiri', 'name': 'Mandiri',   'emoji': '🏦'},
    {'id': 'seabank', 'name': 'SeaBank',   'emoji': '🌊'},
    {'id': 'jago',    'name': 'Bank Jago', 'emoji': '🐆'},
    {'id': 'gopay',   'name': 'GoPay',     'emoji': '🟢'},
    {'id': 'shopee',  'name': 'ShopeePay', 'emoji': '🟠'},
    {'id': 'ovo',     'name': 'OVO',       'emoji': '🟣'},
    {'id': 'dana',    'name': 'DANA',      'emoji': '🔵'},
  ];

  @override
  void initState() {
    super.initState();
    _categoryTabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSettings());
  }

  @override
  void dispose() {
    _categoryTabController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? 'Bos';
    if (mounted) setState(() { _currentName = name; _loaded = true; });
  }

  // ─── GANTI NAMA ──────────────────────────────────────────────

  void _showChangeNameSheet() {
    final ctrl = TextEditingController(text: _currentName);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BottomSheetWrapper(
        title: '👤 Ganti Nama',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _inputField(ctrl, 'Nama baru...'),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: _outlineBtn('Batal', () => Navigator.pop(ctx)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _solidBtn('Simpan', () async {
                  final name = ctrl.text.trim();
                  if (name.isEmpty) return;
                  Navigator.pop(ctx);
                  await ref
                      .read(preferencesNotifierProvider.notifier)
                      .updateUserName(name);
                  ref.invalidate(userNameProvider);
                  if (mounted) setState(() => _currentName = name);
                  _showSnack('Nama berhasil diubah ✅');
                }),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ─── KELOLA WALLET ───────────────────────────────────────────

  void _showWalletSheet() async {
    final wallets = await DatabaseHelper.instance.getAllWallets();
    final currentActive = wallets
        .where((w) => w.showInExpense || w.showInIncome)
        .map((w) => w.id)
        .toSet();

    if (!mounted) return;

    // state lokal bottom sheet
    final selected = Set<String>.from(currentActive);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return _BottomSheetWrapper(
            title: '👜 Pilih Wallet Aktif',
            subtitle: 'Maks. 6 wallet • Tap untuk aktifkan/nonaktifkan',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Grid wallet
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _allWallets.length,
                  itemBuilder: (_, i) {
                    final w = _allWallets[i];
                    final isActive = selected.contains(w['id']);
                    return GestureDetector(
                      onTap: () async {
                        if (isActive) {
                          // Sudah aktif → tanya hapus atau sembunyikan
                          if (selected.length <= 1) {
                            _showSnack('Minimal 1 wallet harus aktif!');
                            return;
                          }
                          final action =
                          await _showDeactivateChoice(ctx, w);
                          if (action == null) return;

                          if (action == 'delete') {
                            await DatabaseHelper.instance
                                .deleteWalletData(w['id']!);
                          }
                          await DatabaseHelper.instance
                              .updateWalletVisibility(
                            w['id']!,
                            showInExpense: false,
                            showInIncome: false,
                          );
                          setSheetState(() => selected.remove(w['id']));
                          _invalidateAll();
                        } else {
                          // Belum aktif → aktifkan (max 6)
                          if (selected.length >= 6) {
                            _showSnack('Maksimal 6 wallet aktif!');
                            return;
                          }
                          await DatabaseHelper.instance
                              .updateWalletVisibility(
                            w['id']!,
                            showInExpense: true,
                            showInIncome: true,
                          );
                          setSheetState(() => selected.add(w['id']!));
                          _invalidateAll();
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF5C4A6E)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isActive
                                ? const Color(0xFF5C4A6E)
                                : const Color(0xFFE0D0F0),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(w['emoji']!,
                                style: const TextStyle(fontSize: 24)),
                            const SizedBox(height: 4),
                            Text(w['name']!,
                                style: GoogleFonts.nunito(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isActive
                                      ? Colors.white
                                      : const Color(0xFF5C4A6E),
                                ),
                                textAlign: TextAlign.center),
                            if (isActive)
                              Text('✓',
                                  style: GoogleFonts.nunito(
                                      fontSize: 10,
                                      color: Colors.white70)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Badge jumlah aktif
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected.length == 6
                          ? const Color(0xFFFFD6E0)
                          : const Color(0xFFB8F0C8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${selected.length}/6 wallet aktif',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: selected.length == 6
                            ? const Color(0xFFFF8FAB)
                            : const Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _solidBtn('Selesai', () => Navigator.pop(ctx)),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<String?> _showDeactivateChoice(
      BuildContext ctx, Map<String, String> wallet) {
    return showDialog<String>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Nonaktifkan ${wallet['emoji']} ${wallet['name']}?',
          style: GoogleFonts.nunito(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF5C4A6E)),
        ),
        content: Text(
          'Pilih apa yang ingin dilakukan dengan data wallet ini:',
          style:
          GoogleFonts.nunito(fontSize: 13, color: const Color(0xFF9B8AAE)),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Opsi 1: Hapus data
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(dCtx, 'delete'),
                icon: const Text('🗑️'),
                label: Text('Hapus semua data wallet ini',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 8),
              // Opsi 2: Sembunyikan saja
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(dCtx, 'hide'),
                icon: const Text('👁️'),
                label: Text('Sembunyikan saja, data tetap aman',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C4A6E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 8),
              // Batal
              TextButton(
                onPressed: () => Navigator.pop(dCtx, null),
                child: Text('Batal',
                    style: GoogleFonts.nunito(
                        color: const Color(0xFF9B8AAE))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── KELOLA KATEGORI ─────────────────────────────────────────

  void _showAddCategorySheet(String type) {
    final nameCtrl = TextEditingController();
    final emojiCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BottomSheetWrapper(
        title: type == 'expense'
            ? '➕ Kategori Pengeluaran Baru'
            : '➕ Kategori Pemasukan Baru',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              SizedBox(
                width: 64,
                child: _inputField(emojiCtrl, '😊', maxLength: 2),
              ),
              const SizedBox(width: 12),
              Expanded(child: _inputField(nameCtrl, 'Nama kategori...')),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: _outlineBtn('Batal', () => Navigator.pop(ctx))),
              const SizedBox(width: 12),
              Expanded(
                child: _solidBtn('Tambah', () async {
                  final name = nameCtrl.text.trim();
                  final emoji =
                  emojiCtrl.text.trim().isEmpty ? '📌' : emojiCtrl.text.trim();
                  if (name.isEmpty) return;
                  final newCat = CategoryModel(
                    id: const Uuid().v4(),
                    name: name,
                    emoji: emoji,
                    type: type == 'expense'
                        ? CategoryType.expense
                        : CategoryType.income,
                  );
                  await ref
                      .read(categoryNotifierProvider.notifier)
                      .addCategory(newCat);
                  if (mounted) Navigator.pop(ctx);
                  _showSnack('Kategori ditambahkan ✅');
                }),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  void _showEditCategorySheet(CategoryModel cat) {
    final nameCtrl = TextEditingController(text: cat.name);
    final emojiCtrl = TextEditingController(text: cat.emoji);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BottomSheetWrapper(
        title: 'Edit Kategori',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              SizedBox(
                width: 64,
                child: _inputField(emojiCtrl, '😊', maxLength: 2),
              ),
              const SizedBox(width: 12),
              Expanded(child: _inputField(nameCtrl, 'Nama kategori...')),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: _outlineBtn('Batal', () => Navigator.pop(ctx))),
              const SizedBox(width: 12),
              Expanded(
                child: _solidBtn('Simpan', () async {
                  final name = nameCtrl.text.trim();
                  final emoji = emojiCtrl.text.trim().isEmpty
                      ? cat.emoji
                      : emojiCtrl.text.trim();
                  if (name.isEmpty) return;
                  await ref
                      .read(categoryNotifierProvider.notifier)
                      .updateCategory(CategoryModel(
                    id: cat.id,
                    name: name,
                    emoji: emoji,
                    type: cat.type,
                  ));
                  if (mounted) Navigator.pop(ctx);
                  _showSnack('Kategori diperbarui ✅');
                }),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteCategory(CategoryModel cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus kategori?',
            style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF5C4A6E))),
        content: Text(
          '${cat.emoji} ${cat.name} akan dihapus dari daftar pilihan.\n\n'
              'Transaksi lama yang memakai kategori ini tetap tersimpan di riwayat.',
          style: GoogleFonts.nunito(
              fontSize: 13, color: const Color(0xFF9B8AAE)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal',
                style:
                GoogleFonts.nunito(color: const Color(0xFF9B8AAE))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Hapus',
                style: GoogleFonts.nunito(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref
          .read(categoryNotifierProvider.notifier)
          .deleteCategory(cat.id);
      _showSnack('Kategori dihapus');
    }
  }

  // ─── DANGER ZONE ─────────────────────────────────────────────

  Future<void> _deleteAllTransactions() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus semua catatan?',
            style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF5C4A6E))),
        content: Text(
          'Seluruh riwayat pemasukan dan pengeluaran akan dihapus, '
              'dan saldo semua wallet akan kembali ke 0.\n\n'
              'Wallet dan kategori kamu tetap tersimpan.',
          style: GoogleFonts.nunito(
              fontSize: 13, color: const Color(0xFF9B8AAE)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal',
                style:
                GoogleFonts.nunito(color: const Color(0xFF9B8AAE))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Hapus Semua Catatan',
                style: GoogleFonts.nunito(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    for (final w in _allWallets) {
      await DatabaseHelper.instance.deleteWalletData(w['id']!);
    }
    _invalidateAll();
    _showSnack('Semua catatan keuangan dihapus ✅');
  }

  Future<void> _resetApp() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Mulai ulang aplikasi?',
            style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF5C4A6E))),
        content: Text(
          'Semua data kamu — catatan keuangan, saldo wallet, nama, '
              'dan pengaturan — akan dihapus permanen.\n\n'
              'Kamu akan diarahkan ke halaman pengaturan awal.',
          style: GoogleFonts.nunito(
              fontSize: 13, color: const Color(0xFF9B8AAE)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal',
                style:
                GoogleFonts.nunito(color: const Color(0xFF9B8AAE))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Mulai Ulang',
                style: GoogleFonts.nunito(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    for (final w in _allWallets) {
      await DatabaseHelper.instance.deleteWalletData(w['id']!);
      await DatabaseHelper.instance.updateWalletVisibility(w['id']!,
          showInExpense: false, showInIncome: false);
    }
    await ref
        .read(preferencesNotifierProvider.notifier)
        .resetOnboarding();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
            (_) => false,
      );
    }
  }

  // ─── HELPERS ─────────────────────────────────────────────────

  void _invalidateAll() {
    ref.invalidate(walletNotifierProvider);
    ref.invalidate(allWalletsProvider);
    ref.invalidate(expenseWalletProvider);
    ref.invalidate(incomeWalletProvider);
    ref.invalidate(allTransactionsProvider);
    ref.invalidate(expenseTransactionsProvider);
    ref.invalidate(incomeTransactionsProvider);
    ref.invalidate(totalIncomeProvider);
    ref.invalidate(totalExpenseProvider);
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.nunito()),
      backgroundColor:
      isError ? const Color(0xFFFF8FAB) : const Color(0xFF4CAF50),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ));
  }

  Widget _inputField(TextEditingController ctrl, String hint,
      {int? maxLength}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0E6FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: ctrl,
        maxLength: maxLength,
        style: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF5C4A6E)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.nunito(color: const Color(0xFFCCBBDD)),
          border: InputBorder.none,
          counterText: '',
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        textCapitalization: TextCapitalization.sentences,
      ),
    );
  }

  Widget _solidBtn(String label, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5C4A6E),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      child: Text(label,
          style: GoogleFonts.nunito(
              fontSize: 14, fontWeight: FontWeight.w700)),
    );
  }

  Widget _outlineBtn(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFF9B8AAE)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(label,
          style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF9B8AAE))),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
        style: GoogleFonts.nunito(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF5C4A6E),
        )),
  );

  Widget _settingsTile({
    required String emoji,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF5C4A6E))),
                Text(subtitle,
                    style: GoogleFonts.nunito(
                        fontSize: 12, color: const Color(0xFF9B8AAE))),
              ],
            ),
          ),
          const Icon(Icons.chevron_right,
              color: Color(0xFFCCBBDD), size: 20),
        ]),
      ),
    );
  }

  // ─── BUILD ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0E6FF),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 6)
                      ],
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        size: 16, color: Color(0xFF5C4A6E)),
                  ),
                ),
                const SizedBox(width: 12),
                Text('⚙️ Pengaturan',
                    style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF5C4A6E),
                    )),
              ]),
            ),

            const SizedBox(height: 24),

            Expanded(
              child: !_loaded
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                padding:
                const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Profil ──────────────────────────
                    _sectionLabel('👤 Profil'),
                    _settingsTile(
                      emoji: '✏️',
                      title: 'Ganti Nama',
                      subtitle: 'Nama sekarang: $_currentName',
                      onTap: _showChangeNameSheet,
                    ),

                    const SizedBox(height: 24),

                    // ── Wallet ──────────────────────────
                    _sectionLabel('👜 Dompet'),
                    _settingsTile(
                      emoji: '🔧',
                      title: 'Kelola Wallet',
                      subtitle:
                      'Pilih wallet yang ingin ditampilkan (maks. 6)',
                      onTap: _showWalletSheet,
                    ),

                    const SizedBox(height: 24),

                    // ── Kategori ─────────────────────────
                    _sectionLabel('🏷️ Kategori'),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: Column(
                        children: [
                          // TabBar
                          Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0E6FF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: TabBar(
                              controller: _categoryTabController,
                              indicator: BoxDecoration(
                                color: const Color(0xFF5C4A6E),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              indicatorSize: TabBarIndicatorSize.tab,  // ← tambah ini
                              dividerColor: Colors.transparent,
                              labelColor: Colors.white,
                              unselectedLabelColor: const Color(0xFF9B8AAE),
                              labelStyle: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700),
                              unselectedLabelStyle: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700),
                              padding: EdgeInsets.zero,               // ← tambah ini
                              tabs: const [
                                Tab(text: '💸 Pengeluaran'),
                                Tab(text: '💰 Pemasukan'),
                              ],
                            ),
                          ),

                          // Tab content
                          SizedBox(
                            height: 320,
                            child: categoriesAsync.when(
                              data: (allCats) {
                                return TabBarView(
                                  controller:
                                  _categoryTabController,
                                  children: [
                                    _buildCategoryList(
                                        allCats
                                            .where((c) =>
                                        c.type ==
                                            CategoryType.expense)
                                            .toList(),
                                        'expense'),
                                    _buildCategoryList(
                                        allCats
                                            .where((c) =>
                                        c.type ==
                                            CategoryType.income)
                                            .toList(),
                                        'income'),
                                  ],
                                );
                              },
                              loading: () => const Center(
                                  child: CircularProgressIndicator()),
                              error: (e, _) =>
                              const Center(child: Text('Error')),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Danger Zone ──────────────────────
                    _sectionLabel('⚠️ Zona Berbahaya'),
                    Text(
                      'Tindakan di bawah tidak dapat dibatalkan',
                      style: GoogleFonts.nunito(
                          fontSize: 11,
                          color: const Color(0xFF9B8AAE)),
                    ),
                    const SizedBox(height: 12),

                    // Hapus semua catatan
                    _dangerTile(
                      emoji: '🗑️',
                      title: 'Hapus semua catatan keuangan',
                      subtitle:
                      'Riwayat transaksi & saldo wallet dihapus. Wallet dan kategori tetap ada.',
                      onTap: _deleteAllTransactions,
                    ),

                    const SizedBox(height: 10),

                    // Reset total
                    _dangerTile(
                      emoji: '🔄',
                      title: 'Mulai ulang dari awal',
                      subtitle:
                      'Hapus semua data dan kembali ke pengaturan awal aplikasi.',
                      onTap: _resetApp,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList(List<CategoryModel> cats, String type) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      children: [
        ...cats.map((cat) => ListTile(
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          leading: Text(cat.emoji,
              style: const TextStyle(fontSize: 22)),
          title: Text(cat.name,
              style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5C4A6E))),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _showEditCategorySheet(cat),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0E6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit,
                      size: 16, color: Color(0xFF9B8AAE)),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _confirmDeleteCategory(cat),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD6E0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline,
                      size: 16, color: Colors.redAccent),
                ),
              ),
            ],
          ),
        )),
        // Tombol tambah kategori
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: TextButton.icon(
            onPressed: () => _showAddCategorySheet(type),
            icon: const Icon(Icons.add_circle_outline,
                size: 18, color: Color(0xFF9B8AAE)),
            label: Text('Tambah kategori baru',
                style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF9B8AAE))),
          ),
        ),
      ],
    );
  }

  Widget _dangerTile({
    required String emoji,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F0),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: Colors.redAccent.withOpacity(0.3), width: 1),
        ),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.redAccent)),
                Text(subtitle,
                    style: GoogleFonts.nunito(
                        fontSize: 11,
                        color: const Color(0xFF9B8AAE))),
              ],
            ),
          ),
          const Icon(Icons.chevron_right,
              color: Colors.redAccent, size: 20),
        ]),
      ),
    );
  }
}

// ─── Bottom Sheet Wrapper ─────────────────────────────────────

class _BottomSheetWrapper extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _BottomSheetWrapper({
    required this.title,
    required this.child,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0D0F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: GoogleFonts.nunito(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF5C4A6E),
              )),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!,
                style: GoogleFonts.nunito(
                    fontSize: 12, color: const Color(0xFF9B8AAE))),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

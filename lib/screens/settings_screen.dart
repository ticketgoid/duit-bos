import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database_helper.dart';
import '../providers/preferences_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/transaction_provider.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  bool _isSaving = false;

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

  Set<String> _activeWallets = {};
  Set<String> _originalActiveWallets = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentSettings() async {
    // Load nama user
    final prefs = ref.read(preferencesNotifierProvider);
    prefs.whenData((data) {
      _nameController.text = data['user_name'] ?? 'Bos';
    });

    // Load wallet aktif dari DB
    final wallets = await DatabaseHelper.instance.getAllWallets();
    final active = wallets
        .where((w) => w.showInExpense || w.showInIncome)
        .map((w) => w.id)
        .toSet();

    if (mounted) {
      setState(() {
        _activeWallets = Set.from(active);
        _originalActiveWallets = Set.from(active);
        _loaded = true;
      });
    }
  }

  void _toggleWallet(String id) {
    setState(() {
      if (_activeWallets.contains(id)) {
        if (_activeWallets.length > 1) {
          _activeWallets.remove(id);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Minimal 1 wallet harus aktif!',
                style: GoogleFonts.nunito()),
            backgroundColor: const Color(0xFFFF8FAB),
            behavior: SnackBarBehavior.floating,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ));
        }
      } else {
        if (_activeWallets.length < 6) {
          _activeWallets.add(id);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Maksimal 6 wallet aktif!',
                style: GoogleFonts.nunito()),
            backgroundColor: const Color(0xFFFF8FAB),
            behavior: SnackBarBehavior.floating,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ));
        }
      }
    });
  }

  Future<void> _saveSettings() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Nama tidak boleh kosong!', style: GoogleFonts.nunito()),
        backgroundColor: const Color(0xFFFF8FAB),
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ));
      return;
    }

    // Cek wallet yang dinonaktifkan (ada di original tapi tidak di active)
    final deactivated = _originalActiveWallets.difference(_activeWallets);

    // Jika ada wallet yang dinonaktifkan dan punya data, tampilkan konfirmasi
    if (deactivated.isNotEmpty) {
      final confirm = await _showDeactivateConfirm(deactivated);
      if (confirm != true) return;
    }

    setState(() => _isSaving = true);

    // Hapus data wallet yang dinonaktifkan
    for (final walletId in deactivated) {
      await DatabaseHelper.instance.deleteWalletData(walletId);
    }

    // Update visibility semua wallet
    for (final w in _allWallets) {
      final isActive = _activeWallets.contains(w['id']!);
      await DatabaseHelper.instance.updateWalletVisibility(
        w['id']!,
        showInExpense: isActive,
        showInIncome: isActive,
      );
    }

    // Update nama user
    await ref
        .read(preferencesNotifierProvider.notifier)
        .updateUserName(_nameController.text.trim());

    // Invalidate semua provider terkait
    ref.invalidate(walletNotifierProvider);
    ref.invalidate(allWalletsProvider);
    ref.invalidate(expenseWalletProvider);
    ref.invalidate(incomeWalletProvider);
    ref.invalidate(allTransactionsProvider);
    ref.invalidate(expenseTransactionsProvider);
    ref.invalidate(incomeTransactionsProvider);
    ref.invalidate(totalIncomeProvider);
    ref.invalidate(totalExpenseProvider);

    if (mounted) {
      setState(() {
        _isSaving = false;
        _originalActiveWallets = Set.from(_activeWallets);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
        Text('Pengaturan tersimpan! ✅', style: GoogleFonts.nunito()),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ));
      Navigator.pop(context);
    }
  }

  Future<bool?> _showDeactivateConfirm(Set<String> deactivated) {
    final names = _allWallets
        .where((w) => deactivated.contains(w['id']))
        .map((w) => '${w['emoji']} ${w['name']}')
        .join(', ');

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus data wallet?',
            style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF5C4A6E))),
        content: Text(
          'Wallet $names akan dinonaktifkan.\n\n'
              'Semua transaksi dan saldo wallet tersebut akan dihapus permanen. '
              'Tindakan ini tidak dapat dibatalkan.',
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
            child: Text('Hapus & Lanjutkan',
                style: GoogleFonts.nunito(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _resetApp() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Reset Aplikasi?',
            style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF5C4A6E))),
        content: Text(
          'Semua data transaksi, saldo, dan pengaturan akan dihapus permanen. '
              'Aplikasi akan kembali ke setup awal.',
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
            child: Text('Reset',
                style: GoogleFonts.nunito(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Hapus semua data
    for (final w in _allWallets) {
      await DatabaseHelper.instance.deleteWalletData(w['id']!);
      await DatabaseHelper.instance.updateWalletVisibility(
        w['id']!,
        showInExpense: false,
        showInIncome: false,
      );
    }

    // Reset onboarding
    await ref.read(preferencesNotifierProvider.notifier).resetOnboarding();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
            (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0E6FF),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────
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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Nama User ──────────────────────
                    _sectionLabel('👤 Nama Kamu'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: TextField(
                        controller: _nameController,
                        style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF5C4A6E)),
                        decoration: InputDecoration(
                          hintText: 'Nama kamu...',
                          hintStyle: GoogleFonts.nunito(
                              color: const Color(0xFFCCBBDD)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                        ),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) =>
                            FocusScope.of(context).unfocus(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Pilih Wallet Aktif ─────────────
                    Row(children: [
                      _sectionLabel('👜 Wallet Aktif'),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _activeWallets.length == 6
                              ? const Color(0xFFFF8FAB).withOpacity(0.2)
                              : const Color(0xFFB8F0C8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${_activeWallets.length}/6',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _activeWallets.length == 6
                                  ? const Color(0xFFFF8FAB)
                                  : const Color(0xFF4CAF50),
                            )),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      'Wallet dinonaktifkan akan menghapus semua datanya',
                      style: GoogleFonts.nunito(
                          fontSize: 11,
                          color: const Color(0xFF9B8AAE)),
                    ),
                    const SizedBox(height: 12),

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
                      itemBuilder: (context, index) {
                        final w = _allWallets[index];
                        final isActive =
                        _activeWallets.contains(w['id']);
                        return GestureDetector(
                          onTap: () => _toggleWallet(w['id']!),
                          child: AnimatedContainer(
                            duration:
                            const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFF5C4A6E)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2))
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                Text(w['emoji']!,
                                    style: const TextStyle(
                                        fontSize: 26)),
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

                    const SizedBox(height: 32),

                    // ── Tombol Simpan ──────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5C4A6E),
                          padding: const EdgeInsets.symmetric(
                              vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(20)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2))
                            : Text('Simpan Pengaturan ✅',
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            )),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Divider ────────────────────────
                    Divider(color: Colors.black.withOpacity(0.08)),

                    const SizedBox(height: 16),

                    // ── Danger Zone ────────────────────
                    _sectionLabel('⚠️ Danger Zone'),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _resetApp,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(20)),
                        ),
                        child: Text('Reset Semua Data 🗑️',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.redAccent,
                            )),
                      ),
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

  Widget _sectionLabel(String text) {
    return Text(text,
        style: GoogleFonts.nunito(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF5C4A6E),
        ));
  }
}

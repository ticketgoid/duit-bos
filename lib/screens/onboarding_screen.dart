import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database_helper.dart';
import '../providers/preferences_provider.dart';
import '../providers/wallet_provider.dart';
import 'home_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _pageController = PageController();

  // Daftar semua wallet tersedia
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

  final Set<String> _selectedWallets = {};
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _toggleWallet(String id) {
    setState(() {
      if (_selectedWallets.contains(id)) {
        _selectedWallets.remove(id);
      } else {
        if (_selectedWallets.length < 6) {
          _selectedWallets.add(id);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Maksimal 6 wallet aktif!',
                  style: GoogleFonts.nunito()),
              backgroundColor: const Color(0xFFFF8FAB),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          );
        }
      }
    });
  }

  Future<void> _finishOnboarding() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Masukkan namamu dulu!', style: GoogleFonts.nunito()),
          backgroundColor: const Color(0xFFFF8FAB),
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
      return;
    }
    if (_selectedWallets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pilih minimal 1 wallet!', style: GoogleFonts.nunito()),
          backgroundColor: const Color(0xFFFF8FAB),
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Set semua wallet nonaktif dulu, lalu aktifkan yang dipilih
    for (final w in _allWallets) {
      final isSelected = _selectedWallets.contains(w['id']!);
      await DatabaseHelper.instance.updateWalletVisibility(
        w['id']!,
        showInExpense: isSelected,
        showInIncome: isSelected,
      );
    }

    // Simpan nama & tandai onboarding selesai
    await ref
        .read(preferencesNotifierProvider.notifier)
        .completeOnboarding(_nameController.text.trim());

    // Refresh wallet provider
    ref.invalidate(walletNotifierProvider);
    ref.invalidate(allWalletsProvider);
    ref.invalidate(expenseWalletProvider);
    ref.invalidate(incomeWalletProvider);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0E6FF),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildWelcomePage(),
            _buildWalletPage(),
          ],
        ),
      ),
    );
  }

  // ── Halaman 1: Nama ──────────────────────────────────────────
  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👋', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 24),
          Text('Halo!',
              style: GoogleFonts.nunito(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF5C4A6E),
              )),
          const SizedBox(height: 8),
          Text('Siapa namamu?',
              style: GoogleFonts.nunito(
                fontSize: 18,
                color: const Color(0xFF9B8AAE),
              )),
          const SizedBox(height: 40),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _nameController,
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF5C4A6E),
              ),
              decoration: InputDecoration(
                hintText: 'Nama kamu...',
                hintStyle: GoogleFonts.nunito(color: const Color(0xFFCCBBDD)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 18),
              ),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Masukkan namamu dulu!',
                          style: GoogleFonts.nunito()),
                      backgroundColor: const Color(0xFFFF8FAB),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  );
                  return;
                }
                FocusScope.of(context).unfocus();
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C4A6E),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: Text('Lanjut →',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  )),
            ),
          ),
        ],
      ),
    );
  }

  // ── Halaman 2: Pilih Wallet ──────────────────────────────────
  Widget _buildWalletPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text('Pilih Walletmu 👜',
              style: GoogleFonts.nunito(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF5C4A6E),
              )),
          const SizedBox(height: 4),
          Text(
            'Pilih maksimal 6 wallet yang kamu gunakan',
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: const Color(0xFF9B8AAE),
            ),
          ),
          const SizedBox(height: 8),
          // Counter
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _selectedWallets.length == 6
                  ? const Color(0xFFFF8FAB).withOpacity(0.2)
                  : const Color(0xFFB8F0C8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_selectedWallets.length}/6 dipilih',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _selectedWallets.length == 6
                    ? const Color(0xFFFF8FAB)
                    : const Color(0xFF4CAF50),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Grid wallet
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _allWallets.length,
              itemBuilder: (context, index) {
                final w = _allWallets[index];
                final isSelected = _selectedWallets.contains(w['id']);
                return GestureDetector(
                  onTap: () => _toggleWallet(w['id']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF5C4A6E)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(w['emoji']!,
                            style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 6),
                        Text(w['name']!,
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF5C4A6E),
                            ),
                            textAlign: TextAlign.center),
                        if (isSelected)
                          const Text('✓',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            TextButton(
              onPressed: () => _pageController.previousPage(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              ),
              child: Text('← Kembali',
                  style: GoogleFonts.nunito(
                    color: const Color(0xFF9B8AAE),
                    fontWeight: FontWeight.w700,
                  )),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isSaving ? null : _finishOnboarding,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C4A6E),
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: _isSaving
                  ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : Text('Mulai! 🚀',
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  )),
            ),
          ]),
        ],
      ),
    );
  }
}

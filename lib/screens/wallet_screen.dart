import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/wallet_provider.dart';
import '../models/wallet_model.dart';
import '../utils/wallet_logo.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(allWalletsProvider);
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFE8D5F5),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(children: [
                const Text('👜', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 8),
                Text('Dompetku',
                    style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF5C4A6E),
                    )),
              ]),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Hanya wallet aktif yang ditampilkan',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: const Color(0xFF9B8AAE),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Total Saldo ──────────────────────────
            walletsAsync.when(
              data: (wallets) {
                final activeWallets = wallets
                    .where((w) => w.showInExpense || w.showInIncome)
                    .toList();
                final totalBalance =
                activeWallets.fold(0.0, (sum, w) => sum + w.balance);

                return Column(
                  children: [
                    // Total saldo card — tidak diubah
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9B8AAE), Color(0xFF5C4A6E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5C4A6E).withOpacity(0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Saldo',
                                  style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.8),
                                  )),
                              const SizedBox(height: 4),
                              Text(fmt.format(totalBalance),
                                  style: GoogleFonts.nunito(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  )),
                            ],
                          ),
                          Text('${activeWallets.length} wallet aktif',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.7),
                              )),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ✅ FIX Bug 4: 2 kolom, aspect ratio landscape, layout Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,      // ✅ 3 → 2 kolom
                          childAspectRatio: 1.35, // ✅ card lebih lebar
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                        itemCount: activeWallets.length.clamp(0, 6),
                        itemBuilder: (context, index) {
                          final w = activeWallets[index];
                          return _buildWalletCard(w, fmt);
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () =>
              const Center(child: CircularProgressIndicator()),
              error: (e, _) => const SizedBox(),
            ),

            const Spacer(),

            // ── Hint ────────────────────────────────
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '⚙️  atur wallet di Pengaturan',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF9B8AAE),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletCard(WalletModel w, NumberFormat fmt) {
    return Container(
      // ✅ FIX Bug 4: padding lebih besar, layout Row (emoji kiri, teks kanan)
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: walletLogo(w.id, size: 40),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(w.name,
                    style: GoogleFonts.nunito(
                      fontSize: 13, // ✅ 11 → 13
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF5C4A6E),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1),
                const SizedBox(height: 3),
                Text(
                  fmt.format(w.balance),
                  style: GoogleFonts.nunito(
                    fontSize: 12, // ✅ 10 → 12
                    fontWeight: FontWeight.w800,
                    color: w.balance >= 0
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFFF8FAB),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
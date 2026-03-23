import 'package:flutter/material.dart';
import 'expense_screen.dart';
import 'income_screen.dart';
import 'history_screen.dart';
import 'wallet_screen.dart';
import '../providers/wallet_provider.dart';
import '../providers/transaction_provider.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _verticalController = PageController(initialPage: 1);
  final PageController _horizontalController = PageController(initialPage: 1);
  bool _isOnHomePage = true;

  @override
  void initState() {
    super.initState();
    _horizontalController.addListener(() {
      final page = _horizontalController.page ?? 1;
      setState(() {
        _isOnHomePage = (page == 1.0);
      });
    });
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // Blokir scroll vertikal parent jika BUKAN di homepage
          if (!_isOnHomePage &&
              notification.depth == 0 &&
              notification is ScrollStartNotification) {
            return true;
          }
          return false;
        },
        child: PageView(
          controller: _verticalController,
          scrollDirection: Axis.vertical,
          physics: _isOnHomePage
              ? const BouncingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          children: [
            const WalletScreen(),
            PageView(
              controller: _horizontalController,
              physics: const BouncingScrollPhysics(),
              children: [
                const IncomeScreen(),
                _buildHomePage(),
                const ExpenseScreen(),
              ],
            ),
            const HistoryScreen(type: HistoryType.all),
          ],
        ),
      ),
    );
  }

  Widget _buildHomePage() {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F0),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const Text('🐱', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 12),
            Text('Duit Bos', style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 8),
            Text(
              'Kelola keuanganmu dengan gaya!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF9B8AAE),
              ),
            ),
            const Spacer(),
            _buildSwipeHint(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeHint() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          _hintRow('👆', 'Swipe atas', 'Semua riwayat'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _hintChip('👈 Pengeluaran'),
              _hintChip('Pemasukan 👉'),
            ],
          ),
          const SizedBox(height: 8),
          _hintRow('👇', 'Swipe bawah', 'Lihat dompet'),
        ],
      ),
    );
  }

  Widget _hintRow(String emoji, String label, String sub) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text('$label — $sub',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9B8AAE),
              )),
        ],
      ),
    );
  }

  Widget _hintChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9B8AAE),
          )),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';
import '../models/category_model.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/category_provider.dart';
import 'history_screen.dart';

class ExpenseScreen extends ConsumerStatefulWidget {
  const ExpenseScreen({super.key});

  @override
  ConsumerState<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends ConsumerState<ExpenseScreen>
    with SingleTickerProviderStateMixin {
  String _amount = '0';
  WalletModel? _selectedWallet;
  CategoryModel? _selectedCategory;
  final _noteController = TextEditingController();
  late AnimationController _hintController;
  late Animation<double> _hintAnimation;

  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _hintAnimation = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _hintController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    _hintController.dispose();
    super.dispose();
  }

  void _onNumpad(String value) {
    setState(() {
      if (value == 'DEL') {
        _amount = _amount.length > 1
            ? _amount.substring(0, _amount.length - 1)
            : '0';
      } else if (value == '000') {
        if (_amount != '0') _amount += '000';
      } else {
        if (_amount == '0') {
          _amount = value;
        } else {
          if (_amount.length < 12) _amount += value;
        }
      }
    });
  }

  String get _formattedAmount {
    final number = int.tryParse(_amount) ?? 0;
    return currencyFormat.format(number);
  }

  Future<void> _saveTransaction() async {
    if (_amount == '0' || _selectedWallet == null || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lengkapi nominal, wallet, dan kategori!',
              style: GoogleFonts.nunito()),
          backgroundColor: const Color(0xFFFF8FAB),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
      return;
    }
    final transaction = TransactionModel(
      title: _selectedCategory!.name,
      amount: double.parse(_amount),
      type: TransactionType.expense,
      categoryId: _selectedCategory!.id,
      walletId: _selectedWallet!.id,
      date: DateTime.now(),
      note: _noteController.text.isEmpty ? null : _noteController.text,
    );
    await ref.read(transactionNotifierProvider.notifier).addTransaction(transaction);
    setState(() {
      _amount = '0';
      _selectedCategory = null;
      _noteController.clear();
    });
    if (mounted) {
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pengeluaran tersimpan! 💸', style: GoogleFonts.nunito()),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      scrollDirection: Axis.vertical,
      physics: const BouncingScrollPhysics(),
      children: [
        _buildExpensePage(),
        const HistoryScreen(type: HistoryType.expense),
      ],
    );
  }

  Widget _buildExpensePage() {
    final walletsAsync = ref.watch(expenseWalletProvider);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFD6E0),
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  MediaQuery.of(context).viewInsets.bottom,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      children: [
                        const Text('💸', style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 8),
                        Text('Pengeluaran',
                            style: GoogleFonts.nunito(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF5C4A6E),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      children: [
                        Text(_formattedAmount,
                            style: GoogleFonts.nunito(fontSize: 34, fontWeight: FontWeight.w800, color: const Color(0xFFFF8FAB))),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _noteController,
                          style: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFF5C4A6E)),
                          decoration: InputDecoration(
                            hintText: 'Catatan (opsional)...',
                            hintStyle: GoogleFonts.nunito(color: const Color(0xFFCCBBDD)),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          textAlign: TextAlign.center,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => FocusScope.of(context).unfocus(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.only(left: 24, bottom: 8),
                    child: Text('Keluar uang pake apa? 💳',
                        style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF5C4A6E))),
                  ),
                  walletsAsync.when(
                    data: (wallets) => SizedBox(
                      height: 42,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: wallets.length,
                        itemBuilder: (context, index) {
                          final wallet = wallets[index];
                          final isSelected = _selectedWallet?.id == wallet.id;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedWallet = wallet),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFFF8FAB) : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
                              ),
                              child: Row(children: [
                                Text(wallet.emoji, style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 5),
                                Text(wallet.name, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : const Color(0xFF5C4A6E))),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
                    loading: () => const SizedBox(height: 42),
                    error: (e, _) => const SizedBox(height: 42),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.only(left: 24, bottom: 8),
                    child: Text('Buat apa? 🤔',
                        style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF5C4A6E))),
                  ),
                  _buildCategoryPicker(),
                  const Spacer(),
                  _buildNumpad(),
                  const SizedBox(height: 16),
                  Center(
                    child: AnimatedBuilder(
                      animation: _hintAnimation,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, _hintAnimation.value),
                        child: child,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('👆  swipe atas untuk riwayat pengeluaran',
                            style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF9B8AAE))),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildCategoryPicker() {
    final categoriesAsync = ref.watch(categoryProvider('expense'));
    return categoriesAsync.when(
      data: (categories) => SizedBox(
        height: 42,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            final isSelected = _selectedCategory?.id == cat.id;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF5C4A6E)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Text(cat.emoji,
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 5),
                    Text(cat.name,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF5C4A6E),
                        )),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      loading: () => const SizedBox(height: 42),
      error: (e, _) => const SizedBox(height: 42),
    );
  }

  Widget _buildNumpad() {
    final buttons = ['7','8','9','4','5','6','1','2','3','000','0','DEL'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C4A6E),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: Text('Simpan Pengeluaran 💸',
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  )),
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.6,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: buttons.length,
            itemBuilder: (context, index) {
              final btn = buttons[index];
              final isDel = btn == 'DEL';
              return GestureDetector(
                onTap: () => _onNumpad(btn),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDel
                        ? const Color(0xFFFF8FAB).withOpacity(0.3)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      isDel ? '⌫' : btn,
                      style: GoogleFonts.nunito(
                        fontSize: isDel ? 20 : 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF5C4A6E),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';
import '../models/category_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('duit_bos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 2, // ← naik dari 1 ke 2
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Reset semua wallet ke nonaktif — biarkan onboarding yang atur
          await db.execute(
              'UPDATE wallets SET showInExpense = 0, showInIncome = 0');
        }
      },
    );
  }


  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        categoryId TEXT NOT NULL,
        walletId TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE wallets (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        emoji TEXT NOT NULL,
        balance REAL NOT NULL,
        showInExpense INTEGER NOT NULL DEFAULT 1,
        showInIncome INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        emoji TEXT NOT NULL,
        type TEXT NOT NULL
      )
    ''');

    await _insertDefaultWallets(db);
    await _insertDefaultCategories(db);
  }

  Future _insertDefaultWallets(Database db) async {
    final wallets = [
      {'id': 'cash', 'name': 'Tunai', 'emoji': '💵', 'balance': 0.0, 'showInExpense': 0, 'showInIncome': 0},
      {'id': 'bca', 'name': 'BCA', 'emoji': '🏦', 'balance': 0.0, 'showInExpense': 0, 'showInIncome': 0},
      {'id': 'bri', 'name': 'BRI', 'emoji': '🏦', 'balance': 0.0, 'showInExpense': 0, 'showInIncome': 0},
      {'id': 'bni', 'name': 'BNI', 'emoji': '🏦', 'balance': 0.0, 'showInExpense': 0, 'showInIncome': 0},
      {'id': 'mandiri', 'name': 'Mandiri', 'emoji': '🏦', 'balance': 0.0, 'showInExpense': 0, 'showInIncome': 0},
      {'id': 'seabank', 'name': 'SeaBank', 'emoji': '🌊', 'balance': 0.0, 'showInExpense': 0, 'showInIncome': 0},
      {'id': 'jago', 'name': 'Bank Jago', 'emoji': '🐆', 'balance': 0.0, 'showInExpense': 0, 'showInIncome': 0},
      {'id': 'gopay', 'name': 'GoPay', 'emoji': '🟢', 'balance': 0.0, 'showInExpense': 0, 'showInIncome': 0},
      {'id': 'shopee', 'name': 'ShopeePay', 'emoji': '🟠', 'balance': 0.0, 'showInExpense': 0, 'showInIncome': 0},
      {'id': 'ovo', 'name': 'OVO', 'emoji': '🟣', 'balance': 0.0, 'showInExpense': 0, 'showInIncome': 0},
      {'id': 'dana', 'name': 'DANA', 'emoji': '🔵', 'balance': 0.0, 'showInExpense': 0, 'showInIncome': 0},
    ];
    for (final w in wallets) {
      await db.insert('wallets', w);
    }
  }

  Future _insertDefaultCategories(Database db) async {
    final categories = [
      {'id': 'food', 'name': 'Makan & Minum', 'emoji': '🍜', 'type': 'expense'},
      {'id': 'transport', 'name': 'Transportasi', 'emoji': '🚗', 'type': 'expense'},
      {'id': 'shopping', 'name': 'Belanja', 'emoji': '🛍️', 'type': 'expense'},
      {'id': 'health', 'name': 'Kesehatan', 'emoji': '💊', 'type': 'expense'},
      {'id': 'entertainment', 'name': 'Hiburan', 'emoji': '🎮', 'type': 'expense'},
      {'id': 'bills', 'name': 'Tagihan', 'emoji': '📱', 'type': 'expense'},
      {'id': 'education', 'name': 'Pendidikan', 'emoji': '📚', 'type': 'expense'},
      {'id': 'salary', 'name': 'Gaji', 'emoji': '💼', 'type': 'income'},
      {'id': 'freelance', 'name': 'Freelance', 'emoji': '💻', 'type': 'income'},
      {'id': 'business', 'name': 'Bisnis', 'emoji': '🏪', 'type': 'income'},
      {'id': 'gift', 'name': 'Hadiah', 'emoji': '🎁', 'type': 'income'},
      {'id': 'investment', 'name': 'Investasi', 'emoji': '📈', 'type': 'income'},
    ];
    for (final c in categories) {
      await db.insert('categories', c);
    }
  }

  // ─── TRANSACTIONS ────────────────────────────────────────────

  Future<int> insertTransaction(TransactionModel t) async {
    final db = await database;
    final id = await db.insert('transactions', t.toMap());
    // Update saldo wallet
    final wallet = await getWalletById(t.walletId);
    if (wallet != null) {
      final newBalance = t.type == TransactionType.income
          ? wallet.balance + t.amount
          : wallet.balance - t.amount;
      await updateWalletBalance(t.walletId, newBalance);
    }
    return id;
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await database;
    final maps = await db.query('transactions', orderBy: 'date DESC');
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  Future<List<TransactionModel>> getTransactionsByType(TransactionType type) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'type = ?',
      whereArgs: [type.name],
      orderBy: 'date DESC',
    );
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  /// ✅ FIX: Rollback saldo wallet sebelum hapus transaksi
  Future<int> deleteTransaction(int id) async {
    final db = await database;

    // Ambil data transaksi sebelum dihapus
    final maps = await db.query('transactions', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      final transaction = TransactionModel.fromMap(maps.first);
      final wallet = await getWalletById(transaction.walletId);
      if (wallet != null) {
        // Rollback: balik arah operasi saldo
        final restoredBalance = transaction.type == TransactionType.income
            ? wallet.balance - transaction.amount  // income dihapus → kurangi saldo
            : wallet.balance + transaction.amount; // expense dihapus → tambah saldo
        await updateWalletBalance(transaction.walletId, restoredBalance);
      }
    }

    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // ─── WALLETS ─────────────────────────────────────────────────

  Future<List<WalletModel>> getAllWallets() async {
    final db = await database;
    final maps = await db.query('wallets');
    return maps.map((m) => WalletModel.fromMap(m)).toList();
  }

  Future<WalletModel?> getWalletById(String id) async {
    final db = await database;
    final maps = await db.query('wallets', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return WalletModel.fromMap(maps.first);
  }

  Future<List<WalletModel>> getWalletsForExpense() async {
    final db = await database;
    final maps = await db.query(
      'wallets',
      where: 'showInExpense = ?',
      whereArgs: [1],
      limit: 6, // ✅ max 6 wallet aktif
    );
    return maps.map((m) => WalletModel.fromMap(m)).toList();
  }

  Future<List<WalletModel>> getWalletsForIncome() async {
    final db = await database;
    final maps = await db.query(
      'wallets',
      where: 'showInIncome = ?',
      whereArgs: [1],
      limit: 6, // ✅ max 6 wallet aktif
    );
    return maps.map((m) => WalletModel.fromMap(m)).toList();
  }

  Future updateWalletBalance(String id, double balance) async {
    final db = await database;
    await db.update(
      'wallets',
      {'balance': balance},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future updateWalletVisibility(String id,
      {bool? showInExpense, bool? showInIncome}) async {
    final db = await database;
    final updates = <String, dynamic>{};
    if (showInExpense != null) updates['showInExpense'] = showInExpense ? 1 : 0;
    if (showInIncome != null) updates['showInIncome'] = showInIncome ? 1 : 0;
    await db.update('wallets', updates, where: 'id = ?', whereArgs: [id]);
  }

  /// Hapus semua transaksi milik wallet tertentu + reset saldo
  Future deleteWalletData(String walletId) async {
    final db = await database;
    await db.delete('transactions', where: 'walletId = ?', whereArgs: [walletId]);
    await updateWalletBalance(walletId, 0.0);
  }

  // ─── CATEGORIES ──────────────────────────────────────────────

  Future<List<CategoryModel>> getAllCategories() async {
    final db = await database;
    final maps = await db.query('categories');
    return maps.map((m) => CategoryModel.fromMap(m)).toList();
  }

  Future<List<CategoryModel>> getCategoriesByType(String type) async {
    final db = await database;
    final maps = await db.query(
      'categories',
      where: 'type = ? OR type = ?',
      whereArgs: [type, 'both'],
    );
    return maps.map((m) => CategoryModel.fromMap(m)).toList();
  }

  Future<int> insertCategory(CategoryModel c) async {
    final db = await database;
    return await db.insert('categories', c.toMap());
  }

  Future<int> deleteCategory(String id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ─── SUMMARY ─────────────────────────────────────────────────

  Future<double> getTotalBalance() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT SUM(balance) as total FROM wallets WHERE showInExpense = 1 OR showInIncome = 1');
    return (result.first['total'] as double?) ?? 0.0;
  }

  Future<double> getTotalByType(TransactionType type,
      {DateTime? from, DateTime? to}) async {
    final db = await database;
    String query =
        'SELECT SUM(amount) as total FROM transactions WHERE type = ?';
    List<dynamic> args = [type.name];
    if (from != null) {
      query += ' AND date >= ?';
      args.add(from.toIso8601String());
    }
    if (to != null) {
      query += ' AND date <= ?';
      args.add(to.toIso8601String());
    }
    final result = await db.rawQuery(query, args);
    return (result.first['total'] as double?) ?? 0.0;
  }
}

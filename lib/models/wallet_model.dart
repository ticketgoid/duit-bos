class WalletModel {
  final String id;
  final String name;
  final String emoji;
  final double balance;
  final bool showInExpense;
  final bool showInIncome;

  WalletModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.balance,
    this.showInExpense = true,
    this.showInIncome = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'balance': balance,
      'showInExpense': showInExpense ? 1 : 0,
      'showInIncome': showInIncome ? 1 : 0,
    };
  }

  factory WalletModel.fromMap(Map<String, dynamic> map) {
    return WalletModel(
      id: map['id'],
      name: map['name'],
      emoji: map['emoji'],
      balance: map['balance'],
      showInExpense: map['showInExpense'] == 1,
      showInIncome: map['showInIncome'] == 1,
    );
  }
}

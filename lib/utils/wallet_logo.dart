import 'package:flutter/material.dart';

Widget walletLogo(String walletId, {double size = 32}) {
  const logoMap = {
    'bca':     'assets/logos/BCA.png',
    'bri':     'assets/logos/BRI.png',
    'mandiri': 'assets/logos/Mandiri.png',
    'seabank': 'assets/logos/SeaBank.png',
    'jago':    'assets/logos/JAGO.png',
    'gopay':   'assets/logos/GoPay.png',
    'dana':    'assets/logos/Dana.png',
    'ovo':     'assets/logos/OVO.png',
    'shopee':  'assets/logos/ShoppePay.png',
  };

  const emojiMap = {
    'cash': '💵',
    'bni':  '🏦',
  };

  if (logoMap.containsKey(walletId)) {
    return Image.asset(
      logoMap[walletId]!,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }

  return Text(
    emojiMap[walletId] ?? '💳',
    style: TextStyle(fontSize: size * 0.75),
  );
}

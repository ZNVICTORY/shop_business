import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CurrencyText extends StatelessWidget {
  const CurrencyText(
    this.amount, {
    super.key,
    this.style,
    this.prefix = '¥',
  });

  final double amount;
  final TextStyle? style;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    final formatted = NumberFormat.currency(
      locale: 'zh_CN',
      symbol: prefix,
      decimalDigits: amount == amount.roundToDouble() ? 0 : 2,
    ).format(amount);
    return Text(formatted, style: style);
  }
}

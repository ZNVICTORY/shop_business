import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_store.dart';
import '../state/cart_store.dart';
import '../state/merchant_store.dart';
import '../widgets/currency_text.dart';
import 'payment_mock_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressCtrl = TextEditingController(text: '演示收货地址 · 某某市某某区某某路 1 号');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartStore>();
    final merchant = context.watch<MerchantStore>();
    final auth = context.watch<AuthStore>();

    final lines = cart.toOrderLines();
    double total = 0;
    for (final line in lines) {
      final p = merchant.products.firstWhere((x) => x.id == line.productId);
      total += p.price * line.quantity;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('确认订单')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('收货信息', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(
                labelText: '收货地址',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return '请填写收货地址';
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text('商品清单', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final line in lines)
              Card(
                child: ListTile(
                  title: Text(
                    merchant.products.firstWhere((x) => x.id == line.productId).name,
                  ),
                  subtitle: Text('× ${line.quantity}'),
                  trailing: CurrencyText(
                    merchant.products.firstWhere((x) => x.id == line.productId).price *
                        line.quantity,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '应付金额',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                CurrencyText(
                  total,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: lines.isEmpty
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate()) return;
                      final email = auth.email!;
                      final name = auth.displayName ?? '用户';
                      final orderId = merchant.placeCustomerOrder(
                        buyerEmail: email,
                        buyerDisplay: name,
                        address: _addressCtrl.text.trim(),
                        lines: lines,
                      );
                      if (!context.mounted) return;
                      if (orderId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('库存不足或商品已下架，请返回购物车调整')),
                        );
                        return;
                      }
                      context.read<CartStore>().clear();
                      await Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) => PaymentMockScreen(orderId: orderId),
                        ),
                      );
                    },
              child: const Text('提交订单'),
            ),
          ],
        ),
      ),
    );
  }
}

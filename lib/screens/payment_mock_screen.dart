import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/merchant_store.dart';
import '../theme/app_theme.dart';

/// 模拟收银台：真实项目此处跳转微信/支付宝 SDK 或 H5。
class PaymentMockScreen extends StatelessWidget {
  const PaymentMockScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('收银台')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '模拟支付',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '订单号：$orderId',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.onSurfaceMuted,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '点击下方按钮即视为支付成功，订单将进入「待发货」。接入真实支付后替换本页逻辑。',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.onSurfaceMuted,
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () {
                final ok =
                    context.read<MerchantStore>().mockPaymentSuccess(orderId);
                if (!context.mounted) return;
                if (!ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('支付失败或订单状态已变更')),
                  );
                  return;
                }
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('支付成功')),
                );
              },
              child: const Text('模拟支付成功'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('稍后支付'),
            ),
          ],
        ),
      ),
    );
  }
}

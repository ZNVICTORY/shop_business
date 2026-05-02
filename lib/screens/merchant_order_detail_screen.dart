import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../state/merchant_store.dart';
import '../theme/app_theme.dart';
import '../widgets/currency_text.dart';
import '../widgets/merchant_order_actions.dart';

/// 商家订单详情（备注、复制单号、统一操作入口）。
class MerchantOrderDetailScreen extends StatefulWidget {
  const MerchantOrderDetailScreen({super.key, required this.order});

  final ShopOrder order;

  @override
  State<MerchantOrderDetailScreen> createState() =>
      _MerchantOrderDetailScreenState();
}

class _MerchantOrderDetailScreenState extends State<MerchantOrderDetailScreen> {
  late final TextEditingController _noteCtrl;

  ShopOrder get order => widget.order;

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController(text: order.merchantNote);
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _saveNote(BuildContext context) {
    context.read<MerchantStore>().updateOrderMerchantNote(
          order,
          _noteCtrl.text.trim(),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('备注已保存')),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<MerchantStore>();
    final theme = Theme.of(context);
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');
    final branchTitle =
        context.read<MerchantStore>().branchName(order.branchId);

    return Scaffold(
      appBar: AppBar(
        title: Text(order.id),
        actions: [
          IconButton(
            tooltip: '复制订单号',
            icon: const Icon(Icons.copy_outlined),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: order.id));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已复制订单号')),
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  branchTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.onSurfaceMuted,
                  ),
                ),
              ),
              _StatusChip(status: order.status),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(label: '下单时间', value: dateFmt.format(order.createdAt)),
          if (order.buyerEmail != null && order.buyerEmail!.isNotEmpty)
            _InfoRow(label: '买家邮箱', value: order.buyerEmail!),
          _InfoRow(label: '收件人', value: order.buyer),
          if (order.address.isNotEmpty)
            _InfoRow(label: '收货地址', value: order.address),
          const SizedBox(height: 16),
          Text('商家备注', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: '对内备注，顾客不可见（可搜索）',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            onSubmitted: (_) => _saveNote(context),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonal(
              onPressed: () => _saveNote(context),
              child: const Text('保存备注'),
            ),
          ),
          const SizedBox(height: 16),
          Text('商品明细', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  for (final line in order.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Text(line.productName)),
                          Text('×${line.quantity}'),
                          const SizedBox(width: 12),
                          CurrencyText(line.lineTotal),
                        ],
                      ),
                    ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Spacer(),
                      Text('合计 ', style: theme.textTheme.bodySmall),
                      CurrencyText(
                        order.total,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('处理订单', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          MerchantOrderActionsBar(order: order),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.onSurfaceMuted,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../state/merchant_store.dart';
import '../theme/app_theme.dart';

/// 摄像头扫码或手输 SKU/条码，为当前门店增加库存。
class ScanInboundScreen extends StatefulWidget {
  const ScanInboundScreen({super.key});

  @override
  State<ScanInboundScreen> createState() => _ScanInboundScreenState();
}

class _ScanInboundScreenState extends State<ScanInboundScreen> {
  final _qtyCtrl = TextEditingController(text: '1');
  final _manualCtrl = TextEditingController();
  String? _lastCode;
  DateTime? _lastAutoInboundAt;

  static bool get _canUseCamera =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _manualCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<MerchantStore>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('扫码入库'),
            Text(
              '当前门店：${store.storeName}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.onSurfaceMuted,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_canUseCamera) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: MobileScanner(
                  onDetect: (capture) {
                    for (final b in capture.barcodes) {
                      final v = b.rawValue;
                      if (v != null && v.isNotEmpty) {
                        setState(() => _lastCode = v);
                        _confirmInbound(context, v, fromCamera: true);
                        break;
                      }
                    }
                  },
                ),
              ),
            ),
            if (_lastCode != null) ...[
              const SizedBox(height: 8),
              Text(
                '上次识别：$_lastCode',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.onSurfaceMuted,
                ),
              ),
            ],
          ] else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '当前环境不支持相机扫码，请使用下方手动输入 SKU / 商品编码。',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onSurfaceMuted,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text('手动入库', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _manualCtrl,
            decoration: const InputDecoration(
              labelText: 'SKU 或商品 ID',
              border: OutlineInputBorder(),
              hintText: '例：TS-001 或 h1',
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _qtyCtrl,
            decoration: const InputDecoration(
              labelText: '入库数量',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              final q = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
              _confirmInbound(context, _manualCtrl.text.trim(), qtyOverride: q);
            },
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('确认入库'),
          ),
        ],
      ),
    );
  }

  void _confirmInbound(
    BuildContext context,
    String code, {
    int? qtyOverride,
    bool fromCamera = false,
  }) {
    if (code.isEmpty) return;
    if (fromCamera) {
      final now = DateTime.now();
      if (_lastAutoInboundAt != null &&
          now.difference(_lastAutoInboundAt!) < const Duration(milliseconds: 1200)) {
        return;
      }
      _lastAutoInboundAt = now;
    }
    final store = context.read<MerchantStore>();
    final q = qtyOverride ?? int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    final err = store.inboundByScanCode(code, q);
    if (!context.mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已入库 $q 件（$code）')),
    );
    _manualCtrl.clear();
  }
}

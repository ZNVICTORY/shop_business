import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/order.dart';

String ordersToCsv(
  List<ShopOrder> orders,
  String Function(String branchId) branchName,
) {
  final buf = StringBuffer();
  buf.writeln('订单号,门店,状态,下单时间,买家,金额,地址,商家备注,邮箱');
  final df = DateFormat('yyyy-MM-dd HH:mm');
  for (final o in orders) {
    buf.writeln(
      [
        _csvCell(o.id),
        _csvCell(branchName(o.branchId)),
        _csvCell(o.status.label),
        _csvCell(df.format(o.createdAt)),
        _csvCell(o.buyer),
        o.total.toString(),
        _csvCell(o.address),
        _csvCell(o.merchantNote),
        _csvCell(o.buyerEmail ?? ''),
      ].join(','),
    );
  }
  return buf.toString();
}

String _csvCell(String s) {
  if (s.contains(',') ||
      s.contains('"') ||
      s.contains('\n') ||
      s.contains('\r')) {
    return '"${s.replaceAll('"', '""')}"';
  }
  return s;
}

/// 导出 CSV（可用 Excel 打开）；通过系统分享发出，全平台可用。
Future<void> shareOrdersCsv(String csv) async {
  await SharePlus.instance.share(
    ShareParams(
      text: csv,
      subject: '订单导出',
    ),
  );
}

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/order.dart';

/// 生成并唤起系统打印预览（电子面单样式，演示用）。
Future<void> printElectronicShippingLabel({
  required ShopOrder order,
  required String branchName,
}) async {
  final font = await PdfGoogleFonts.notoSansSCRegular();
  final dateFmt = DateFormat('yyyy-MM-dd HH:mm');
  final mockWaybill =
      'SF${order.id.hashCode.remainder(100000000).abs().toString().padLeft(8, '0')}';

  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: font),
  );

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat(
        100 * PdfPageFormat.mm,
        150 * PdfPageFormat.mm,
        marginAll: 8 * PdfPageFormat.mm,
      ),
      build: (ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '电子面单（演示）',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Text('发货门店：$branchName', style: const pw.TextStyle(fontSize: 10)),
            pw.Text('订单号：${order.id}', style: const pw.TextStyle(fontSize: 10)),
            pw.Text(
              '打印时间：${dateFmt.format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Divider(thickness: 0.5),
            pw.Text('运单号（模拟）：$mockWaybill',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text('收件人：${order.buyer}', style: const pw.TextStyle(fontSize: 10)),
            if (order.address.isNotEmpty)
              pw.Text('地址：${order.address}', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 6),
            pw.Text('商品明细', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            for (final it in order.items)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 2),
                child: pw.Text(
                  '${it.productName} × ${it.quantity}  '
                  '¥${it.unitPrice.toStringAsFixed(it.unitPrice == it.unitPrice.roundToDouble() ? 0 : 2)}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
            pw.Spacer(),
            pw.Text(
              '此为演示 PDF，接入快递网关后可替换为菜鸟/顺丰等真实面单。',
              style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
            ),
          ],
        );
      },
    ),
  );

  await Printing.layoutPdf(
    name: '电子面单_${order.id}.pdf',
    onLayout: (PdfPageFormat format) async => doc.save(),
  );
}

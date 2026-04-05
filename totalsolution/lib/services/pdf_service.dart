import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/models.dart';

class PdfService {
  /// Generate a professional PDF invoice for an order
  static Future<Uint8List> generateOrderPdf(OrderModel order) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(order),
              pw.SizedBox(height: 20),
              // Customer Info
              _buildCustomerInfo(order),
              pw.SizedBox(height: 20),
              // Items Table
              _buildItemsTable(order),
              pw.SizedBox(height: 20),
              // Totals
              _buildTotals(order),
              pw.SizedBox(height: 20),
              // Footer
              _buildFooter(order),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(OrderModel order) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFF1A3B70),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'TOTAL SOLUTION',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Order Management System',
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 12),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'INVOICE',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                order.orderNumber,
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCustomerInfo(OrderModel order) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Bill To:',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF1A3B70),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  order.customerName,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text('Phone: ${order.customerPhone}'),
                pw.Text('Area: ${order.areaName}'),
                if (order.routeName.isNotEmpty)
                  pw.Text('Route: ${order.routeName}'),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Order Details:',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF1A3B70),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text('Date: ${_formatDate(order.createdAt)}'),
                pw.Text('Status: ${order.statusDisplay}'),
                pw.Text('Type: ${order.orderTypeDisplay}'),
                if (order.paymentMode != null)
                  pw.Text('Payment: ${order.paymentMode!.name}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(OrderModel order) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header Row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFF1A3B70)),
          children: [
            _buildTableCell('Product', isHeader: true),
            _buildTableCell('Qty', isHeader: true),
            _buildTableCell('Rate', isHeader: true),
            _buildTableCell('Amount', isHeader: true),
          ],
        ),
        // Data Rows
        ...order.items.map(
          (item) => pw.TableRow(
            children: [
              _buildTableCell(item.productName),
              _buildTableCell(item.quantity.toString()),
              _buildTableCell('₹${item.rate.toStringAsFixed(2)}'),
              _buildTableCell('₹${item.amount.toStringAsFixed(2)}'),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _buildTotals(OrderModel order) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                _buildTotalRow('Subtotal', order.totalAmount),
                pw.SizedBox(height: 8),
                _buildTotalRow('Paid Amount', order.paidAmount),
                pw.SizedBox(height: 8),
                pw.Divider(color: PdfColors.grey400),
                pw.SizedBox(height: 8),
                _buildTotalRow(
                  'Balance Due',
                  order.dueAmount,
                  isBold: true,
                  color: order.dueAmount > 0
                      ? PdfColor.fromInt(0xFFE53935)
                      : PdfColors.green,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF00A68A),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text(
                  'TOTAL: ',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  '₹${order.totalAmount.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTotalRow(
    String label,
    double amount, {
    bool isBold = false,
    PdfColor? color,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            fontSize: isBold ? 14 : 12,
          ),
        ),
        pw.Text(
          '₹${amount.toStringAsFixed(2)}',
          style: pw.TextStyle(
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            fontSize: isBold ? 14 : 12,
            color: color,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildFooter(OrderModel order) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Terms & Conditions:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '• Payment is due within the agreed credit period.\n'
            '• Goods once sold cannot be returned.\n'
            '• Please contact support for any discrepancies.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Thank you for your business!',
                style: pw.TextStyle(
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColor.fromInt(0xFF1A3B70),
                ),
              ),
              pw.Text(
                'Generated on: ${_formatDateTime(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Share PDF to WhatsApp or other apps
  static Future<void> shareOrderPdf(OrderModel order) async {
    try {
      final pdfData = await generateOrderPdf(order);
      final fileName = 'Order_${order.orderNumber}.pdf';

      // Get temp directory
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pdfData);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Order ${order.orderNumber} - Total Solution',
        subject: 'Order Invoice - ${order.orderNumber}',
      );
    } catch (e) {
      throw Exception('Failed to share PDF: $e');
    }
  }

  /// Share PDF directly to WhatsApp
  static Future<void> shareToWhatsApp(OrderModel order) async {
    try {
      final pdfData = await generateOrderPdf(order);
      final fileName = 'Order_${order.orderNumber}.pdf';

      // Get temp directory
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pdfData);

      // Create WhatsApp share message
      final message =
          'Order ${order.orderNumber}\n'
          'Customer: ${order.customerName}\n'
          'Total: ₹${order.totalAmount.toStringAsFixed(2)}\n'
          'Items: ${order.items.length}\n\n'
          'Please find the attached invoice.';

      // Use share_plus for WhatsApp sharing
      await Share.shareXFiles(
        [XFile(file.path)],
        text: message,
        subject: 'Order Invoice - ${order.orderNumber}',
      );
    } catch (e) {
      throw Exception('Failed to share to WhatsApp: $e');
    }
  }

  /// Share order summary text to WhatsApp (without PDF)
  static Future<void> shareOrderSummaryToWhatsApp(OrderModel order) async {
    try {
      // Build order summary message
      String message = '🧾 *Order Details*\n\n';
      message += '*Order No:* ${order.orderNumber}\n';
      message += '*Customer:* ${order.customerName}\n';
      message += '*Phone:* ${order.customerPhone}\n';
      message += '*Area:* ${order.areaName}\n\n';
      message += '*Items:*\n';

      for (var item in order.items) {
        message +=
            '• ${item.productName} x ${item.quantity} = ₹${item.amount.toStringAsFixed(2)}\n';
      }

      message += '\n';
      message += '*Subtotal:* ₹${order.totalAmount.toStringAsFixed(2)}\n';
      if (order.paidAmount > 0) {
        message += '*Paid:* ₹${order.paidAmount.toStringAsFixed(2)}\n';
      }
      if (order.dueAmount > 0) {
        message += '*Due:* ₹${order.dueAmount.toStringAsFixed(2)}\n';
      }
      message += '\n*Total: ₹${order.totalAmount.toStringAsFixed(2)}*\n\n';
      message += 'Thank you for your business! 🙏';

      // Use share_plus for sharing
      await Share.share(
        message,
        subject: 'Order ${order.orderNumber} - Total Solution',
      );
    } catch (e) {
      throw Exception('Failed to share to WhatsApp: $e');
    }
  }

  /// Print the order PDF
  static Future<void> printOrderPdf(OrderModel order) async {
    try {
      final pdfData = await generateOrderPdf(order);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfData,
        name: 'Order_${order.orderNumber}',
      );
    } catch (e) {
      throw Exception('Failed to print PDF: $e');
    }
  }

  /// Download PDF to device
  static Future<String?> downloadOrderPdf(OrderModel order) async {
    try {
      final pdfData = await generateOrderPdf(order);
      final fileName = 'Order_${order.orderNumber}.pdf';

      // Get downloads directory
      final directory = await getExternalStorageDirectory();
      if (directory == null) return null;

      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdfData);

      return file.path;
    } catch (e) {
      throw Exception('Failed to download PDF: $e');
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  static String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} ${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}

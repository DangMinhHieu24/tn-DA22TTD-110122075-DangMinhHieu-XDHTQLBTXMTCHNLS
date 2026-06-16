import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/work_history_item.dart';

class PdfReportGenerator {
  static const _kGreen = PdfColor.fromInt(0xFF006E2F);
  static const _kLightGreen = PdfColor.fromInt(0xFFE8F5E9);
  static const _kGray = PdfColor.fromInt(0xFF6B7280);
  static const _kDark = PdfColor.fromInt(0xFF191C1E);
  static const _kBorder = PdfColor.fromInt(0xFFE5E7EB);

  static Future<Uint8List> generateVehicleHistoryReport({
    required String licensePlate,
    String? vehicleModel,
    String? vehicleColor,
    String? ownerName,
    String? ownerPhone,
    required List<WorkHistoryItem> items,
    DateTime? startDate,
    DateTime? endDate,
    Uint8List? fontBytes,
  }) async {
    final pdf = pw.Document();
    final font = fontBytes != null ? pw.Font.ttf(ByteData.view(fontBytes.buffer)) : null;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 24, 28, 24),
        build: (context) => [
          _buildHeader(font),
          pw.SizedBox(height: 20),
          _buildInfoSection(licensePlate, vehicleModel, vehicleColor, ownerName, ownerPhone, font),
          pw.SizedBox(height: 8),
          _buildDateFilter(startDate, endDate, font),
          pw.SizedBox(height: 14),
          _buildTable(items, font),
        ],
        footer: (context) => _buildFooter(context, font),
      ),
    );

    return pdf.save();
  }

  // ── Header ──────────────────────────────────────────────────────

  static pw.Widget _buildHeader(pw.Font? font) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [
            const PdfColor.fromInt(0xFF004D21),
            _kGreen,
          ],
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'NĂNG LƯỢNG SẠCH',
            style: pw.TextStyle(
              font: font,
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              letterSpacing: 2,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Hệ thống quản lý bảo trì xe điện thông minh',
            style: pw.TextStyle(
              font: font,
              fontSize: 10,
              color: PdfColor.fromInt(0xFFBBF7D0),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            width: double.infinity,
            height: 1,
            color: PdfColor.fromInt(0xFF22C55E),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'SAO KÊ LỊCH SỬ SỬA CHỮA',
            style: pw.TextStyle(
              font: font,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ── Info Section ────────────────────────────────────────────────

  static pw.Widget _buildInfoSection(
    String licensePlate,
    String? model,
    String? color,
    String? ownerName,
    String? ownerPhone,
    pw.Font? font,
  ) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: _kBorder, width: 0.5),
      ),
      child: pw.Column(
        children: [
          // Top: license plate + model
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.fromLTRB(20, 16, 20, 14),
            decoration: const pw.BoxDecoration(
              color: _kLightGreen,
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(10),
                topRight: pw.Radius.circular(10),
              ),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        licensePlate,
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: _kGreen,
                          letterSpacing: 2,
                        ),
                      ),
                      if (model != null || color != null)
                        pw.Text(
                          [model, color].whereType<String>().join(' • '),
                          style: pw.TextStyle(font: font, fontSize: 10, color: _kGray),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Owner info
          if (ownerName != null)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.fromLTRB(20, 12, 20, 14),
              child: pw.Row(
                children: [
                  pw.Container(
                    width: 28,
                    height: 28,
                    decoration: pw.BoxDecoration(
                      color: _kLightGreen,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(14)),
                    ),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      ownerName.isNotEmpty ? ownerName[0].toUpperCase() : 'C',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: _kGreen,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        ownerName,
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: _kDark,
                        ),
                      ),
                      if (ownerPhone != null)
                        pw.Text(
                          ownerPhone,
                          style: pw.TextStyle(font: font, fontSize: 9, color: _kGray),
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Date Filter ─────────────────────────────────────────────────

  static pw.Widget _buildDateFilter(DateTime? startDate, DateTime? endDate, pw.Font? font) {
    if (startDate == null && endDate == null) {
      return pw.SizedBox.shrink();
    }
    final start = '${startDate!.day.toString().padLeft(2, '0')}/${startDate.month.toString().padLeft(2, '0')}/${startDate.year}';
    final end = '${endDate!.day.toString().padLeft(2, '0')}/${endDate.month.toString().padLeft(2, '0')}/${endDate.year}';
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFFFF3E0),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Text(
        '  từ $start  đến $end',
        style: pw.TextStyle(
          font: font,
          fontSize: 10,
          color: PdfColor.fromInt(0xFFE65100),
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  // ── Table ───────────────────────────────────────────────────────

  static pw.Widget _buildTable(List<WorkHistoryItem> items, pw.Font? font) {
    if (items.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(32),
        alignment: pw.Alignment.center,
        child: pw.Text(
          'Không có dữ liệu phiếu sửa chữa.',
          style: pw.TextStyle(font: font, fontSize: 12, color: _kGray),
        ),
      );
    }

    const headers = ['STT', 'Mã WO', 'Ngày', 'Mô tả dịch vụ', 'Trạng thái', 'Thành tiền'];
    final widths = [0.05, 0.14, 0.12, 0.33, 0.18, 0.18];
    final grandTotal = items.fold<double>(0, (sum, item) => sum + (item.totalCost ?? 0));

    return pw.Table(
      border: pw.TableBorder.all(color: _kBorder, width: 0.5),
      columnWidths: {
        for (var i = 0; i < headers.length; i++)
          i: pw.FlexColumnWidth(widths[i]),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _kGreen),
          children: headers.map((h) => pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 9, horizontal: 6),
            child: pw.Text(
              h,
              style: pw.TextStyle(
                font: font,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          )).toList(),
        ),
        // Rows
        for (var i = 0; i < items.length; i++)
          pw.TableRow(
            decoration: i.isEven
                ? const pw.BoxDecoration()
                : pw.BoxDecoration(color: PdfColor.fromInt(0xFFF9FAFB)),
            children: [
              _cell('${i + 1}', font, align: pw.TextAlign.center),
              _cell(items[i].orderNumber, font, bold: true),
              _cell(
                items[i].createdAt != null
                    ? '${items[i].createdAt!.day.toString().padLeft(2, '0')}/${items[i].createdAt!.month.toString().padLeft(2, '0')}/${items[i].createdAt!.year}'
                    : '',
                font,
              ),
              _cell(items[i].description ?? items[i].notes ?? '', font, maxLines: 2),
              _statusCell(items[i].status, font),
              _cell(_formatCurrency(items[i].totalCost), font, align: pw.TextAlign.right, bold: true),
            ],
          ),
        // Grand total row
        if (grandTotal > 0)
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFE2E8F0)),
            children: [
              _cell('', font),
              _cell('', font),
              _cell('', font),
              _cell('Tổng cộng', font, bold: true, align: pw.TextAlign.right),
              _cell('', font),
              _cell(_formatCurrency(grandTotal), font, bold: true, align: pw.TextAlign.right),
            ],
          ),
      ],
    );
  }

  static pw.Widget _cell(String text, pw.Font? font, {
    pw.TextAlign align = pw.TextAlign.left,
    bool bold = false,
    int maxLines = 1,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 6),
      child: pw.Text(
        text,
        textAlign: align,
        maxLines: maxLines,
        style: pw.TextStyle(
          font: font,
          fontSize: 8.5,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: _kDark,
        ),
      ),
    );
  }

  static pw.Widget _statusCell(String? status, pw.Font? font) {
    final color = _getStatusColor(status);
    final bgColor = _getStatusBgColor(status);
    final text = _getStatusText(status);
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 6),
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            font: font,
            fontSize: 7.5,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  // ── Footer ──────────────────────────────────────────────────────

  static pw.Widget _buildFooter(pw.Context context, pw.Font? font) {
    final now = DateTime.now();
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 16),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _kBorder, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Xuất ngày ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
            style: pw.TextStyle(font: font, fontSize: 8, color: _kGray),
          ),
          pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: pw.TextStyle(font: font, fontSize: 8, color: _kGray),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────

  static PdfColor _getStatusColor(String? status) {
    switch (status) {
      case 'PENDING':
        return PdfColor.fromInt(0xFFF97316);
      case 'IN_PROGRESS':
        return PdfColor.fromInt(0xFF3B82F6);
      case 'INSPECTION':
        return PdfColor.fromInt(0xFF9C27B0);
      case 'COMPLETED':
        return PdfColor.fromInt(0xFF4CAF50);
      case 'PAID':
        return _kGreen;
      case 'CANCELLED':
        return PdfColor.fromInt(0xFFEF4444);
      default:
        return PdfColor.fromInt(0xFF9CA3AF);
    }
  }

  static PdfColor _getStatusBgColor(String? status) {
    switch (status) {
      case 'PENDING':
        return PdfColor.fromInt(0xFFFFF3E0);
      case 'IN_PROGRESS':
        return PdfColor.fromInt(0xFFE3F2FD);
      case 'INSPECTION':
        return PdfColor.fromInt(0xFFF3E5F5);
      case 'COMPLETED':
        return PdfColor.fromInt(0xFFE8F5E9);
      case 'PAID':
        return PdfColor.fromInt(0xFFE0F2E9);
      case 'CANCELLED':
        return PdfColor.fromInt(0xFFFEE2E2);
      default:
        return PdfColor.fromInt(0xFFF3F4F6);
    }
  }

  static String _getStatusText(String? status) {
    switch (status) {
      case 'PENDING':
        return 'CHỜ XỬ LÝ';
      case 'IN_PROGRESS':
        return 'ĐANG THỰC HIỆN';
      case 'INSPECTION':
        return 'KIỂM TRA';
      case 'COMPLETED':
        return 'HOÀN THÀNH';
      case 'PAID':
        return 'ĐÃ THANH TOÁN';
      case 'CANCELLED':
        return 'ĐÃ HỦY';
      default:
        return 'KHÔNG RÕ';
    }
  }

  static String _formatCurrency(double? amount) {
    if (amount == null || amount == 0) return '';
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '$formatted₫';
  }
}

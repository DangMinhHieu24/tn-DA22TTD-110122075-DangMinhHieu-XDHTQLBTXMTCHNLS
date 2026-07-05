import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../../../domain/entities/revenue_report.dart';

class PdfRevenueReportGenerator {
  static const _kGreen = PdfColor.fromInt(0xFF006E2F);
  static const _kDarkGreen = PdfColor.fromInt(0xFF004D21);
  static const _kLightGreen = PdfColor.fromInt(0xFFE8F5E9);
  static const _kGray = PdfColor.fromInt(0xFF6B7280);
  static const _kLightGray = PdfColor.fromInt(0xFFF3F4F6);
  static const _kDark = PdfColor.fromInt(0xFF191C1E);
  static const _kBorder = PdfColor.fromInt(0xFFE5E7EB);
  static const _kWhite = PdfColor.fromInt(0xFFFFFFFF);

  static Future<Uint8List> generate({
    required RevenueReport report,
    Uint8List? fontBytes,
  }) async {
    final pdf = pw.Document();
    final font = fontBytes != null ? pw.Font.ttf(ByteData.view(fontBytes.buffer)) : null;

    final rangeLabel = _formatRangeLabel(report.rangeStart, report.rangeEnd);
    final nowStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final avgDaily = report.dailyRevenue.isNotEmpty
        ? report.totalRevenue / report.dailyRevenue.length
        : 0.0;
    final avgOrderValue = report.totalOrders > 0
        ? report.totalRevenue / report.totalOrders
        : 0.0;
    final growthSign = report.growthPercent >= 0 ? '+' : '';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 24, 28, 24),
        build: (context) => [
          _buildHeader(context, rangeLabel, font),
          pw.SizedBox(height: 20),
          _buildMetricCards(report, avgDaily, avgOrderValue, growthSign, font),
          pw.SizedBox(height: 22),
          _buildSectionTitle('CHI TIẾT DOANH THU THEO NGÀY', font),
          pw.SizedBox(height: 8),
          _buildDailyTable(report.dailyRevenue, font),
          pw.SizedBox(height: 22),
          _buildSectionTitle('DỊCH VỤ PHỔ BIẾN', font),
          pw.SizedBox(height: 8),
          _buildServicesTable(report.topServices, report.totalRevenue, font),
          pw.SizedBox(height: 22),
          _buildSectionTitle('HIỆU SUẤT KỸ THUẬT VIÊN', font),
          pw.SizedBox(height: 8),
          _buildTechniciansTable(report.technicians, font),
        ],
        footer: (context) => _buildFooter(context, nowStr, font),
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(pw.Context context, String rangeLabel, pw.Font? font) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(24, 22, 24, 16),
      decoration: pw.BoxDecoration(
        gradient: const pw.LinearGradient(
          begin: pw.Alignment.centerLeft,
          end: pw.Alignment.centerRight,
          colors: [_kDarkGreen, _kGreen],
        ),
        borderRadius: const pw.BorderRadius.only(
          topLeft: pw.Radius.circular(14),
          topRight: pw.Radius.circular(14),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'NĂNG LƯỢNG SẠCH',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: _kWhite,
                      letterSpacing: 3,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'Hệ thống quản lý bảo trì xe điện thông minh',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 9,
                      color: const PdfColor.fromInt(0xFFA7F3D0),
                    ),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0x26FFFFFF),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Text(
                  rangeLabel,
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: _kWhite,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            width: double.infinity,
            height: 1,
            color: const PdfColor.fromInt(0x8022C55E),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'BÁO CÁO DOANH THU',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: _kWhite,
                  letterSpacing: 1.5,
                ),
              ),
              pw.Text(
                'Ngày xuất: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 8.5,
                  color: const PdfColor.fromInt(0xFFBBF7D0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMetricCards(RevenueReport report, double avgDaily, double avgOrderValue, String growthSign, pw.Font? font) {
    return pw.Row(
      children: [
        _metricCard(
          'Tổng doanh thu',
          _formatCurrency(report.totalRevenue),
          '${growthSign}${_formatPercent(report.growthPercent)}',
          const PdfColor.fromInt(0xFFE8F5E9),
          _kGreen,
          font,
        ),
        pw.SizedBox(width: 10),
        _metricCard(
          'Tổng đơn hàng',
          '${report.totalOrders}',
          '${report.dailyRevenue.length} ngày',
          const PdfColor.fromInt(0xFFE3F2FD),
          const PdfColor.fromInt(0xFF0058BE),
          font,
        ),
        pw.SizedBox(width: 10),
        _metricCard(
          'TB doanh thu/ngày',
          _formatCurrency(avgDaily),
          'TB/đơn: ${_formatCurrency(avgOrderValue)}',
          const PdfColor.fromInt(0xFFFFF3E0),
          const PdfColor.fromInt(0xFFD97706),
          font,
        ),
      ],
    );
  }

  static pw.Widget _metricCard(String title, String value, String subtitle, PdfColor bgColor, PdfColor accentColor, pw.Font? font) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
          border: pw.Border.all(color: const PdfColor.fromInt(0x33000000), width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                font: font,
                fontSize: 8,
                color: _kGray,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              value,
              style: pw.TextStyle(
                font: font,
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: _kDark,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              subtitle,
              style: pw.TextStyle(
                font: font,
                fontSize: 7.5,
                color: accentColor,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildSectionTitle(String title, pw.Font? font) {
    return pw.Row(
      children: [
        pw.Container(
          width: 4,
          height: 18,
          decoration: const pw.BoxDecoration(
            color: _kGreen,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Text(
          title,
          style: pw.TextStyle(
            font: font,
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: _kDark,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildDailyTable(List<RevenuePoint> points, pw.Font? font) {
    if (points.isEmpty) {
      return _emptyTable('Không có dữ liệu doanh thu theo ngày.');
    }

    const headers = ['STT', 'Ngày', 'Thứ', 'Doanh thu', 'Số đơn', 'TB/đơn', 'Tích lũy'];
    final widths = [0.06, 0.16, 0.14, 0.18, 0.10, 0.17, 0.19];

    double runningRevenue = 0.0;

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _kBorder, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Table(
        border: pw.TableBorder(
          horizontalInside: pw.BorderSide(color: _kBorder, width: 0.5),
          verticalInside: pw.BorderSide(color: _kBorder, width: 0.5),
        ),
        columnWidths: {
          for (var i = 0; i < headers.length; i++)
            i: pw.FlexColumnWidth(widths[i]),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(
              color: _kDarkGreen,
            ),
            children: headers.map((h) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 5),
              child: pw.Text(
                h,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  font: font,
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: _kWhite,
                ),
              ),
            )).toList(),
          ),
          for (var i = 0; i < points.length; i++) ...[
            (() {
              runningRevenue += points[i].revenue;
              final dateStr = DateFormat('dd/MM/yyyy').format(points[i].date);
              final dayName = _dayOfWeekVietnamese(points[i].date.weekday);
              final avgVal = points[i].orders > 0 ? points[i].revenue / points[i].orders : 0.0;

              return pw.TableRow(
                decoration: i % 2 == 0
                    ? pw.BoxDecoration(color: _kWhite)
                    : pw.BoxDecoration(color: _kLightGray),
                children: [
                  _cell('${i + 1}', font, align: pw.TextAlign.center),
                  _cell(dateStr, font, align: pw.TextAlign.center),
                  _cell(dayName, font, align: pw.TextAlign.center),
                  _cell(_formatCurrency(points[i].revenue), font, align: pw.TextAlign.right, bold: true, color: _kGreen),
                  _cell('${points[i].orders}', font, align: pw.TextAlign.center),
                  _cell(_formatCurrency(avgVal), font, align: pw.TextAlign.right),
                  _cell(_formatCurrency(runningRevenue), font, align: pw.TextAlign.right, bold: true),
                ],
              );
            }())
          ],
          pw.TableRow(
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFE2E8F0),
            ),
            children: [
              _cell('', font),
              _cell('', font),
              _cell('Tổng', font, bold: true, align: pw.TextAlign.right),
              _cell(_formatCurrency(runningRevenue), font, bold: true, align: pw.TextAlign.right, color: _kDark),
              _cell('${points.fold<int>(0, (s, p) => s + p.orders)}', font, bold: true, align: pw.TextAlign.center),
              _cell('', font),
              _cell('', font),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildServicesTable(List<ServiceBreakdown> services, double totalRevenue, pw.Font? font) {
    if (services.isEmpty) return _emptyTable('Không có dữ liệu dịch vụ.');

    const headers = ['STT', 'Tên dịch vụ / Gói sửa chữa', 'Doanh thu', 'Tỷ trọng'];
    final widths = [0.06, 0.56, 0.20, 0.18];

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _kBorder, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Table(
        border: pw.TableBorder(
          horizontalInside: pw.BorderSide(color: _kBorder, width: 0.5),
          verticalInside: pw.BorderSide(color: _kBorder, width: 0.5),
        ),
        columnWidths: {
          for (var i = 0; i < headers.length; i++)
            i: pw.FlexColumnWidth(widths[i]),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(
              color: _kDarkGreen,
            ),
            children: headers.map((h) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 5),
              child: pw.Text(
                h,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  font: font,
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: _kWhite,
                ),
              ),
            )).toList(),
          ),
          for (var i = 0; i < services.length; i++)
            pw.TableRow(
              decoration: i % 2 == 0
                  ? pw.BoxDecoration(color: _kWhite)
                  : pw.BoxDecoration(color: _kLightGray),
              children: [
                _cell('${i + 1}', font, align: pw.TextAlign.center),
                _cell(services[i].name, font),
                _cell(_formatCurrency(services[i].revenue), font, align: pw.TextAlign.right, bold: true),
                _cell('${services[i].percent.toStringAsFixed(1)}%', font, align: pw.TextAlign.center, bold: true, color: _kGreen),
              ],
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildTechniciansTable(List<TechnicianBreakdown> technicians, pw.Font? font) {
    if (technicians.isEmpty) return _emptyTable('Không có dữ liệu kỹ thuật viên.');

    const headers = ['STT', 'Họ và tên', 'Doanh thu', 'Hoàn thành', 'Đang xử lý'];
    final widths = [0.06, 0.46, 0.22, 0.14, 0.12];

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _kBorder, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Table(
        border: pw.TableBorder(
          horizontalInside: pw.BorderSide(color: _kBorder, width: 0.5),
          verticalInside: pw.BorderSide(color: _kBorder, width: 0.5),
        ),
        columnWidths: {
          for (var i = 0; i < headers.length; i++)
            i: pw.FlexColumnWidth(widths[i]),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(
              color: _kDarkGreen,
            ),
            children: headers.map((h) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 5),
              child: pw.Text(
                h,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  font: font,
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: _kWhite,
                ),
              ),
            )).toList(),
          ),
          for (var i = 0; i < technicians.length; i++)
            pw.TableRow(
              decoration: i % 2 == 0
                  ? pw.BoxDecoration(color: _kWhite)
                  : pw.BoxDecoration(color: _kLightGray),
              children: [
                _cell('${i + 1}', font, align: pw.TextAlign.center),
                _cell(technicians[i].name, font, bold: true),
                _cell(_formatCurrency(technicians[i].revenue), font, align: pw.TextAlign.right, bold: true, color: _kGreen),
                _cell('${technicians[i].orders} đơn', font, align: pw.TextAlign.center),
                _cell('${technicians[i].activeOrders} đơn', font, align: pw.TextAlign.center),
              ],
            ),
        ],
      ),
    );
  }

  static pw.Widget _cell(String text, pw.Font? font, {
    pw.TextAlign align = pw.TextAlign.left,
    bool bold = false,
    PdfColor color = _kDark,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          font: font,
          fontSize: 8,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  static pw.Widget _emptyTable(String message) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(24),
      decoration: pw.BoxDecoration(
        color: _kLightGray,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: _kBorder, width: 0.5),
      ),
      child: pw.Center(
        child: pw.Text(
          message,
          style: pw.TextStyle(fontSize: 10, color: _kGray),
        ),
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context, String nowStr, pw.Font? font) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 16),
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _kBorder, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 3,
                height: 3,
                decoration: const pw.BoxDecoration(
                  color: _kGreen,
                  shape: pw.BoxShape.circle,
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Text(
                'Hệ thống quản lý Năng Lượng Sạch',
                style: pw.TextStyle(font: font, fontSize: 7.5, color: _kGray),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                '·',
                style: pw.TextStyle(font: font, fontSize: 7.5, color: _kGray),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                'Xuất lúc $nowStr',
                style: pw.TextStyle(font: font, fontSize: 7.5, color: _kGray),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: pw.BoxDecoration(
              color: _kLightGreen,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              'Trang ${context.pageNumber} / ${context.pagesCount}',
              style: pw.TextStyle(
                font: font,
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
                color: _kGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatRangeLabel(DateTime start, DateTime end) {
    final formatter = DateFormat('dd/MM/yyyy');
    return '${formatter.format(start)} - ${formatter.format(end)}';
  }

  static String _dayOfWeekVietnamese(int weekday) {
    switch (weekday) {
      case 1: return 'Thứ Hai';
      case 2: return 'Thứ Ba';
      case 3: return 'Thứ Tư';
      case 4: return 'Thứ Năm';
      case 5: return 'Thứ Sáu';
      case 6: return 'Thứ Bảy';
      case 7: return 'Chủ Nhật';
      default: return '';
    }
  }

  static String _formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '$formatted₫';
  }

  static String _formatPercent(double value) {
    return '${value.toStringAsFixed(1)}%';
  }
}

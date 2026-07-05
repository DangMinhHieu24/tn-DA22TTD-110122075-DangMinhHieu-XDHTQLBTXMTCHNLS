import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'package:get_it/get_it.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:auth/auth.dart';
import 'package:excel/excel.dart' as excel_lib;

class DataExportPage extends StatefulWidget {
  const DataExportPage({super.key});

  @override
  State<DataExportPage> createState() => _DataExportPageState();
}

class _DataExportPageState extends State<DataExportPage> {
  int? _selectedYear;
  bool _isLoading = false;
  final List<int> _availableYears = List.generate(10, (index) => DateTime.now().year - index);
  static const String _baseUrl = 'https://nanglungsach-api.onrender.com/api';

  Future<String?> _getToken() async {
    try {
      final authLocalDataSource = GetIt.instance<AuthLocalDataSource>();
      return await authLocalDataSource.getToken();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      appBar: AppBar(
        title: const Text(
          'Truy xuất dữ liệu',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),
            _buildYearSelector(),
            const SizedBox(height: 24),
            _buildExportOptions(),
            const SizedBox(height: 32),
            _buildExportButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E40AF),
            Color(0xFF3B82F6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.file_download_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Xuất hồ sơ bảo hành kỹ thuật số',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildYearSelector() {
    final currentYear = DateTime.now().year;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Chọn năm xuất dữ liệu',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Dropdown để chọn năm
          GestureDetector(
            onTap: () => _showYearPicker(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _selectedYear != null
                      ? AppColors.primary
                      : AppColors.outline.withValues(alpha: 0.3),
                  width: _selectedYear != null ? 2 : 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.event_rounded,
                        color: _selectedYear != null
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedYear != null
                            ? 'Năm $_selectedYear'
                            : 'Chọn năm...',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _selectedYear != null
                              ? AppColors.onSurface
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                      if (_selectedYear == currentYear)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Hiện tại',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    color: AppColors.onSurfaceVariant,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showYearPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Chọn năm xuất dữ liệu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _availableYears.length,
                  itemBuilder: (context, index) {
                    final year = _availableYears[index];
                    final isSelected = _selectedYear == year;
                    final isCurrentYear = year == DateTime.now().year;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              _selectedYear = year;
                            });
                            Navigator.pop(ctx);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.1)
                                  : AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.onSurfaceVariant,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Năm $year',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.onSurface,
                                    ),
                                  ),
                                ),
                                if (isCurrentYear)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Hiện tại',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportOptions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Dữ liệu sẽ bao gồm',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildExportItem(
            icon: Icons.assignment_outlined,
            title: 'Hồ sơ bảo hành',
            description: 'Toàn bộ hồ sơ bảo hành đã kích hoạt',
          ),
          const Divider(height: 24),
          _buildExportItem(
            icon: Icons.people_outline_rounded,
            title: 'Thông tin khách hàng',
            description: 'Họ tên, SĐT, email, địa chỉ',
          ),
          const Divider(height: 24),
          _buildExportItem(
            icon: Icons.directions_car_outlined,
            title: 'Thông tin xe',
            description: 'Biển số, mã VIN, model xe',
          ),
          const Divider(height: 24),
          _buildExportItem(
            icon: Icons.build_outlined,
            title: 'Phiếu sửa chữa',
            description: 'Phiếu sửa chữa, trạng thái, chi phí',
          ),
        ],
      ),
    );
  }

  Widget _buildExportItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF059669),
          size: 20,
        ),
      ],
    );
  }

  Widget _buildExportButton() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            boxShadow: _selectedYear != null
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: ElevatedButton.icon(
            onPressed: _selectedYear == null || _isLoading
                ? null
                : () => _showExportDialog(),
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.download_rounded, size: 22),
            label: Text(
              _isLoading ? 'Đang xuất dữ liệu...' : 'Xuất dữ liệu năm $_selectedYear',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedYear != null
                  ? AppColors.primary
                  : AppColors.surfaceContainerLow,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF059669).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF059669),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Dữ liệu được xuất theo định dạng Excel (.xlsx) và có thể được sử dụng cho mục đích lưu trữ, kiểm tra hoặc cung cấp cho cơ quan có thẩm quyền.',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF059669).withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showExportDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Xuất dữ liệu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF191C1E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Chọn cách xuất dữ liệu năm $_selectedYear',
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 24),
              _exportOption(
                icon: Icons.save_alt_rounded,
                title: 'Tải xuống',
                subtitle: 'Lưu file Excel vào thiết bị',
                color: const Color(0xFF006E2F),
                onTap: () {
                  Navigator.pop(ctx);
                  _exportAndSaveFile();
                },
              ),
              const SizedBox(height: 12),
              _exportOption(
                icon: Icons.share_rounded,
                title: 'Chia sẻ',
                subtitle: 'Gửi qua Gmail, Drive, hoặc ứng dụng khác',
                color: const Color(0xFF3B82F6),
                onTap: () {
                  Navigator.pop(ctx);
                  _exportAndShareFile();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _exportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.15), width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF191C1E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchAllData(String token) async {
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final results = await Future.wait([
      http.get(Uri.parse('$_baseUrl/warranties'), headers: headers)
          .timeout(const Duration(seconds: 60)),
      http.get(Uri.parse('$_baseUrl/users/customers'), headers: headers)
          .timeout(const Duration(seconds: 60)),
      http.get(Uri.parse('$_baseUrl/vehicles'), headers: headers)
          .timeout(const Duration(seconds: 60)),
      http.get(Uri.parse('$_baseUrl/work-orders'), headers: headers)
          .timeout(const Duration(seconds: 60)),
    ]);

    Map<String, dynamic> data = {};

    for (var i = 0; i < results.length; i++) {
      if (results[i].statusCode == 200) {
        final json = jsonDecode(results[i].body);
        if (json['success'] == true) {
          final raw = json['data'];
          if (raw is List) {
            data[['warranties', 'customers', 'vehicles', 'workOrders'][i]] = raw;
          } else if (raw is Map && raw.containsKey('data')) {
            data[['warranties', 'customers', 'vehicles', 'workOrders'][i]] = raw['data'] as List<dynamic>? ?? [];
          } else {
            data[['warranties', 'customers', 'vehicles', 'workOrders'][i]] = [];
          }
        } else {
          data[['warranties', 'customers', 'vehicles', 'workOrders'][i]] = [];
        }
      } else {
        data[['warranties', 'customers', 'vehicles', 'workOrders'][i]] = [];
      }
    }

    // Fetch service/part details for work orders that lack them
    final wos = data['workOrders'] as List<dynamic>;
    if (wos.any((wo) => (wo['services'] as List<dynamic>?) == null || (wo['partsUsed'] as List<dynamic>?) == null)) {
      data['serviceDetails'] = await _fetchWoServicesAndParts(wos, token, _selectedYear!);
    } else {
      data['serviceDetails'] = _extractServicesAndParts(wos, _selectedYear!);
    }

    return data;
  }

  Future<List<Map<String, dynamic>>> _fetchWoServicesAndParts(
      List<dynamic> workOrders, String token, int year) async {
    final results = <Map<String, dynamic>>[];
    const batchSize = 10;

    for (var i = 0; i < workOrders.length; i += batchSize) {
      final batch = workOrders.skip(i).take(batchSize).toList();

      final futures = <Future<Map<String, dynamic>>>[];
      for (var wo in batch) {
        futures.add(_fetchWoDetail(wo, token, year));
      }
      results.addAll(await Future.wait(futures));
    }

    return results.where((r) => r['rows'] is List && (r['rows'] as List).isNotEmpty).toList();
  }

  Future<Map<String, dynamic>> _fetchWoDetail(dynamic wo, String token, int year) async {
    final woId = wo['id'] as String?;
    if (woId == null) return {'woId': '', 'rows': []};

    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/work-orders/$woId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['success'] == true) {
          return _extractWoRows(json['data'], year);
        }
      }
    } catch (_) {}
    return _extractWoRows(wo, year);
  }

  Map<String, dynamic> _extractWoRows(dynamic wo, int year) {
    final rows = <Map<String, String>>[];
    final createdAt = wo['createdAt'] as String? ?? wo['createdDate'] as String? ?? '';
    DateTime? createdDate;
    try { createdDate = DateTime.parse(createdAt); } catch (_) {}

    if (createdDate != null && createdDate.year != year) return {'woId': wo['id'] ?? '', 'rows': []};

    final vehicle = wo['vehicle'] as Map<String, dynamic>?;
    final licensePlate = vehicle?['licensePlate']?.toString() ?? '';

    final services = wo['services'] as List<dynamic>? ?? [];
    for (var s in services) {
      final sName = s['description']?.toString() ?? s['serviceType']?.toString() ?? s['serviceName']?.toString() ?? '';
      final qty = (s['quantity'] as num?)?.toInt() ?? 1;
      final price = (s['price'] as num?)?.toDouble() ?? (s['unitPrice'] as num?)?.toDouble() ?? 0;
      final total = (s['total'] as num?)?.toDouble() ?? price * qty;
      rows.add({
        'woId': wo['id']?.toString() ?? '',
        'licensePlate': licensePlate,
        'type': 'Dịch vụ',
        'name': sName,
        'qty': qty.toString(),
        'price': price.toStringAsFixed(0),
        'total': total.toStringAsFixed(0),
        'date': _fmtDate(createdAt),
      });
    }

    final parts = wo['partsUsed'] as List<dynamic>? ?? [];
    for (var p in parts) {
      final pName = p['partName']?.toString() ?? '';
      final qty = (p['quantity'] as num?)?.toInt() ?? 1;
      final price = (p['unitPrice'] as num?)?.toDouble() ?? (p['price'] as num?)?.toDouble() ?? 0;
      final total = (p['total'] as num?)?.toDouble() ?? price * qty;
      rows.add({
        'woId': wo['id']?.toString() ?? '',
        'licensePlate': licensePlate,
        'type': 'Phụ tùng',
        'name': pName,
        'qty': qty.toString(),
        'price': price.toStringAsFixed(0),
        'total': total.toStringAsFixed(0),
        'date': _fmtDate(createdAt),
      });
    }

    return {'woId': wo['id'] ?? '', 'rows': rows};
  }

  List<Map<String, dynamic>> _extractServicesAndParts(List<dynamic> workOrders, int year) {
    final results = <Map<String, dynamic>>[];
    for (var wo in workOrders) {
      final r = _extractWoRows(wo, year);
      if ((r['rows'] as List).isNotEmpty) results.add(r);
    }
    return results;
  }

  Future<void> _exportAndSaveFile() async {
    setState(() { _isLoading = true; });

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Phiên đăng nhập hết hạn, vui lòng đăng nhập lại');
      }

      final data = await _fetchAllData(token);
      if (!mounted) return;

      final excelBytes = _generateExcel(data, _selectedYear!);
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/warranty-data-$_selectedYear.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(excelBytes);

      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSaveSuccessDialog(filePath);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorDialog(error.toString());
    }
  }

  Future<void> _exportAndShareFile() async {
    setState(() { _isLoading = true; });

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Phiên đăng nhập hết hạn, vui lòng đăng nhập lại');
      }

      final data = await _fetchAllData(token);
      if (!mounted) return;

      final excelBytes = _generateExcel(data, _selectedYear!);
      final tempDir = Directory.systemTemp;
      final fileName = 'warranty-data-$_selectedYear.xlsx';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(excelBytes, flush: true);

      if (!mounted) return;
      setState(() => _isLoading = false);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Dữ liệu hệ thống năm $_selectedYear',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (!error.toString().contains('share')) {
        _showErrorDialog(error.toString());
      }
    }
  }

  String _fmtDate(dynamic v) {
    if (v == null || v == '') return '';
    try {
      final d = DateTime.parse(v.toString());
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return v.toString();
    }
  }

  String _statusText(dynamic s) {
    switch ((s as String? ?? '').toUpperCase()) {
      case 'ACTIVE': return 'Đang hiệu lực';
      case 'EXPIRING_SOON': return 'Sắp hết hạn';
      case 'EXPIRED': return 'Đã hết hạn';
      case 'PENDING': return 'Chờ xử lý';
      case 'IN_PROGRESS': return 'Đang thực hiện';
      case 'COMPLETED': return 'Hoàn thành';
      case 'CANCELLED': return 'Đã hủy';
      default: return s?.toString() ?? '';
    }
  }

  Uint8List _generateExcel(Map<String, dynamic> data, int year) {
    final excel = excel_lib.Excel.createExcel();

    // Helper: style header row
    void applyHeaderStyle(excel_lib.Sheet sheet) {
      for (var j = 0; j < sheet.maxColumns; j++) {
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: j, rowIndex: 0)).cellStyle = excel_lib.CellStyle(
          bold: true,
          fontSize: 11,
          fontColorHex: excel_lib.ExcelColor.fromHexString('#FFFFFF'),
          backgroundColorHex: excel_lib.ExcelColor.fromHexString('#1B5E20'),
          horizontalAlign: excel_lib.HorizontalAlign.Center,
        );
      }
    }

    // Helper: auto column widths
    void autoWidth(excel_lib.Sheet sheet, List<double> widths) {
      for (var i = 0; i < widths.length; i++) {
        sheet.setColumnWidth(i, widths[i]);
      }
    }

    final warranties = data['warranties'] as List<dynamic>? ?? [];
    final customers = data['customers'] as List<dynamic>? ?? [];
    final vehicles = data['vehicles'] as List<dynamic>? ?? [];
    final workOrders = data['workOrders'] as List<dynamic>? ?? [];

    final now = DateTime.now();
    final nowStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // =====================================================================
    // SHEET 1: GIỚI THIỆU
    // =====================================================================
    final intro = excel['GIỚI THIỆU'];
    intro.setColumnWidth(0, 18);
    intro.setColumnWidth(1, 40);

    // Title block
    intro.appendRow([excel_lib.TextCellValue('')]);
    intro.appendRow([excel_lib.TextCellValue('')]);
    intro.appendRow([excel_lib.TextCellValue('XANH EV'), excel_lib.TextCellValue('')]);
    intro.appendRow([excel_lib.TextCellValue('HỆ THỐNG QUẢN LÝ BẢO HÀNH KỸ THUẬT SỐ'), excel_lib.TextCellValue('')]);
    intro.appendRow([excel_lib.TextCellValue('')]);
    intro.appendRow([excel_lib.TextCellValue('BÁO CÁO HỒ SƠ BẢO HÀNH KỸ THUẬT SỐ'), excel_lib.TextCellValue('')]);
    intro.appendRow([excel_lib.TextCellValue('Dùng cho mục đích lưu trữ, kiểm tra và cung cấp cho cơ quan có thẩm quyền'), excel_lib.TextCellValue('')]);
    intro.appendRow([excel_lib.TextCellValue('')]);
    intro.appendRow([excel_lib.TextCellValue('')]);

    // Metadata
    intro.appendRow([excel_lib.TextCellValue('NĂM BÁO CÁO'), excel_lib.TextCellValue(year.toString())]);
    intro.appendRow([excel_lib.TextCellValue('NGÀY XUẤT'), excel_lib.TextCellValue(nowStr)]);
    intro.appendRow([excel_lib.TextCellValue('ĐƠN VỊ'), excel_lib.TextCellValue('Công ty Xanh EV')]);
    intro.appendRow([excel_lib.TextCellValue(''), excel_lib.TextCellValue('')]);
    intro.appendRow([excel_lib.TextCellValue('THỐNG KÊ TỔNG QUAN'), excel_lib.TextCellValue('')]);
    intro.appendRow([excel_lib.TextCellValue('Tổng số bảo hành'), excel_lib.IntCellValue(warranties.length)]);
    intro.appendRow([excel_lib.TextCellValue('Tổng số phương tiện'), excel_lib.IntCellValue(vehicles.length)]);
    intro.appendRow([excel_lib.TextCellValue('Tổng số khách hàng'), excel_lib.IntCellValue(customers.length)]);
    intro.appendRow([excel_lib.TextCellValue('Tổng số phiếu sửa chữa'), excel_lib.IntCellValue(workOrders.length)]);
    intro.appendRow([excel_lib.TextCellValue(''), excel_lib.TextCellValue('')]);
    intro.appendRow([excel_lib.TextCellValue('GHI CHÚ'), excel_lib.TextCellValue('Dữ liệu được xuất tự động từ hệ thống quản lý bảo hành kỹ thuật số Xanh EV. File này có giá trị tham khảo.')]);

    excel_lib.CellStyle? introTitleStyle;
    try {
      introTitleStyle = excel_lib.CellStyle(
        bold: true,
        fontSize: 20,
        fontColorHex: excel_lib.ExcelColor.fromHexString('#1B5E20'),
      );
    } catch (_) {}
    for (var r = 0; r < 6; r++) {
      if (introTitleStyle != null && r >= 2 && r <= 3) {
        intro.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r)).cellStyle = introTitleStyle;
      }
    }
    // Style the report title row (index 5)
    try {
      final reportTitleStyle = excel_lib.CellStyle(
        bold: true,
        fontSize: 16,
        fontColorHex: excel_lib.ExcelColor.fromHexString('#1B5E20'),
      );
      intro.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5)).cellStyle = reportTitleStyle;
    } catch (_) {}

    // =====================================================================
    // SHEET 2: HỒ SƠ BẢO HÀNH
    // =====================================================================
    final warrantySheet = excel['HỒ SƠ BẢO HÀNH'];
    autoWidth(warrantySheet, [5, 28, 15, 15, 12, 10, 15, 15, 14, 25, 14, 12, 10, 10, 14, 25]);

    warrantySheet.appendRow([
      excel_lib.TextCellValue('STT'),
      excel_lib.TextCellValue('Mã bảo hành'),
      excel_lib.TextCellValue('Loại bảo hành'),
      excel_lib.TextCellValue('Ngày bắt đầu'),
      excel_lib.TextCellValue('Ngày hết hạn'),
      excel_lib.TextCellValue('Số ngày\ncòn lại'),
      excel_lib.TextCellValue('Trạng thái'),
      excel_lib.TextCellValue('Điều kiện'),
      excel_lib.TextCellValue('Nơi cấp'),
      excel_lib.TextCellValue('Biển số xe'),
      excel_lib.TextCellValue('Mã VIN'),
      excel_lib.TextCellValue('Hãng'),
      excel_lib.TextCellValue('Model'),
      excel_lib.TextCellValue('Năm SX'),
      excel_lib.TextCellValue('Chủ xe'),
      excel_lib.TextCellValue('SĐT chủ xe'),
    ]);
    int stt = 1;
    for (var w in warranties) {
      final sd = w['startDate'] as String?;
      final ed = w['expiryDate'] as String?;
      DateTime? startD, endD;
      try { startD = DateTime.parse(sd!); } catch (_) {}
      try { endD = DateTime.parse(ed!); } catch (_) {}
      final ys = DateTime(year, 1, 1);
      final ye = DateTime(year, 12, 31, 23, 59, 59);
      bool inRange = false;
      if (startD != null && endD != null) {
        inRange = startD.isBefore(ye) && endD.isAfter(ys);
      } else if (startD != null) {
        inRange = startD.year == year;
      } else if (endD != null) {
        inRange = endD.year == year;
      }
      if (!inRange) continue;

      final v = w['vehicle'] as Map<String, dynamic>?;
      final owner = v?['owner'] as Map<String, dynamic>?;
      warrantySheet.appendRow([
        excel_lib.IntCellValue(stt++),
        excel_lib.TextCellValue(w['id']?.toString() ?? ''),
        excel_lib.TextCellValue(w['warrantyType']?.toString() ?? ''),
        excel_lib.TextCellValue(_fmtDate(sd)),
        excel_lib.TextCellValue(_fmtDate(ed)),
        excel_lib.IntCellValue(w['daysRemaining'] as int? ?? 0),
        excel_lib.TextCellValue(_statusText(w['status'])),
        excel_lib.TextCellValue(w['terms']?.toString() ?? ''),
        excel_lib.TextCellValue(w['issuedBy']?.toString() ?? ''),
        excel_lib.TextCellValue(v?['licensePlate']?.toString() ?? ''),
        excel_lib.TextCellValue(v?['vin']?.toString() ?? ''),
        excel_lib.TextCellValue(v?['brand']?.toString() ?? ''),
        excel_lib.TextCellValue(v?['model']?.toString() ?? ''),
        excel_lib.IntCellValue(v?['manufactureYear'] as int? ?? 0),
        excel_lib.TextCellValue(owner?['fullName']?.toString() ?? ''),
        excel_lib.TextCellValue(owner?['phone']?.toString() ?? ''),
      ]);
    }
    applyHeaderStyle(warrantySheet);
    if (stt == 1) warrantySheet.appendRow([excel_lib.TextCellValue(''), excel_lib.TextCellValue('Không có dữ liệu bảo hành trong năm $year')]);

    // =====================================================================
    // SHEET 3: PHƯƠNG TIỆN
    // =====================================================================
    final vehicleSheet = excel['PHƯƠNG TIỆN'];
    autoWidth(vehicleSheet, [5, 15, 20, 12, 10, 10, 10, 10, 25, 15, 10]);

    vehicleSheet.appendRow([
      excel_lib.TextCellValue('STT'),
      excel_lib.TextCellValue('Biển số'),
      excel_lib.TextCellValue('Mã VIN'),
      excel_lib.TextCellValue('Hãng'),
      excel_lib.TextCellValue('Model'),
      excel_lib.TextCellValue('Màu sắc'),
      excel_lib.TextCellValue('Năm SX'),
      excel_lib.TextCellValue('Số KM'),
      excel_lib.TextCellValue('Chủ xe'),
      excel_lib.TextCellValue('SĐT'),
      excel_lib.TextCellValue('Email'),
    ]);
    stt = 1;
    for (var v in vehicles) {
      final o = v['owner'] as Map<String, dynamic>?;
      vehicleSheet.appendRow([
        excel_lib.IntCellValue(stt++),
        excel_lib.TextCellValue(v['licensePlate']?.toString() ?? ''),
        excel_lib.TextCellValue(v['vin']?.toString() ?? ''),
        excel_lib.TextCellValue(v['brand']?.toString() ?? ''),
        excel_lib.TextCellValue(v['model']?.toString() ?? ''),
        excel_lib.TextCellValue(v['color']?.toString() ?? ''),
        excel_lib.IntCellValue(v['manufactureYear'] as int? ?? 0),
        excel_lib.IntCellValue(v['currentKm'] as int? ?? 0),
        excel_lib.TextCellValue(o?['fullName']?.toString() ?? o?['name']?.toString() ?? ''),
        excel_lib.TextCellValue(o?['phone']?.toString() ?? ''),
        excel_lib.TextCellValue(o?['email']?.toString() ?? ''),
      ]);
    }
    applyHeaderStyle(vehicleSheet);
    if (stt == 1) vehicleSheet.appendRow([excel_lib.TextCellValue(''), excel_lib.TextCellValue('Không có dữ liệu phương tiện')]);

    // =====================================================================
    // SHEET 4: KHÁCH HÀNG
    // =====================================================================
    final customerSheet = excel['KHÁCH HÀNG'];
    autoWidth(customerSheet, [5, 25, 30, 15, 30, 15]);

    customerSheet.appendRow([
      excel_lib.TextCellValue('STT'),
      excel_lib.TextCellValue('Họ tên'),
      excel_lib.TextCellValue('Email'),
      excel_lib.TextCellValue('Số điện thoại'),
      excel_lib.TextCellValue('Địa chỉ'),
      excel_lib.TextCellValue('Ngày tạo'),
    ]);
    stt = 1;
    for (var c in customers) {
      customerSheet.appendRow([
        excel_lib.IntCellValue(stt++),
        excel_lib.TextCellValue(c['fullName']?.toString() ?? c['name']?.toString() ?? ''),
        excel_lib.TextCellValue(c['email']?.toString() ?? ''),
        excel_lib.TextCellValue(c['phone']?.toString() ?? ''),
        excel_lib.TextCellValue(c['address']?.toString() ?? ''),
        excel_lib.TextCellValue(_fmtDate(c['createdAt'])),
      ]);
    }
    applyHeaderStyle(customerSheet);
    if (stt == 1) customerSheet.appendRow([excel_lib.TextCellValue(''), excel_lib.TextCellValue('Không có dữ liệu khách hàng')]);

    // =====================================================================
    // SHEET 5: PHIẾU SỬA CHỮA
    // =====================================================================
    final woSheet = excel['PHIẾU SỬA CHỮA'];
    autoWidth(woSheet, [5, 20, 15, 22, 22, 14, 18, 15, 15]);

    woSheet.appendRow([
      excel_lib.TextCellValue('STT'),
      excel_lib.TextCellValue('Mã phiếu'),
      excel_lib.TextCellValue('Biển số xe'),
      excel_lib.TextCellValue('Khách hàng'),
      excel_lib.TextCellValue('Kỹ thuật viên'),
      excel_lib.TextCellValue('Trạng thái'),
      excel_lib.TextCellValue('Tổng tiền (VNĐ)'),
      excel_lib.TextCellValue('Ngày tạo'),
      excel_lib.TextCellValue('Ngày hoàn thành'),
    ]);
    stt = 1;
    for (var wo in workOrders) {
      final v = wo['vehicle'] as Map<String, dynamic>?;
      final cust = wo['customer'] as Map<String, dynamic>?;
      final tech = wo['technician'] as Map<String, dynamic>?;
      final cDate = wo['createdAt'] ?? wo['createdDate'];
      final fDate = wo['completedAt'] ?? wo['completedDate'];

      double calcTotal(List<dynamic> items, String priceKey, double qtyMul) {
        return items.fold<double>(0, (sum, item) {
          final qty = qtyMul > 0 ? ((item['quantity'] as num?)?.toDouble() ?? 1) : 1;
          return sum + ((item[priceKey] as num?)?.toDouble() ?? 0) * qty;
        });
      }

      final svcs = wo['services'] as List<dynamic>? ?? [];
      final prts = wo['partsUsed'] as List<dynamic>? ?? [];
      final calcTotalFromItems = calcTotal(svcs, 'price', 0)
          + calcTotal(prts, 'unitPrice', 1);

      final total = (wo['totalPrice'] as num?)?.toDouble()
          ?? (wo['total'] as num?)?.toDouble()
          ?? (wo['totalCost'] as num?)?.toDouble()
          ?? calcTotalFromItems;
      woSheet.appendRow([
        excel_lib.IntCellValue(stt++),
        excel_lib.TextCellValue(wo['id']?.toString() ?? ''),
        excel_lib.TextCellValue(v?['licensePlate']?.toString() ?? ''),
        excel_lib.TextCellValue(cust?['fullName']?.toString() ?? cust?['name']?.toString() ?? ''),
        excel_lib.TextCellValue(tech?['fullName']?.toString() ?? tech?['name']?.toString() ?? ''),
        excel_lib.TextCellValue(_statusText(wo['status'])),
        excel_lib.DoubleCellValue(total),
        excel_lib.TextCellValue(_fmtDate(cDate)),
        excel_lib.TextCellValue(_fmtDate(fDate)),
      ]);
    }
    applyHeaderStyle(woSheet);
    if (stt == 1) woSheet.appendRow([excel_lib.TextCellValue(''), excel_lib.TextCellValue('Không có dữ liệu phiếu sửa chữa')]);

    // =====================================================================
    // SHEET 6: LỊCH SỬ DỊCH VỤ
    // =====================================================================
    final svcSheet = excel['LỊCH SỬ DỊCH VỤ'];
    autoWidth(svcSheet, [5, 22, 15, 12, 35, 8, 14, 18, 15]);

    svcSheet.appendRow([
      excel_lib.TextCellValue('STT'),
      excel_lib.TextCellValue('Mã phiếu'),
      excel_lib.TextCellValue('Biển số xe'),
      excel_lib.TextCellValue('Loại'),
      excel_lib.TextCellValue('Tên dịch vụ / phụ tùng'),
      excel_lib.TextCellValue('SL'),
      excel_lib.TextCellValue('Đơn giá (VNĐ)'),
      excel_lib.TextCellValue('Thành tiền (VNĐ)'),
      excel_lib.TextCellValue('Ngày thực hiện'),
    ]);
    int rowIdx = 1;
    final details = data['serviceDetails'] as List<Map<String, dynamic>>? ?? [];
    for (var entry in details) {
      final rows = entry['rows'] as List<Map<String, String>>? ?? [];
      for (var r in rows) {
        svcSheet.appendRow([
          excel_lib.IntCellValue(rowIdx++),
          excel_lib.TextCellValue(r['woId'] ?? ''),
          excel_lib.TextCellValue(r['licensePlate'] ?? ''),
          excel_lib.TextCellValue(r['type'] ?? ''),
          excel_lib.TextCellValue(r['name'] ?? ''),
          excel_lib.IntCellValue(int.tryParse(r['qty'] ?? '0') ?? 0),
          excel_lib.DoubleCellValue(double.tryParse(r['price'] ?? '0') ?? 0),
          excel_lib.DoubleCellValue(double.tryParse(r['total'] ?? '0') ?? 0),
          excel_lib.TextCellValue(r['date'] ?? ''),
        ]);
      }
    }
    applyHeaderStyle(svcSheet);
    if (rowIdx == 1) svcSheet.appendRow([excel_lib.TextCellValue(''), excel_lib.TextCellValue('Không có dữ liệu dịch vụ')]);

    try { excel.delete('Sheet1'); } catch (_) {}

    final fileBytes = excel.encode();
    if (fileBytes == null) {
      throw Exception('Không thể tạo file Excel');
    }
    return Uint8List.fromList(fileBytes);
  }

  void _showSaveSuccessDialog(String filePath) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF059669)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Xuất dữ liệu thành công',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dữ liệu năm $_selectedYear đã được lưu thành công (6 sheet: GIỚI THIỆU, HỒ SƠ BẢO HÀNH, PHƯƠNG TIỆN, KHÁCH HÀNG, PHIẾU SỬA CHỮA, LỊCH SỬ DỊCH VỤ).',
              style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      filePath,
                      style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Đóng',
              style: TextStyle(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Đã hiểu', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Lỗi xuất dữ liệu', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
        content: Text(
          'Không thể xuất dữ liệu. Vui lòng thử lại sau.\n\nChi tiết: $error',
          style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

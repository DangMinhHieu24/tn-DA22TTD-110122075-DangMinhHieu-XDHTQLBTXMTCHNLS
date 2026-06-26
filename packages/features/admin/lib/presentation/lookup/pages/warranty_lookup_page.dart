import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:core/core.dart';
import '../../../data/repositories/vehicle_intake_repository.dart';
import '../../../data/models/vehicle_model.dart';
import '../../warranty/admin_vehicle_warranty_page.dart';

class WarrantyLookupPage extends StatefulWidget {
  const WarrantyLookupPage({super.key});

  @override
  State<WarrantyLookupPage> createState() => _WarrantyLookupPageState();
}

class _InvoiceDateFormatter {
  static String formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

class _WarrantyLookupPageState extends State<WarrantyLookupPage> {
  late final WarrantyService _warrantyService;
  final _searchCtrl = TextEditingController();
  
  List<WarrantyModel> _allWarranties = [];
  List<WarrantyModel> _filteredWarranties = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _statusFilter = 'ALL'; // ALL, ACTIVE, EXPIRING_SOON, EXPIRED

  @override
  void initState() {
    super.initState();
    _warrantyService = GetIt.instance<WarrantyService>();
    _loadAllWarranties();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAllWarranties() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _warrantyService.getAllWarranties();
      setState(() {
        _allWarranties = list;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    final query = _searchCtrl.text.trim().toLowerCase();
    
    setState(() {
      _filteredWarranties = _allWarranties.where((w) {
        // 1. Filter by Status
        if (_statusFilter == 'ACTIVE' && w.status != WarrantyStatus.active) {
          return false;
        }
        if (_statusFilter == 'EXPIRING_SOON' && w.status != WarrantyStatus.expiringSoon) {
          return false;
        }
        if (_statusFilter == 'EXPIRED' && w.status != WarrantyStatus.expired) {
          return false;
        }

        // 2. Filter by Search Query
        if (query.isEmpty) return true;

        final type = w.warrantyType.toLowerCase();
        final plate = (w.vehicle?['licensePlate'] as String? ?? '').toLowerCase();
        final model = (w.vehicle?['model'] as String? ?? '').toLowerCase();
        final ownerName = (w.vehicle?['owner']?['name'] as String? ?? '').toLowerCase();
        final ownerPhone = (w.vehicle?['owner']?['phoneNumber'] as String? ?? '').toLowerCase();

        return type.contains(query) ||
            plate.contains(query) ||
            model.contains(query) ||
            ownerName.contains(query) ||
            ownerPhone.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF191C1E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tra cứu bảo hành',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF191C1E),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF006E2F)),
            onPressed: _loadAllWarranties,
            tooltip: 'Làm mới',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(115),
          child: Column(
            children: [
              // Search input
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => _applyFilters(),
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo biển số, dòng xe, tên khách, SĐT...',
                    hintStyle: const TextStyle(color: Color(0xFF9DA3A8), fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6D7B6C)),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _applyFilters();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF2F4F6),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              // Filter chips
              _buildFilterBar(),
            ],
          ),
        ),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddWarrantyBottomSheet(context),
        backgroundColor: const Color(0xFF006E2F),
        icon: const Icon(Icons.verified_user, color: Colors.white),
        label: const Text(
          'Tạo bảo hành',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('Tất cả', 'ALL'),
          _buildFilterChip('Còn hạn', 'ACTIVE'),
          _buildFilterChip('Sắp hết hạn', 'EXPIRING_SOON'),
          _buildFilterChip('Hết hạn', 'EXPIRED'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    
    // Get count for each filter
    int count = 0;
    if (value == 'ALL') {
      count = _allWarranties.length;
    } else if (value == 'ACTIVE') {
      count = _allWarranties.where((w) => w.status == WarrantyStatus.active).length;
    } else if (value == 'EXPIRING_SOON') {
      count = _allWarranties.where((w) => w.status == WarrantyStatus.expiringSoon).length;
    } else if (value == 'EXPIRED') {
      count = _allWarranties.where((w) => w.status == WarrantyStatus.expired).length;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF3D4A3D),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFE5E8EA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF6D7B6C),
                ),
              ),
            ),
          ],
        ),
        selected: isSelected,
        selectedColor: const Color(0xFF006E2F),
        backgroundColor: const Color(0xFFF2F4F6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _statusFilter = value;
            });
            _applyFilters();
          }
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006E2F)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFBA1A1A), size: 54),
              const SizedBox(height: 16),
              Text(
                'Lỗi: $_errorMessage',
                style: const TextStyle(color: Color(0xFFBA1A1A)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadAllWarranties,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006E2F),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredWarranties.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_outlined, size: 72, color: const Color(0xFFDAE4DC)),
            const SizedBox(height: 16),
            const Text(
              'Không tìm thấy bảo hành nào',
              style: TextStyle(fontSize: 15, color: Color(0xFF6D7B6C), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: _filteredWarranties.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _buildWarrantyCard(_filteredWarranties[i]),
    );
  }

  Widget _buildWarrantyCard(WarrantyModel w) {
    Color statusColor;
    String statusLabel;
    
    switch (w.status) {
      case WarrantyStatus.active:
        statusColor = const Color(0xFF006E2F);
        statusLabel = 'Còn hạn';
      case WarrantyStatus.expiringSoon:
        statusColor = const Color(0xFFD97706);
        statusLabel = 'Sắp hết hạn';
      case WarrantyStatus.expired:
        statusColor = const Color(0xFFBA1A1A);
        statusLabel = 'Hết hạn';
    }

    final plate = w.vehicle?['licensePlate'] as String? ?? 'Chưa rõ';
    final model = w.vehicle?['model'] as String? ?? 'Chưa rõ';
    final ownerName = w.vehicle?['owner']?['name'] as String? ?? '—';
    final ownerPhone = w.vehicle?['owner']?['phoneNumber'] as String? ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E5EA), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF191C1E).withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminVehicleWarrantyPage(
                  vehicleId: w.vehicleId,
                  licensePlate: plate,
                ),
              ),
            ).then((_) => _loadAllWarranties());
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (License plate + Status badge)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F4F6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFDAE4DC)),
                      ),
                      child: Text(
                        plate,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF191C1E),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Warranty type name
                Text(
                  w.warrantyType,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF191C1E),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 10),
                // Info grid
                Row(
                  children: [
                    const Icon(Icons.two_wheeler_outlined, size: 16, color: Color(0xFF6D7B6C)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        model,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF3D4A3D)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF6D7B6C)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$ownerName ${ownerPhone.isNotEmpty ? "($ownerPhone)" : ""}',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF3D4A3D)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF0F2F4)),
                const SizedBox(height: 12),
                // Footer (Time frame + remaining indicator)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_InvoiceDateFormatter.formatDate(w.startDate)} - ${_InvoiceDateFormatter.formatDate(w.expiryDate)}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF9DA3A8)),
                    ),
                    Text(
                      w.status == WarrantyStatus.expired
                          ? 'Đã hết hạn ${w.daysRemaining.abs()} ngày'
                          : 'Còn ${w.daysRemaining} ngày',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddWarrantyBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddWarrantySheet(
        vehicleIntakeRepository: GetIt.instance<VehicleIntakeRepository>(),
        warrantyService: _warrantyService,
        onSuccess: () {
          _loadAllWarranties();
        },
      ),
    );
  }
}

class _AddWarrantySheet extends StatefulWidget {
  final VehicleIntakeRepository vehicleIntakeRepository;
  final WarrantyService warrantyService;
  final VoidCallback onSuccess;

  const _AddWarrantySheet({
    required this.vehicleIntakeRepository,
    required this.warrantyService,
    required this.onSuccess,
  });

  @override
  State<_AddWarrantySheet> createState() => _AddWarrantySheetState();
}

class _AddWarrantySheetState extends State<_AddWarrantySheet> {
  final _formKey = GlobalKey<FormState>();
  final _plateCtrl = TextEditingController();
  final _typeCtrl = TextEditingController();
  final _termsCtrl = TextEditingController();
  final _issuedByCtrl = TextEditingController(text: 'Xanh EV Garage');

  bool _isCheckingVehicle = false;
  bool _isSaving = false;
  String? _checkError;
  VehicleModel? _matchedVehicle;
  
  DateTime _startDate = DateTime.now();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));

  @override
  void dispose() {
    _plateCtrl.dispose();
    _typeCtrl.dispose();
    _termsCtrl.dispose();
    _issuedByCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkVehicle() async {
    final plate = _plateCtrl.text.trim();
    if (plate.isEmpty) return;

    setState(() {
      _isCheckingVehicle = true;
      _checkError = null;
      _matchedVehicle = null;
    });

    try {
      final v = await widget.vehicleIntakeRepository.searchVehicle(plate);
      setState(() {
        _isCheckingVehicle = false;
        if (v != null) {
          _matchedVehicle = v;
        } else {
          _checkError = 'Không tìm thấy xe với biển số này!';
        }
      });
    } catch (e) {
      setState(() {
        _isCheckingVehicle = false;
        _checkError = 'Lỗi tra cứu: $e';
      });
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF006E2F),
            onPrimary: Colors.white,
            onSurface: Color(0xFF191C1E),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_expiryDate.isBefore(_startDate)) {
          _expiryDate = _startDate.add(const Duration(days: 365));
        }
      });
    }
  }

  Future<void> _selectExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: _startDate.add(const Duration(days: 1)),
      lastDate: _startDate.add(const Duration(days: 3650)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF006E2F),
            onPrimary: Colors.white,
            onSurface: Color(0xFF191C1E),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _matchedVehicle == null) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await widget.warrantyService.createWarranty(
        vehicleId: _matchedVehicle!.id,
        warrantyType: _typeCtrl.text.trim(),
        startDate: _startDate,
        expiryDate: _expiryDate,
        terms: _termsCtrl.text.trim().isNotEmpty ? _termsCtrl.text.trim() : null,
        issuedBy: _issuedByCtrl.text.trim().isNotEmpty ? _issuedByCtrl.text.trim() : null,
      );

      if (mounted) {
        widget.onSuccess();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã tạo gói bảo hành xe thành công!'),
            backgroundColor: const Color(0xFF006E2F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tạo bảo hành: $e'),
          backgroundColor: const Color(0xFFBA1A1A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pull bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDAE4DC),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tạo bảo hành xe',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF191C1E)),
              ),
              const SizedBox(height: 20),

              // Biển số xe & Check
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _plateCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Biển số xe *',
                        hintText: 'VD: 29A-123.45',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Nhập biển số' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isCheckingVehicle ? null : _checkVehicle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006E2F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isCheckingVehicle
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Tra cứu'),
                    ),
                  ),
                ],
              ),

              // Matched Vehicle Display or Error
              if (_matchedVehicle != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDCFCE7)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF006E2F), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Xe: ${_matchedVehicle!.brand ?? ""} ${_matchedVehicle!.model} • Chủ xe: ${_matchedVehicle!.ownerName ?? "—"}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF004B1E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_checkError != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0ED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFDAD6)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFBA1A1A), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _checkError!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFBA1A1A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              // Loại bảo hành
              TextFormField(
                controller: _typeCtrl,
                decoration: InputDecoration(
                  labelText: 'Loại bảo hành *',
                  hintText: 'VD: Bảo hành pin, Bảo hành động cơ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Nhập loại bảo hành' : null,
              ),

              const SizedBox(height: 16),
              // Date fields
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectStartDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Ngày bắt đầu',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          _InvoiceDateFormatter.formatDate(_startDate),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: _selectExpiryDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Ngày hết hạn',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          _InvoiceDateFormatter.formatDate(_expiryDate),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              // Điều khoản
              TextFormField(
                controller: _termsCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Điều khoản bảo hành',
                  hintText: 'Nhập nội dung điều khoản nếu có',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              // Đơn vị cấp
              TextFormField(
                controller: _issuedByCtrl,
                decoration: InputDecoration(
                  labelText: 'Đơn vị cấp',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 28),
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_isSaving || _matchedVehicle == null) ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006E2F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Lưu'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

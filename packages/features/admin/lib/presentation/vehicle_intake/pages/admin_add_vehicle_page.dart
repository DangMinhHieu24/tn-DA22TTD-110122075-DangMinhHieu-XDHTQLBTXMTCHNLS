import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:core/core.dart';
import 'package:admin/data/datasources/remote/vehicle_remote_datasource.dart';
import 'package:admin/data/repositories/vehicle_intake_repository.dart';

class AdminAddVehiclePage extends StatefulWidget {
  const AdminAddVehiclePage({super.key});

  @override
  State<AdminAddVehiclePage> createState() => _AdminAddVehiclePageState();
}

class _AdminAddVehiclePageState extends State<AdminAddVehiclePage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _plateController = TextEditingController();
  final _modelController = TextEditingController();
  final _colorController = TextEditingController();
  final _yearController = TextEditingController();
  final _kmController = TextEditingController(text: '0');
  final _customBrandController = TextEditingController();

  // Status state
  bool _isLoadingCustomer = false;
  bool _isSaving = false;
  bool _hasSearched = false;
  bool _customerExists = false;
  String? _resolvedOwnerId;
  String? _selectedBrand;
  File? _vehicleImageFile;

  Future<void> _pickVehicleImage() async {
    final imageService = GetIt.instance<ImageUploadService>();
    
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Chọn ảnh đại diện cho xe',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF006E2F)),
              title: const Text('Chụp ảnh mới', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF006E2F)),
              title: const Text('Chọn từ thư viện', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      File? pickedFile;
      if (source == ImageSource.camera) {
        pickedFile = await imageService.takePhoto();
      } else {
        pickedFile = await imageService.pickImage();
      }

      if (pickedFile != null) {
        setState(() {
          _vehicleImageFile = pickedFile;
        });
      }
    } catch (e) {
      _showSnackBar('Lỗi chọn ảnh: $e', isError: true);
    }
  }

  final List<String> _brands = [
    'VinFast',
    'Yadea',
    'Pega',
    'Honda',
    'Yamaha',
    'Khác'
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && _plateController.text.isEmpty) {
      _plateController.text = args;
    } else if (args is Map<String, dynamic>) {
      final plate = args['plate'];
      final phone = args['phone'];
      if (plate is String && _plateController.text.isEmpty) {
        _plateController.text = plate;
      }
      if (phone is String && _phoneController.text.isEmpty) {
        _phoneController.text = phone;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _lookupCustomer();
        });
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _plateController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    _yearController.dispose();
    _kmController.dispose();
    _customBrandController.dispose();
    super.dispose();
  }

  Future<void> _lookupCustomer() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showSnackBar('Vui lòng nhập số điện thoại để tra cứu', isError: true);
      return;
    }

    setState(() {
      _isLoadingCustomer = true;
      _hasSearched = false;
      _customerExists = false;
      _resolvedOwnerId = null;
    });

    try {
      final dataSource = GetIt.instance<VehicleRemoteDataSource>();
      final customer = await dataSource.getCustomerByPhone(phone);

      if (customer != null) {
        setState(() {
          _customerExists = true;
          _resolvedOwnerId = customer.id;
          _nameController.text = customer.name;
          _hasSearched = true;
        });
        _showSnackBar('Đã tìm thấy khách hàng: ${customer.name}');
      } else {
        setState(() {
          _customerExists = false;
          _resolvedOwnerId = null;
          _nameController.clear();
          _hasSearched = true;
        });
        _showSnackBar('Số điện thoại chưa có trên hệ thống. Nhập tên để tạo mới.');
      }
    } catch (e) {
      _showSnackBar('Lỗi khi tra cứu khách hàng: $e', isError: true);
    } finally {
      setState(() {
        _isLoadingCustomer = false;
      });
    }
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showSnackBar('Vui lòng nhập số điện thoại khách hàng', isError: true);
      return;
    }

    if (!_hasSearched) {
      _showSnackBar('Vui lòng bấm tra cứu số điện thoại trước khi lưu', isError: true);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = GetIt.instance<VehicleIntakeRepository>();
      String ownerId = _resolvedOwnerId ?? '';

      // 1. Register new customer if doesn't exist
      if (!_customerExists) {
        final name = _nameController.text.trim();
        if (name.isEmpty) {
          throw Exception('Vui lòng nhập tên khách hàng mới');
        }
        
        // Call backend registration
        ownerId = await repository.createVehicleOwner(
          name: name,
          phoneNumber: phone,
        );
      }

      // 2. Upload image if present
      String? imageUrl;
      if (_vehicleImageFile != null) {
        final imageService = GetIt.instance<ImageUploadService>();
        final plateStr = _plateController.text.trim().toUpperCase();
        imageUrl = await imageService.uploadImage(
          imageFile: _vehicleImageFile!,
          folder: 'vehicles/$plateStr',
        );
      }

      // 3. Register vehicle details
      final brandName = _selectedBrand == 'Khác' 
          ? _customBrandController.text.trim()
          : (_selectedBrand ?? 'Khác');

      final currentKm = int.tryParse(_kmController.text.trim()) ?? 0;
      final year = int.tryParse(_yearController.text.trim());

      await repository.createVehicle(
        licensePlate: _plateController.text.trim().toUpperCase(),
        ownerId: ownerId,
        brand: brandName,
        model: _modelController.text.trim(),
        color: _colorController.text.trim().isNotEmpty ? _colorController.text.trim() : null,
        manufactureYear: year,
        currentKm: currentKm,
        imageUrl: imageUrl,
      );

      // 3. Show Success and Pop
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      _showSnackBar('Lỗi khi lưu thông tin: ${e.toString().replaceAll('Exception: ', '')}', isError: true);
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        backgroundColor: isError ? const Color(0xFFBA1A1A) : const Color(0xFF006E2F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF006E2F), size: 28),
            SizedBox(width: 8),
            Text(
              'Thành công',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text('Đã thêm xe mới và liên kết với khách hàng thành công!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // pop dialog
              Navigator.of(context).pop(true); // pop add vehicle page
            },
            child: const Text(
              'Xác nhận',
              style: TextStyle(color: Color(0xFF006E2F), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 15,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ),
        title: const Text(
          'Thêm xe mới cho Khách',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── STEP 1: CUSTOMER INFO ──────────────────────────────
                _buildSectionHeader('1', 'Thông tin khách hàng'),
                const SizedBox(height: 12),
                _buildCustomerCard(),
                const SizedBox(height: 24),

                // ── STEP 2: VEHICLE INFO ──────────────────────────────
                _buildSectionHeader('2', 'Thông tin xe máy điện'),
                const SizedBox(height: 12),
                _buildVehicleCard(),
                const SizedBox(height: 36),

                // ── SUBMIT CTA ─────────────────────────────────────────
                _buildSubmitButton(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String index, String title) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF006E2F), Color(0xFF22C55E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF006E2F).withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              index,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phone lookup field
          const Text(
            'SỐ ĐIỆN THOẠI KHÁCH HÀNG *',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    hintText: 'Nhập số điện thoại...',
                    hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8), fontWeight: FontWeight.normal),
                    prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF64748B), size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF006E2F), width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1.5),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Nhập số điện thoại khách';
                    }
                    if (val.trim().length < 9) {
                      return 'Số điện thoại không hợp lệ';
                    }
                    return null;
                  },
                  onChanged: (val) {
                    setState(() {
                      _hasSearched = false;
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _isLoadingCustomer ? null : _lookupCustomer,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  height: 52, // Match input height
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF006E2F), Color(0xFF009844)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF006E2F).withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isLoadingCustomer
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            'Tra cứu',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
          
          if (_hasSearched) ...[
            const SizedBox(height: 18),
            // Lookup message box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _customerExists ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(14),
                border: Border(
                  left: BorderSide(
                    color: _customerExists ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                    width: 4,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _customerExists ? Icons.check_circle_rounded : Icons.info_rounded,
                    color: _customerExists ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _customerExists
                          ? 'Đã tìm thấy khách hàng cũ trên hệ thống.'
                          : 'Số điện thoại mới. Nhập họ tên bên dưới để tạo tài khoản mới.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _customerExists ? const Color(0xFF14532D) : const Color(0xFF78350F),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Customer name field
            const Text(
              'TÊN KHÁCH HÀNG *',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              enabled: !_customerExists, // Disabled if old customer
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _customerExists ? const Color(0xFF64748B) : const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: _customerExists ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
                hintText: 'Nhập họ và tên...',
                hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8), fontWeight: FontWeight.normal),
                prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF64748B), size: 20),
                suffixIcon: _customerExists 
                    ? const Icon(Icons.lock_outline_rounded, color: Color(0xFF94A3B8), size: 18)
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF006E2F), width: 1.5),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Nhập tên khách hàng';
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVehicleCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo picker widget
          Center(
            child: GestureDetector(
              onTap: _pickVehicleImage,
              child: Container(
                width: 160,
                height: 110,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  image: _vehicleImageFile != null
                      ? DecorationImage(
                          image: FileImage(_vehicleImageFile!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _vehicleImageFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF0FDF4),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_a_photo_rounded, 
                              color: Color(0xFF006E2F), 
                              size: 24
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Thêm ảnh xe\n(Không bắt buộc)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11, 
                              color: Color(0xFF64748B), 
                              fontWeight: FontWeight.w600,
                              height: 1.2
                            ),
                          ),
                        ],
                      )
                    : Stack(
                        children: [
                          Positioned(
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _vehicleImageFile = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // License Plate
          const Text(
            'BIỂN SỐ XE *',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _plateController,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              TextInputFormatter.withFunction((oldVal, newVal) {
                return newVal.copyWith(text: newVal.text.toUpperCase());
              })
            ],
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              hintText: 'VD: 29A-123.45',
              hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8), fontWeight: FontWeight.normal),
              prefixIcon: const Icon(Icons.tag_rounded, color: Color(0xFF64748B), size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF006E2F), width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1.5),
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Nhập biển số xe';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),

          // Brand Dropdown
          const Text(
            'HÃNG XE *',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedBrand,
            hint: const Text('Chọn hãng xe', style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8), fontWeight: FontWeight.normal)),
            isExpanded: true,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              prefixIcon: const Icon(Icons.business_rounded, color: Color(0xFF64748B), size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF006E2F), width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1.5),
              ),
            ),
            items: _brands.map((b) => DropdownMenuItem(
              value: b,
              child: Text(b, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            )).toList(),
            onChanged: (val) {
              setState(() {
                _selectedBrand = val;
              });
            },
            validator: (val) => val == null ? 'Chọn hãng xe' : null,
          ),
          
          if (_selectedBrand == 'Khác') ...[
            const SizedBox(height: 18),
            const Text(
              'TÊN HÃNG XE KHÁC *',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _customBrandController,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                hintText: 'Nhập hãng xe mới...',
                hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8), fontWeight: FontWeight.normal),
                prefixIcon: const Icon(Icons.add_business_rounded, color: Color(0xFF64748B), size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF006E2F), width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1.5),
                ),
              ),
              validator: (val) {
                if (_selectedBrand == 'Khác' && (val == null || val.trim().isEmpty)) {
                  return 'Nhập tên hãng xe';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 18),

          // Vehicle Model
          const Text(
            'DÒNG XE (MODEL) *',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _modelController,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              hintText: 'VD: Klara S, Feliz, Evo 200...',
              hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8), fontWeight: FontWeight.normal),
              prefixIcon: const Icon(Icons.motorcycle_rounded, color: Color(0xFF64748B), size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF006E2F), width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1.5),
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Nhập dòng xe';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),

          // Year and Color Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NĂM SẢN XUẤT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _yearController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        hintText: 'VD: 2024',
                        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8), fontWeight: FontWeight.normal),
                        prefixIcon: const Icon(Icons.calendar_today_rounded, color: Color(0xFF64748B), size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF006E2F), width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1.5),
                        ),
                      ),
                      validator: (val) {
                        if (val != null && val.trim().isNotEmpty) {
                          final y = int.tryParse(val.trim());
                          if (y == null || y < 1900 || y > DateTime.now().year + 1) {
                            return 'Năm không hợp lệ';
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MÀU SẮC',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _colorController,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        hintText: 'VD: Đỏ, Trắng...',
                        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8), fontWeight: FontWeight.normal),
                        prefixIcon: const Icon(Icons.palette_rounded, color: Color(0xFF64748B), size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF006E2F), width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Current KM
          const Text(
            'SỐ KM HIỆN TẠI',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _kmController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              hintText: '0',
              prefixIcon: const Icon(Icons.speed_rounded, color: Color(0xFF64748B), size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF006E2F), width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1.5),
              ),
            ),
            validator: (val) {
              if (val != null && val.trim().isNotEmpty) {
                final k = int.tryParse(val.trim());
                if (k == null || k < 0) {
                  return 'Số KM không hợp lệ';
                }
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF006E2F), Color(0xFF009844)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF006E2F).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveVehicle,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : const Text(
                  'LƯU THÔNG TIN XE',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}

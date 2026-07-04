import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:admin/data/datasources/remote/vehicle_remote_datasource.dart';
import 'package:admin/data/repositories/vehicle_intake_repository.dart';

class AdminCreateCustomerPage extends StatefulWidget {
  const AdminCreateCustomerPage({super.key});

  @override
  State<AdminCreateCustomerPage> createState() => _AdminCreateCustomerPageState();
}

class _AdminCreateCustomerPageState extends State<AdminCreateCustomerPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();

  // State flags
  bool _isSaving = false;
  bool _autoPassword = true;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createCustomer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim();

    setState(() {
      _isSaving = true;
    });

    try {
      final vehicleDataSource = GetIt.instance<VehicleRemoteDataSource>();
      final repository = GetIt.instance<VehicleIntakeRepository>();

      // 1. Check if customer already exists
      final existingCustomer = await vehicleDataSource.getCustomerByPhone(phone);
      if (existingCustomer != null) {
        throw Exception('Số điện thoại này đã được đăng ký cho khách hàng: ${existingCustomer.name}');
      }

      // 2. Determine password
      String finalPassword;
      if (_autoPassword) {
        finalPassword = 'AutoPwd${DateTime.now().millisecondsSinceEpoch % 1000000}';
      } else {
        finalPassword = _passwordController.text.trim();
        if (finalPassword.length < 6) {
          throw Exception('Mật khẩu tự chọn phải có ít nhất 6 ký tự');
        }
      }

      // 3. Register user (owner)
      // Since vehicle_intake_repository.dart has createVehicleOwner, let's call the registration
      final sanitizedPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
      final email = 'owner.$sanitizedPhone.${DateTime.now().millisecondsSinceEpoch}@auto.local';

      // We'll call the direct dio registration from repository.
      // But wait! createVehicleOwner in vehicle_intake_repository auto-generates password.
      // Since we want to support custom password if provided, let's call the repository registration but bypass it if we want custom password, or call registration via repository but pass the custom password?
      // Wait, let's see how repository.createVehicleOwner is implemented:
      // It auto-generates password internally and doesn't take email/password as parameter!
      // But wait, can we register directly using dio from repository, or modify createVehicleOwner to accept optional password?
      // Wait! Let's check repository.createVehicleOwner again:
      // ```dart
      //   Future<String> createVehicleOwner({
      //     required String name,
      //     required String phoneNumber,
      //   })
      // ```
      // It doesn't accept password parameter.
      // So if the user wants custom password, can we add email/password as optional parameters to createVehicleOwner?
      // YES! That is extremely clean and avoids duplication!
      // Let's first design the UI, and if we need to customize createVehicleOwner, we can modify it.
      // Let's implement registration directly using repository's createVehicleOwner but if they provided custom email/password we can modify createVehicleOwner to accept optional email/password!
      // Let's look at how we can modify createVehicleOwner:
      // ```dart
      //   Future<String> createVehicleOwner({
      //     required String name,
      //     required String phoneNumber,
      //     String? email,
      //     String? password,
      //   })
      // ```
      // This is perfectly backwards-compatible and simple!
      
      await repository.createVehicleOwner(
        name: name,
        phoneNumber: phone,
        email: email,
        password: finalPassword,
      );

      if (mounted) {
        _showSuccessDialog(name, phone, finalPassword);
      }
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
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

  void _showSuccessDialog(String name, String phone, String password) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tài khoản khách hàng đã được khởi tạo thành công!',
              style: TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dialogInfoRow('Họ và tên:', name),
                  const SizedBox(height: 8),
                  _dialogInfoRow('Số điện thoại:', phone),
                  const SizedBox(height: 8),
                  _dialogInfoRow('Mật khẩu:', password, isSelectable: true),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '* Hãy báo thông tin SĐT và mật khẩu trên cho khách hàng để họ đăng nhập vào ứng dụng.',
              style: TextStyle(fontSize: 11, color: Color(0xFFE28B00), fontWeight: FontWeight.w600, height: 1.3),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // pop dialog
              Navigator.of(context).pop(); // pop create customer page
            },
            child: const Text(
              'Hoàn tất',
              style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // pop dialog
              Navigator.of(context).pop(); // pop create customer page
              Navigator.of(context).pushNamed(
                '/admin/add-vehicle',
                arguments: {'phone': phone},
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006E2F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Thêm xe ngay',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogInfoRow(String label, String value, {bool isSelectable = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5),
        ),
        const SizedBox(height: 2),
        isSelectable
            ? SelectableText(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: 0.5),
              )
            : Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
      ],
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
          'Tạo tài khoản Khách',
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
                _buildFormCard(),
                const SizedBox(height: 36),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
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
          // Header title
          const Row(
            children: [
              Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF006E2F), size: 24),
              SizedBox(width: 10),
              Text(
                'Tài khoản mới',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 20),

          // SĐT Field
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
          TextFormField(
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
          ),
          const SizedBox(height: 18),

          // Tên khách hàng Field
          const Text(
            'HỌ VÀ TÊN KHÁCH HÀNG *',
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
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              hintText: 'Nhập họ và tên...',
              hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8), fontWeight: FontWeight.normal),
              prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF64748B), size: 20),
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
                return 'Nhập họ và tên';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Auto password switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MẬT KHẨU TỰ ĐỘNG',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Hệ thống tự tạo mật khẩu an toàn',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              Switch(
                value: _autoPassword,
                onChanged: (val) {
                  setState(() {
                    _autoPassword = val;
                  });
                },
                activeThumbColor: const Color(0xFF006E2F),
              ),
            ],
          ),

          if (!_autoPassword) ...[
            const SizedBox(height: 18),
            // Custom Password field
            const Text(
              'MẬT KHẨU TỰ CHỌN (TỐI THIỂU 6 KÝ TỰ) *',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: 0.5),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                hintText: 'Nhập mật khẩu...',
                hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8), fontWeight: FontWeight.normal, letterSpacing: 0),
                prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF64748B), size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: const Color(0xFF64748B),
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
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
                if (!_autoPassword && (val == null || val.trim().isEmpty)) {
                  return 'Nhập mật khẩu tự chọn';
                }
                if (!_autoPassword && val!.trim().length < 6) {
                  return 'Mật khẩu phải có ít nhất 6 ký tự';
                }
                return null;
              },
            ),
          ],
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
          onPressed: _isSaving ? null : _createCustomer,
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
                  'ĐĂNG KÝ TÀI KHOẢN',
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

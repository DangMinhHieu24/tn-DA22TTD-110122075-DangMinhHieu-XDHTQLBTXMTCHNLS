import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  bool _isEditing = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    String name = '';
    String phone = '';
    String email = '';

    if (authState is AuthAuthenticated) {
      name = authState.user.name;
      phone = authState.user.phoneNumber ?? '';
      email = authState.user.email;
    }

    _nameController = TextEditingController(text: name);
    _phoneController = TextEditingController(text: phone);
    _emailController = TextEditingController(text: email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      final userId = authState.user.id;
      final dio = GetIt.instance<Dio>();

      final response = await dio.put(
        '/users/$userId',
        data: {
          'name': _nameController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
        },
      );

      if (response.data['success'] == true) {
        final updatedUserModel = UserModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );

        // Save updated user data locally
        await GetIt.instance<AuthLocalDataSource>().saveUser(updatedUserModel);

        // Update AuthBloc state globally
        if (mounted) {
          context.read<AuthBloc>().add(AuthUserUpdated(user: updatedUserModel));
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Cập nhật thông tin thành công'),
                ],
              ),
              backgroundColor: const Color(0xFF006E2F),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );

          setState(() {
            _isEditing = false;
            _isSaving = false;
          });
        }
      } else {
        throw Exception(response.data['message'] ?? 'Không thể cập nhật thông tin');
      }
    } on DioException catch (e) {
      String msg = 'Đã xảy ra lỗi kết nối';
      if (e.response != null && e.response?.data is Map) {
        msg = e.response?.data['message'] ?? e.response?.data['error'] ?? msg;
      } else if (e.message != null) {
        msg = e.message!;
      }
      setState(() {
        _isSaving = false;
        _errorMessage = msg;
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Scaffold(
            body: Center(
              child: Text('Vui lòng đăng nhập lại để xem thông tin'),
            ),
          );
        }

        final user = authState.user;
        final userInitial = user.name.isNotEmpty ? user.name[0].toUpperCase() : 'T';

        return Scaffold(
          backgroundColor: AppColors.surfaceContainerLow,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF191C1E)),
            ),
            title: const Text(
              'Thông tin cá nhân',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF191C1E),
              ),
            ),
            centerTitle: true,
            actions: [
              if (!_isEditing)
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                      _nameController.text = user.name;
                      _phoneController.text = user.phoneNumber ?? '';
                      _emailController.text = user.email;
                    });
                  },
                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF006E2F)),
                ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: const Color(0xFFE5E7EB),
              ),
            ),
          ),
          body: Stack(
            children: [
              Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    children: [
                      // Profile Avatar
                      Center(
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF006E2F), Color(0xFF059669)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF006E2F),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              userInitial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF191C1E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFFB91C1C),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Personal Information Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Thông tin chung',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF191C1E),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Name field
                            _buildField(
                              label: 'Họ và tên',
                              icon: Icons.person_outline_rounded,
                              controller: _nameController,
                              isEditable: _isEditing,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Họ tên không được để trống';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Phone Number field
                            _buildField(
                              label: 'Số điện thoại',
                              icon: Icons.phone_android_outlined,
                              controller: _phoneController,
                              isEditable: _isEditing,
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Số điện thoại không được để trống';
                                }
                                if (!RegExp(r'^[0-9+]{9,15}$').hasMatch(value.trim())) {
                                  return 'Số điện thoại không hợp lệ';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Email field
                            _buildField(
                              label: 'Địa chỉ Email',
                              icon: Icons.mail_outline_rounded,
                              controller: _emailController,
                              isEditable: _isEditing,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Email không được để trống';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                                  return 'Email không hợp lệ';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // System Settings Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hệ thống & Tổ chức',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF191C1E),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Role Info
                            _buildReadOnlyRow(
                              label: 'Vai trò',
                              value: 'Kỹ thuật viên Xanh EV',
                              icon: Icons.badge_outlined,
                            ),
                            const Divider(height: 24, color: Color(0xFFF3F4F6)),

                            // Workshop Info
                            _buildReadOnlyRow(
                              label: 'Xưởng làm việc',
                              value: 'Trạm dịch vụ Xanh EV - Chi nhánh 1',
                              icon: Icons.business_outlined,
                              isLock: true,
                            ),
                          ],
                        ),
                      ),

                      if (_isEditing) ...[
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _isEditing = false;
                                    _errorMessage = null;
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                                  foregroundColor: const Color(0xFF6B7280),
                                ),
                                child: const Text(
                                  'Hủy bỏ',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF006E2F),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Lưu lại',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
              if (_isSaving)
                Container(
                  color: Colors.black.withValues(alpha: 0.25),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF006E2F),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required bool isEditable,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    if (!isEditable) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF6B7280), size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  controller.text.isNotEmpty ? controller.text : 'Chưa cập nhật',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF191C1E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF191C1E),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF006E2F), size: 18),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF006E2F), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
      ),
    );
  }

  Widget _buildReadOnlyRow({
    required String label,
    required String value,
    required IconData icon,
    bool isLock = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFFF3F4F6),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF6B7280), size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF191C1E),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (isLock)
          const Tooltip(
            message: 'Thông tin hệ thống, liên hệ Admin để thay đổi',
            child: Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFF9CA3AF),
              size: 16,
            ),
          ),
      ],
    );
  }
}

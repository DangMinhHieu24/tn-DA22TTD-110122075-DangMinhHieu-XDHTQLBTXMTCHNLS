import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:design_system/design_system.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _oldPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final dio = GetIt.instance<Dio>();
      final response = await dio.post(
        '/auth/change-password',
        data: {
          'oldPassword': _oldPasswordCtrl.text,
          'newPassword': _newPasswordCtrl.text,
        },
      );

      if (response.data['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 8),
                Text(response.data['message'] ?? 'Đổi mật khẩu thành công'),
              ],
            ),
            backgroundColor: const Color(0xFF006E2F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      String errorMessage = 'Đã xảy ra lỗi khi đổi mật khẩu';
      
      if (e is DioException) {
        if (e.response != null && e.response!.data != null) {
          errorMessage = e.response!.data['message'] ?? errorMessage;
        } else {
          errorMessage = 'Lỗi kết nối mạng, vui lòng thử lại sau';
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(errorMessage)),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Đổi mật khẩu',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cập nhật mật khẩu mới',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mật khẩu mới của bạn phải có ít nhất 6 ký tự để bảo vệ tài khoản quản trị.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                
                AppTextField(
                  label: 'Mật khẩu hiện tại',
                  placeholder: 'Nhập mật khẩu hiện tại',
                  icon: Icons.lock_outline_rounded,
                  obscureText: true,
                  controller: _oldPasswordCtrl,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập mật khẩu hiện tại';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                AppTextField(
                  label: 'Mật khẩu mới',
                  placeholder: 'Nhập mật khẩu mới (ít nhất 6 ký tự)',
                  icon: Icons.lock_open_rounded,
                  obscureText: true,
                  controller: _newPasswordCtrl,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập mật khẩu mới';
                    }
                    if (value.trim().length < 6) {
                      return 'Mật khẩu mới phải có ít nhất 6 ký tự';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                AppTextField(
                  label: 'Xác nhận mật khẩu mới',
                  placeholder: 'Nhập lại mật khẩu mới',
                  icon: Icons.lock_reset_rounded,
                  obscureText: true,
                  controller: _confirmPasswordCtrl,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng xác nhận mật khẩu mới';
                    }
                    if (value != _newPasswordCtrl.text) {
                      return 'Mật khẩu xác nhận không khớp';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                
                AppButton(
                  text: 'Đổi mật khẩu',
                  onPressed: _submit,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

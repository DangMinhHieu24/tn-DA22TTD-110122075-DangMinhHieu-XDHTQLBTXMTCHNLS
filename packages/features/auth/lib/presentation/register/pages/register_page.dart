import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import '../../../domain/entities/user.dart';
import '../bloc/register_bloc.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  String _passwordStrength = '';
  Color _passwordStrengthColor = AppColors.onSurfaceVariant;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPasswordStrength);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength() {
    final password = _passwordController.text;
    
    if (password.isEmpty) {
      setState(() {
        _passwordStrength = '';
        _passwordStrengthColor = AppColors.onSurfaceVariant;
      });
      return;
    }

    int strength = 0;
    
    // Độ dài >= 8
    if (password.length >= 8) strength++;
    
    // Có chữ hoa
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    
    // Có chữ thường
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    
    // Có số
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    
    // Có ký tự đặc biệt
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    setState(() {
      if (strength <= 2) {
        _passwordStrength = 'Yếu';
        _passwordStrengthColor = AppColors.error;
      } else if (strength <= 3) {
        _passwordStrength = 'Trung bình';
        _passwordStrengthColor = const Color(0xFFF59E0B); // amber-500
      } else {
        _passwordStrength = 'Mạnh';
        _passwordStrengthColor = AppColors.primary;
      }
    });
  }

  void _handleRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<RegisterBloc>().add(
            RegisterSubmitted(
              name: _nameController.text.trim(),
              phoneNumber: _phoneController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
              confirmPassword: _confirmPasswordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF0FDF4),
              Color(0xFFE0F2FE),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.5,
                height: MediaQuery.of(context).size.height * 0.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.5,
                height: MediaQuery.of(context).size.height * 0.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withOpacity(0.05),
                ),
              ),
            ),
            
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildRegisterCard(),
                          const SizedBox(height: 40),
                          _buildFooter(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          const Icon(
            Icons.eco,
            color: Color(0xFF15803D),
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            'Năng Lượng Sạch',
            style: AppTextStyles.titleMedium.copyWith(
              color: const Color(0xFF166534),
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 448),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 64,
            offset: const Offset(0, 32),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Container(
              height: 6,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryContainer],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 32, 32, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildBrandIdentity(),
                    const SizedBox(height: 32),
                    _buildRegisterForm(),
                    const SizedBox(height: 32),
                    _buildDivider(),
                    const SizedBox(height: 20),
                    _buildGoogleButton(),
                    const SizedBox(height: 32),
                    _buildLoginPrompt(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandIdentity() {
    return Column(
      children: [
        Text(
          'Tạo tài khoản',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            fontSize: 32,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Đăng ký để sử dụng hệ thống',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return BlocConsumer<RegisterBloc, RegisterState>(
      listener: (context, state) {
        if (state is RegisterSuccess) {
          // Navigate to appropriate dashboard based on role
          final route = _getDashboardRoute(state.user.role);
          Navigator.of(context).pushNamedAndRemoveUntil(
            route,
            (route) => false,
          );
        } else if (state is RegisterFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is RegisterLoading;

        return Column(
          children: [
            AppTextField(
              label: 'Họ và tên',
              placeholder: 'Nhập họ và tên',
              icon: Icons.person_outline,
              controller: _nameController,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Vui lòng nhập họ và tên';
                }
                return null;
              },
              suffixIcon: const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Số điện thoại',
              placeholder: 'Nhập số điện thoại',
              icon: Icons.phone_outlined,
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Vui lòng nhập số điện thoại';
                }
                return null;
              },
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Mã OTP sẽ được gửi đến số điện thoại của bạn',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Email',
              placeholder: 'Nhập địa chỉ email',
              icon: Icons.email_outlined,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Vui lòng nhập email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                  return 'Email không hợp lệ';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          'MẬT KHẨU',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 11,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      if (_passwordStrength.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _passwordStrengthColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _passwordStrength,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: _passwordStrengthColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Vui lòng nhập mật khẩu';
                    }
                    if (value!.length < 6) {
                      return 'Mật khẩu phải có ít nhất 6 ký tự';
                    }
                    return null;
                  },
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 15,
                    color: AppColors.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Nhập mật khẩu',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 15,
                      color: AppColors.outlineVariant,
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 16, right: 12),
                      child: Icon(Icons.lock_outline, color: AppColors.outline, size: 20),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 48),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.outline,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                        splashRadius: 20,
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.primary.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.error.withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Xác nhận mật khẩu',
              placeholder: 'Nhập lại mật khẩu',
              icon: Icons.lock_outline,
              controller: _confirmPasswordController,
              obscureText: true,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Vui lòng nhập lại mật khẩu';
                }
                if (value != _passwordController.text) {
                  return 'Mật khẩu xác nhận không khớp';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Đăng ký',
              onPressed: isLoading ? null : _handleRegister,
              isLoading: isLoading,
            ),
          ],
        );
      },
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.outlineVariant.withOpacity(0.3),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'HOẶC',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.outlineVariant,
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.outlineVariant.withOpacity(0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return AppButton(
      text: 'Đăng ký bằng Google',
      type: AppButtonType.tertiary,
      onPressed: () {},
    );
  }

  Widget _buildLoginPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Đã có tài khoản?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            'Đăng nhập',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFooterLink('Điều khoản'),
            const SizedBox(width: 24),
            _buildFooterLink('Bảo mật'),
            const SizedBox(width: 24),
            _buildFooterLink('Hỗ trợ'),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '© 2024 Năng Lượng Sạch. Tất cả quyền được bảo lưu.',
          style: AppTextStyles.bodySmall.copyWith(
            color: const Color(0xFF64748B),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFooterLink(String text) {
    return InkWell(
      onTap: () {},
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          color: const Color(0xFF64748B),
          fontSize: 12,
        ),
      ),
    );
  }
}


  String _getDashboardRoute(UserRole role) {
    switch (role) {
      case UserRole.staff:
        return '/admin/dashboard';
      case UserRole.technician:
        return '/technician/dashboard';
      case UserRole.customer:
        return '/customer/dashboard';
    }
  }

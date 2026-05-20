import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import '../../bloc/auth_bloc.dart';
import '../../../../domain/entities/user.dart';
import '../bloc/login_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Temporarily disabled - testing
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (mounted) {
    //     context.read<LoginBloc>().add(const LoginCredentialsLoaded());
    //   }
    // });
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<LoginBloc>().add(
            LoginSubmitted(
              identifier: _identifierController.text.trim(),
              password: _passwordController.text,
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
              Color(0xFFF0FDF4), // green-50
              Color(0xFFE0F2FE), // blue-50
            ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative blur circles
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
            
            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Header
                  _buildHeader(),
                  
                  // Login form with footer
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildLoginCard(),
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
            color: Color(0xFF15803D), // green-700
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            'Năng Lượng Sạch',
            style: AppTextStyles.titleMedium.copyWith(
              color: const Color(0xFF166534), // green-800
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
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
            // Top accent line
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
                    const SizedBox(height: 40),
                    _buildLoginForm(),
                    const SizedBox(height: 40),
                    _buildDivider(),
                    const SizedBox(height: 24),
                    _buildSecondaryOptions(),
                    const SizedBox(height: 40),
                    _buildSignUpPrompt(),
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
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryFixed.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.bolt,
            color: AppColors.primary,
            size: 40,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Chào mừng trở lại',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Hệ thống quản lý bảo trì xe điện thông minh',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return BlocConsumer<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is LoginSuccess) {
          context.read<AuthBloc>().add(AuthUserUpdated(user: state.user));
          // Navigate based on user role
          _navigateBasedOnRole(context, state.user);
        } else if (state is LoginFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        } else if (state is LoginInitial && state.savedIdentifier != null) {
          // Auto-fill saved credentials
          _identifierController.text = state.savedIdentifier!;
          _passwordController.text = state.savedPassword!;
        }
      },
      builder: (context, state) {
        final isLoading = state is LoginLoading;

        return Column(
          children: [
            AppTextField(
              label: 'Email hoặc Số điện thoại',
              placeholder: 'name@example.com',
              icon: Icons.mail_outline,
              controller: _identifierController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Vui lòng nhập email hoặc số điện thoại';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            AppTextField(
              label: 'Mật khẩu',
              placeholder: '••••••••',
              icon: Icons.lock_outline,
              controller: _passwordController,
              obscureText: true,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Vui lòng nhập mật khẩu';
                }
                if (value!.length < 6) {
                  return 'Mật khẩu phải có ít nhất 6 ký tự';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildOptions(state),
            const SizedBox(height: 24),
            AppButton(
              text: 'Đăng nhập',
              onPressed: isLoading ? null : _handleLogin,
              isLoading: isLoading,
            ),
          ],
        );
      },
    );
  }

  Widget _buildOptions(LoginState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: Checkbox(
                value: (state is LoginInitial) ? state.rememberMe : false,
                onChanged: (value) {
                  context.read<LoginBloc>().add(LoginRememberMeToggled(value ?? false));
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Ghi nhớ',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () {},
          child: Text(
            'Quên mật khẩu?',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
            'HOẶC TIẾP TỤC VỚI',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.outlineVariant,
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

  Widget _buildSecondaryOptions() {
    return Column(
      children: [
        AppButton(
          text: 'Đăng nhập với Email',
          icon: Icons.alternate_email,
          type: AppButtonType.tertiary,
          onPressed: () {},
        ),
        const SizedBox(height: 12),
        AppButton(
          text: 'Đăng nhập với Số điện thoại',
          icon: Icons.smartphone,
          type: AppButtonType.tertiary,
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildSignUpPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Chưa có tài khoản?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pushNamed('/register');
          },
          child: Text(
            'Tạo tài khoản ngay',
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
          color: const Color(0xFF64748B), // slate-500
          fontSize: 12,
        ),
      ),
    );
  }
}


  void _navigateBasedOnRole(BuildContext context, User user) {
    // Clear navigation stack and navigate to appropriate dashboard
    final route = _getDashboardRoute(user.role);
    Navigator.of(context).pushNamedAndRemoveUntil(
      route,
      (route) => false,
    );
  }

  String _getDashboardRoute(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return '/admin/dashboard';
      case UserRole.technician:
        return '/technician/dashboard';
      case UserRole.customer:
        return '/customer/dashboard';
    }
  }

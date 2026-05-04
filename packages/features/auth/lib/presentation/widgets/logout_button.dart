import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'package:get_it/get_it.dart';
import '../../domain/usecases/logout_usecase.dart';
import 'package:core/core.dart';

class LogoutButton extends StatelessWidget {
  final VoidCallback? onLogoutSuccess;

  const LogoutButton({
    super.key,
    this.onLogoutSuccess,
  });

  Future<void> _handleLogout(BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Call logout
    final logoutUseCase = GetIt.instance<LogoutUseCase>();
    final result = await logoutUseCase(NoParams());

    if (!context.mounted) return;
    Navigator.of(context).pop(); // Close loading

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: AppColors.error,
          ),
        );
      },
      (_) {
        // Navigate to login
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
        onLogoutSuccess?.call();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout),
      onPressed: () => _handleLogout(context),
      tooltip: 'Đăng xuất',
    );
  }
}

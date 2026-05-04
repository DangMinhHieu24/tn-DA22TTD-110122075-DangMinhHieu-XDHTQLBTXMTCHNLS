import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppTextField extends StatefulWidget {
  final String label;
  final String placeholder;
  final IconData icon;
  final bool obscureText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;

  const AppTextField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.icon,
    this.obscureText = false,
    this.controller,
    this.validator,
    this.suffixIcon,
    this.keyboardType,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

  void _toggleObscureText() {
    setState(() {
      _isObscured = !_isObscured;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Auto-generate suffix icon for password fields
    final effectiveSuffixIcon = widget.obscureText
        ? IconButton(
            icon: Icon(
              _isObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: AppColors.outline,
              size: 20,
            ),
            onPressed: _toggleObscureText,
            splashRadius: 20,
          )
        : widget.suffixIcon;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            widget.label.toUpperCase(),
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
        ),
        TextFormField(
          controller: widget.controller,
          obscureText: _isObscured,
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 15,
            color: AppColors.onSurface,
          ),
          decoration: InputDecoration(
            hintText: widget.placeholder,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              fontSize: 15,
              color: AppColors.outlineVariant,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Icon(widget.icon, color: AppColors.outline, size: 20),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 48,
            ),
            suffixIcon: effectiveSuffixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: effectiveSuffixIcon,
                  )
                : null,
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
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppColors.error.withOpacity(0.6),
                width: 2,
              ),
            ),
            errorStyle: AppTextStyles.bodySmall.copyWith(
              color: AppColors.error,
              fontSize: 12,
              height: 1.2,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}

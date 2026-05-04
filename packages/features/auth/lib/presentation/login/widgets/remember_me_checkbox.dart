import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/login_bloc.dart';

/// Remember me checkbox widget
class RememberMeCheckbox extends StatelessWidget {
  const RememberMeCheckbox({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        final rememberMe = state is LoginInitial ? state.rememberMe : false;
        
        return Row(
          children: [
            Checkbox(
              value: rememberMe,
              onChanged: (value) {
                context.read<LoginBloc>().add(
                  LoginRememberMeToggled(value ?? false),
                );
              },
              activeColor: const Color(0xFF006E2F),
            ),
            const Text(
              'Ghi nhớ đăng nhập',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF3D4A3D),
              ),
            ),
          ],
        );
      },
    );
  }
}

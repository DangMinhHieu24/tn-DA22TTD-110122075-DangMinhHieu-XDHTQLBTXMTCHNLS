import 'package:dartz/dartz.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase implements UseCase<User, RegisterParams> {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(RegisterParams params) async {
    if (params.name.isEmpty) {
      return const Left(ValidationFailure('Họ và tên không được để trống'));
    }
    
    if (params.phoneNumber.isEmpty) {
      return const Left(ValidationFailure('Số điện thoại không được để trống'));
    }
    
    if (params.email.isEmpty) {
      return const Left(ValidationFailure('Email không được để trống'));
    }
    
    if (!_isValidEmail(params.email)) {
      return const Left(ValidationFailure('Email không hợp lệ'));
    }
    
    if (params.password.isEmpty) {
      return const Left(ValidationFailure('Mật khẩu không được để trống'));
    }
    
    if (params.password.length < 6) {
      return const Left(ValidationFailure('Mật khẩu phải có ít nhất 6 ký tự'));
    }
    
    if (params.password != params.confirmPassword) {
      return const Left(ValidationFailure('Mật khẩu xác nhận không khớp'));
    }

    return await repository.register(
      name: params.name,
      phoneNumber: params.phoneNumber,
      email: params.email,
      password: params.password,
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}

class RegisterParams extends Equatable {
  final String name;
  final String phoneNumber;
  final String email;
  final String password;
  final String confirmPassword;

  const RegisterParams({
    required this.name,
    required this.phoneNumber,
    required this.email,
    required this.password,
    required this.confirmPassword,
  });

  @override
  List<Object> get props => [name, phoneNumber, email, password, confirmPassword];
}

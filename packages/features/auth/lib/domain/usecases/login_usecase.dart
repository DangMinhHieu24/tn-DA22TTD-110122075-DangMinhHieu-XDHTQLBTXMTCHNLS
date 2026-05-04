import 'package:dartz/dartz.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase implements UseCase<User, LoginParams> {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(LoginParams params) async {
    if (params.identifier.isEmpty) {
      return const Left(ValidationFailure('Email hoặc số điện thoại không được để trống'));
    }
    
    if (params.password.isEmpty) {
      return const Left(ValidationFailure('Mật khẩu không được để trống'));
    }
    
    if (params.password.length < 6) {
      return const Left(ValidationFailure('Mật khẩu phải có ít nhất 6 ký tự'));
    }

    return await repository.login(
      identifier: params.identifier,
      password: params.password,
    );
  }
}

class LoginParams extends Equatable {
  final String identifier;
  final String password;

  const LoginParams({
    required this.identifier,
    required this.password,
  });

  @override
  List<Object> get props => [identifier, password];
}

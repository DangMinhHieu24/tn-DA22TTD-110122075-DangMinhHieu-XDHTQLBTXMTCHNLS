import 'package:dartz/dartz.dart';
import 'package:core/core.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> login({
    required String identifier,
    required String password,
  });
  
  Future<Either<Failure, User>> register({
    required String name,
    required String phoneNumber,
    required String email,
    required String password,
  });
  
  Future<Either<Failure, void>> logout();
  
  Future<Either<Failure, User>> getCurrentUser();
}

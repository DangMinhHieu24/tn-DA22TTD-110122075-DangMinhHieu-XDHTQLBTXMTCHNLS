import 'package:dartz/dartz.dart';
import 'package:core/core.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/auth_local_datasource.dart';
import '../datasources/remote/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });
  
  @override
  Future<Either<Failure, User>> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await remoteDataSource.login(
        identifier: identifier,
        password: password,
      );
      
      // Save token and user to local storage
      await localDataSource.saveToken(response.token);
      await localDataSource.saveUser(response.user);
      
      return Right(response.user);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> register({
    required String name,
    required String phoneNumber,
    required String email,
    required String password,
  }) async {
    try {
      final response = await remoteDataSource.register(
        name: name,
        phoneNumber: phoneNumber,
        email: email,
        password: password,
      );
      
      // Save token and user to local storage
      await localDataSource.saveToken(response.token);
      await localDataSource.saveUser(response.user);
      
      return Right(response.user);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      // Call API to logout
      await remoteDataSource.logout();
      
      // Clear local storage
      await localDataSource.deleteToken();
      await localDataSource.deleteUser();
      
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      await localDataSource.saveUser(user);
      return Right(user);
    } catch (e) {
      try {
        final cached = await localDataSource.getUser();
        if (cached == null) {
          return const Left(CacheFailure('Chưa đăng nhập'));
        }
        return Right(cached);
      } catch (e2) {
        return Left(CacheFailure(e2.toString()));
      }
    }
  }
}

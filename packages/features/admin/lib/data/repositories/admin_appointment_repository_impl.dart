import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/admin_appointment.dart';
import '../../domain/repositories/admin_appointment_repository.dart';
import '../datasources/remote/admin_appointment_remote_datasource.dart';

class AdminAppointmentRepositoryImpl implements AdminAppointmentRepository {
  final AdminAppointmentRemoteDataSource remoteDataSource;

  AdminAppointmentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<AdminAppointment>>> getUpcomingAppointments({String? date, String? dateFrom, String? dateTo}) async {
    try {
      final models = await remoteDataSource.getUpcomingAppointments(date: date, dateFrom: dateFrom, dateTo: dateTo);
      return Right(models);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAppointment(String id) async {
    try {
      await remoteDataSource.deleteAppointment(id);
      return const Right(null);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Lỗi mạng khi xóa lịch hẹn';
      return Left(ServerFailure(message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

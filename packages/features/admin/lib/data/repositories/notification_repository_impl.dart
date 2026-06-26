import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../domain/repositories/notification_repository.dart';
import '../models/notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final Dio dio;

  NotificationRepositoryImpl({required this.dio});

  @override
  Future<Either<Failure, Tuple2<List<NotificationModel>, int>>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await dio.get(
        '/notifications',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        final List<dynamic> notifList = data['notifications'] as List<dynamic>;
        final notifications = notifList.map((json) => NotificationModel.fromJson(json)).toList();
        final unreadCount = data['unreadCount'] as int? ?? 0;
        return Right(Tuple2(notifications, unreadCount));
      }
      return Left(ServerFailure('Không thể tải danh sách thông báo'));
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Lỗi kết nối máy chủ khi tải thông báo';
      return Left(ServerFailure(message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String id) async {
    try {
      final response = await dio.patch('/notifications/$id/read');
      if (response.data['success'] == true) {
        return const Right(null);
      }
      return Left(ServerFailure('Không thể cập nhật trạng thái thông báo'));
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Lỗi kết nối máy chủ khi đọc thông báo';
      return Left(ServerFailure(message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAllAsRead() async {
    try {
      final response = await dio.patch('/notifications/read-all');
      if (response.data['success'] == true) {
        return const Right(null);
      }
      return Left(ServerFailure('Không thể cập nhật tất cả thông báo'));
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Lỗi kết nối máy chủ khi đọc tất cả thông báo';
      return Left(ServerFailure(message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotification(String id) async {
    try {
      final response = await dio.delete('/notifications/$id');
      if (response.data['success'] == true) {
        return const Right(null);
      }
      return Left(ServerFailure('Không thể xóa thông báo'));
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Lỗi kết nối máy chủ khi xóa thông báo';
      return Left(ServerFailure(message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import '../../data/models/notification_model.dart';

abstract class NotificationRepository {
  Future<Either<Failure, Tuple2<List<NotificationModel>, int>>> getNotifications({
    int page = 1,
    int limit = 20,
  });
  Future<Either<Failure, void>> markAsRead(String id);
  Future<Either<Failure, void>> markAllAsRead();
  Future<Either<Failure, void>> deleteNotification(String id);
}

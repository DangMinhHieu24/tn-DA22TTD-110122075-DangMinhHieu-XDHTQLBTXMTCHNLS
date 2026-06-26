import 'package:equatable/equatable.dart';
import '../../../data/models/notification_model.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationEvent {
  final String userId;

  const LoadNotifications({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class MarkNotificationAsRead extends NotificationEvent {
  final String id;

  const MarkNotificationAsRead(this.id);

  @override
  List<Object?> get props => [id];
}

class MarkAllNotificationsAsRead extends NotificationEvent {}

class DeleteNotification extends NotificationEvent {
  final String id;

  const DeleteNotification(this.id);

  @override
  List<Object?> get props => [id];
}

class NewNotificationReceived extends NotificationEvent {
  final NotificationModel notification;

  const NewNotificationReceived(this.notification);

  @override
  List<Object?> get props => [notification];
}

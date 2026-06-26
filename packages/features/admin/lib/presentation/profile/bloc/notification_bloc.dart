import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/models/notification_model.dart';
import '../../../../domain/repositories/notification_repository.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _repository;
  RealtimeChannel? _channel;

  NotificationBloc({required NotificationRepository repository})
      : _repository = repository,
        super(NotificationInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<NewNotificationReceived>(_onNewNotificationReceived);
    on<MarkNotificationAsRead>(_onMarkAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllAsRead);
    on<DeleteNotification>(_onDeleteNotification);
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    final result = await _repository.getNotifications();

    await result.fold(
      (failure) async {
        emit(NotificationError(failure.message));
      },
      (data) async {
        final notifications = data.value1;
        final unreadCount = data.value2;
        emit(NotificationLoaded(
          notifications: notifications,
          unreadCount: unreadCount,
        ));

        // Subscribe to Supabase Realtime
        _unsubscribe();
        try {
          _channel = Supabase.instance.client.channel('admin-notifications-${event.userId}')
            ..onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'notifications',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: event.userId,
              ),
              callback: (payload) {
                try {
                  final model = NotificationModel.fromJson(payload.newRecord);
                  add(NewNotificationReceived(model));
                } catch (e) {
                  print('Error parsing realtime notification: $e');
                }
              },
            )
            ..subscribe();
        } catch (e) {
          print('Error subscribing to notifications channel: $e');
        }
      },
    );
  }

  void _onNewNotificationReceived(
    NewNotificationReceived event,
    Emitter<NotificationState> emit,
  ) {
    final currentState = state;
    if (currentState is NotificationLoaded) {
      // Avoid duplicate insert
      final exists = currentState.notifications.any((n) => n.id == event.notification.id);
      if (exists) return;

      final updatedList = List<NotificationModel>.from(currentState.notifications)
        ..insert(0, event.notification);
      
      final newUnreadCount = event.notification.isRead 
          ? currentState.unreadCount 
          : currentState.unreadCount + 1;

      emit(currentState.copyWith(
        notifications: updatedList,
        unreadCount: newUnreadCount,
      ));
    }
  }

  Future<void> _onMarkAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is NotificationLoaded) {
      final index = currentState.notifications.indexWhere((n) => n.id == event.id);
      if (index == -1) return;

      final notification = currentState.notifications[index];
      if (notification.isRead) return; // Already read

      // Optimistic update
      final updatedNotification = notification.copyWith(isRead: true);
      final updatedList = List<NotificationModel>.from(currentState.notifications);
      updatedList[index] = updatedNotification;

      final previousState = currentState;
      emit(currentState.copyWith(
        notifications: updatedList,
        unreadCount: (currentState.unreadCount - 1).clamp(0, double.infinity).toInt(),
      ));

      final result = await _repository.markAsRead(event.id);
      result.fold(
        (failure) {
          // Revert state on failure
          emit(previousState.copyWith(error: failure.message));
        },
        (_) {
          // Keep the updated state
        },
      );
    }
  }

  Future<void> _onMarkAllAsRead(
    MarkAllNotificationsAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is NotificationLoaded) {
      if (currentState.unreadCount == 0) return;

      final previousState = currentState;

      // Optimistic update
      final updatedList = currentState.notifications.map((n) {
        return n.isRead ? n : n.copyWith(isRead: true);
      }).toList();

      emit(currentState.copyWith(
        notifications: updatedList,
        unreadCount: 0,
      ));

      final result = await _repository.markAllAsRead();
      result.fold(
        (failure) {
          // Revert state
          emit(previousState.copyWith(error: failure.message));
        },
        (_) {
          // Keep updated state
        },
      );
    }
  }

  Future<void> _onDeleteNotification(
    DeleteNotification event,
    Emitter<NotificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is NotificationLoaded) {
      final index = currentState.notifications.indexWhere((n) => n.id == event.id);
      if (index == -1) return;

      final notification = currentState.notifications[index];
      final previousState = currentState;

      // Optimistic update
      final updatedList = List<NotificationModel>.from(currentState.notifications)..removeAt(index);
      final newUnreadCount = notification.isRead
          ? currentState.unreadCount
          : (currentState.unreadCount - 1).clamp(0, double.infinity).toInt();

      emit(currentState.copyWith(
        notifications: updatedList,
        unreadCount: newUnreadCount,
      ));

      final result = await _repository.deleteNotification(event.id);
      result.fold(
        (failure) {
          // Revert state
          emit(previousState.copyWith(error: failure.message));
        },
        (_) {
          // Keep updated state
        },
      );
    }
  }

  void _unsubscribe() {
    final channel = _channel;
    if (channel != null) {
      try {
        Supabase.instance.client.removeChannel(channel);
      } catch (e) {
        print('Error removing channel: $e');
      }
      _channel = null;
    }
  }

  @override
  Future<void> close() {
    _unsubscribe();
    return super.close();
  }
}

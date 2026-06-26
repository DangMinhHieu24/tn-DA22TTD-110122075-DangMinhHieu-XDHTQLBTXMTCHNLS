import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:design_system/design_system.dart';
import '../../../../data/models/notification_model.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';
import '../../dashboard/pages/inventory_page.dart';
import '../../vehicle_intake/pages/reception_hub_page.dart';
import '../../dashboard/pages/work_order_list_page.dart';
import '../../dashboard/pages/work_order_detail_page.dart';

class NotificationListPage extends StatelessWidget {
  const NotificationListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotificationBloc, NotificationState>(
      listener: (context, state) {
        if (state is NotificationLoaded && state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        final notifications = state is NotificationLoaded ? state.notifications : <NotificationModel>[];
        final unreadCount = state is NotificationLoaded ? state.unreadCount : 0;
        final isLoading = state is NotificationLoading;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leadingWidth: 72,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 15,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ),
            title: const Text(
              'Thông báo hệ thống',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            centerTitle: false,
            actions: [
              if (unreadCount > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: TextButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      context.read<NotificationBloc>().add(MarkAllNotificationsAsRead());
                    },
                    icon: const Icon(Icons.done_all, size: 18, color: AppColors.primary),
                    label: const Text(
                      'Đọc tất cả',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              if (isLoading && notifications.isEmpty)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                )
              else if (notifications.isEmpty)
                Expanded(
                  child: _buildEmptyState(context),
                )
              else
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async {
                      // Get userId from state or loaded profile or just reload
                      final currentState = context.read<NotificationBloc>().state;
                      if (currentState is NotificationLoaded && currentState.notifications.isNotEmpty) {
                        final userId = currentState.notifications.first.userId;
                        context.read<NotificationBloc>().add(LoadNotifications(userId: userId));
                      }
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return _buildDismissibleItem(context, notification);
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Không có thông báo mới',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hệ thống sẽ gửi thông báo đến bạn khi có lịch hẹn mới, thay đổi tồn kho phụ tùng hoặc các yêu cầu phê duyệt từ kỹ thuật viên.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDismissibleItem(BuildContext context, NotificationModel notification) {
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.delete_outline_rounded,
              color: Colors.white,
              size: 24,
            ),
            SizedBox(height: 2),
            Text(
              'Xóa',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        HapticFeedback.lightImpact();
        context.read<NotificationBloc>().add(DeleteNotification(notification.id));
      },
      child: _buildNotificationCard(context, notification),
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationModel notification) {
    final hasRead = notification.isRead;
    final typeData = _getTypeData(notification.type);

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        context.read<NotificationBloc>().add(MarkNotificationAsRead(notification.id));
        _handleNotificationNavigation(context, notification);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasRead ? Colors.white : const Color(0xFFF0FDF4), // soft green tint for unread
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasRead ? const Color(0xFFE2E8F0) : AppColors.primary.withValues(alpha: 0.15),
            width: hasRead ? 1.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: typeData.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                typeData.icon,
                color: typeData.color,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),

            // Text details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: hasRead ? FontWeight.w700 : FontWeight.w900,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (!hasRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 8, top: 4),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.content,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF475569),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTimeAgo(notification.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNotificationNavigation(BuildContext context, NotificationModel notification) {
    switch (notification.type) {
      case 'APPOINTMENT_NEW':
      case 'APPOINTMENT_CANCELLED':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const ReceptionHubPage(),
          ),
        );
        break;
      case 'INVENTORY_LOW':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const InventoryPage(),
          ),
        );
        break;
      case 'APPROVAL_REQUEST':
        final workOrderId = notification.data?['workOrderId'] as String?;
        if (workOrderId != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WorkOrderDetailPage(workOrderId: workOrderId),
            ),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const WorkOrderListPage(initialTabIndex: 0),
            ),
          );
        }
        break;
      default:
        break;
    }
  }

  _TypeData _getTypeData(String type) {
    switch (type) {
      case 'APPOINTMENT_NEW':
        return _TypeData(Icons.bookmark_add_rounded, const Color(0xFF10B981)); // Green
      case 'APPOINTMENT_CANCELLED':
        return _TypeData(Icons.cancel_outlined, const Color(0xFFEF4444)); // Red
      case 'INVENTORY_LOW':
        return _TypeData(Icons.warning_amber_rounded, const Color(0xFFF59E0B)); // Orange/Amber
      case 'APPROVAL_REQUEST':
        return _TypeData(Icons.gavel_rounded, const Color(0xFF3B82F6)); // Blue
      default:
        return _TypeData(Icons.notifications_outlined, AppColors.primary);
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    }
  }
}

class _TypeData {
  final IconData icon;
  final Color color;

  const _TypeData(this.icon, this.color);
}

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:design_system/design_system.dart';
import '../../../domain/repositories/customer_repository.dart';
import '../../../domain/entities/customer_vehicle.dart';
import '../../../domain/entities/customer_work_order.dart';
import '../../vehicles/pages/customer_work_order_detail_page.dart';

class CustomerNotification {
  final String id;
  final String title;
  final String content;
  final String type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  CustomerNotification({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory CustomerNotification.fromJson(Map<String, dynamic> json) {
    return CustomerNotification(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      type: json['type'],
      data: json['data'] is Map<String, dynamic> ? json['data'] : null,
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt']).toLocal()
          : DateTime.now(),
    );
  }

  CustomerNotification copyWith({bool? isRead}) {
    return CustomerNotification(
      id: id,
      title: title,
      content: content,
      type: type,
      data: data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}

class CustomerNotificationListPage extends StatefulWidget {
  const CustomerNotificationListPage({super.key});

  @override
  State<CustomerNotificationListPage> createState() => _CustomerNotificationListPageState();
}

class _CustomerNotificationListPageState extends State<CustomerNotificationListPage> {
  final Dio _dio = GetIt.instance<Dio>();
  List<CustomerNotification> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _dio.get('/notifications');
      if (response.data['success'] == true) {
        final List<dynamic> listData = response.data['data']['notifications'] ?? [];
        if (mounted) {
          setState(() {
            _notifications = listData.map((json) => CustomerNotification.fromJson(json)).toList();
            _isLoading = false;
          });
        }
      } else {
        throw Exception(response.data['message'] ?? 'Không thể tải thông báo');
      }
    } on DioException catch (e) {
      String msg = 'Lỗi kết nối máy chủ';
      if (e.response != null && e.response?.data is Map) {
        msg = e.response?.data['message'] ?? msg;
      }
      if (mounted) {
        setState(() {
          _errorMessage = msg;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsRead(CustomerNotification notification) async {
    if (notification.isRead) return;

    // Optimistically update UI
    setState(() {
      _notifications = _notifications.map((n) {
        return n.id == notification.id ? n.copyWith(isRead: true) : n;
      }).toList();
    });

    try {
      await _dio.patch('/notifications/${notification.id}/read');
    } catch (e) {
      // Revert if failed
      _loadNotifications();
    }
  }

  Future<void> _markAllAsRead() async {
    if (_notifications.isEmpty || _notifications.every((n) => n.isRead)) return;

    // Optimistically update UI
    setState(() {
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    });

    try {
      final response = await _dio.patch('/notifications/read-all');
      if (response.data['success'] != true) {
        throw Exception();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã đánh dấu đọc tất cả thông báo'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      _loadNotifications();
    }
  }

  Future<void> _deleteNotification(CustomerNotification notification) async {
    final deletedIndex = _notifications.indexOf(notification);
    
    // Optimistically update UI
    setState(() {
      _notifications.removeAt(deletedIndex);
    });

    try {
      final response = await _dio.delete('/notifications/${notification.id}');
      if (response.data['success'] != true) {
        throw Exception();
      }
    } catch (e) {
      // Revert if failed
      _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Không thể xóa thông báo, vui lòng thử lại'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleNotificationTap(CustomerNotification notification) async {
    await _markAsRead(notification);

    final workOrderId = notification.data?['workOrderId'];
    if (workOrderId != null && workOrderId is String) {
      _showLoadingDialog();

      try {
        final customerRepo = GetIt.instance<CustomerRepository>();
        final vehicleResult = await customerRepo.getCustomerVehicles();
        
        CustomerVehicle? foundVehicle;
        CustomerWorkOrder? foundWorkOrder;

        await vehicleResult.fold(
          (failure) async {
            _dismissLoading();
            _showErrorSnackBar('Không thể tải thông tin xe');
          },
          (vehicles) async {
            for (final v in vehicles) {
              final woResult = await customerRepo.getWorkOrdersByVehicle(v.id);
              woResult.fold(
                (_) {},
                (workOrders) {
                  for (final wo in workOrders) {
                    if (wo.id == workOrderId) {
                      foundVehicle = v;
                      foundWorkOrder = wo;
                      break;
                    }
                  }
                },
              );
              if (foundWorkOrder != null) break;
            }
          },
        );

        _dismissLoading();

        if (foundWorkOrder != null && foundVehicle != null) {
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CustomerWorkOrderDetailPage(
                  workOrder: foundWorkOrder!,
                  vehicle: foundVehicle!,
                ),
              ),
            );
          }
        } else {
          _showErrorSnackBar('Không tìm thấy chi tiết phiếu sửa chữa');
        }
      } catch (e) {
        _dismissLoading();
        _showErrorSnackBar('Đã xảy ra lỗi khi tải dữ liệu');
      }
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }

  void _dismissLoading() {
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.error,
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Hôm nay, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (dt.year == now.year && dt.month == now.month && dt.day == now.day - 1) {
      return 'Hôm qua, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
  }

  IconData _getIconForType(String type) {
    final t = type.toUpperCase();
    if (t.contains('CREATED')) {
      return Icons.assignment_outlined;
    } else if (t.contains('IN_PROGRESS')) {
      return Icons.build_circle_outlined;
    } else if (t.contains('COMPLETED')) {
      return Icons.check_circle_outline_rounded;
    } else if (t.contains('PAID')) {
      return Icons.receipt_long_rounded;
    }
    return Icons.notifications_none_rounded;
  }

  Color _getColorForType(String type) {
    final t = type.toUpperCase();
    if (t.contains('CREATED')) {
      return AppColors.primary;
    } else if (t.contains('IN_PROGRESS')) {
      return const Color(0xFF8B5CF6);
    } else if (t.contains('COMPLETED')) {
      return const Color(0xFF10B981);
    } else if (t.contains('PAID')) {
      return const Color(0xFF059669);
    }
    return const Color(0xFF3B82F6);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.onSurface, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Thông báo',
          style: TextStyle(
            color: AppColors.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (_notifications.isNotEmpty && _notifications.any((n) => !n.isRead))
            IconButton(
              icon: const Icon(Icons.mark_chat_read_outlined, color: AppColors.primary),
              onPressed: _markAllAsRead,
              tooltip: 'Đọc tất cả',
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.outlineVariant.withValues(alpha: 0.5), height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadNotifications,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              size: 64,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Bạn không có thông báo nào',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Các cập nhật sửa chữa xe sẽ hiển thị ở đây.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      color: AppColors.primary,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notif = _notifications[index];
                          final icon = _getIconForType(notif.type);
                          final color = _getColorForType(notif.type);

                          return Dismissible(
                            key: Key(notif.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              color: AppColors.errorContainer,
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                color: AppColors.error,
                                size: 28,
                              ),
                            ),
                            onDismissed: (direction) => _deleteNotification(notif),
                            child: InkWell(
                              onTap: () => _handleNotificationTap(notif),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: notif.isRead ? Colors.transparent : const Color(0xFFF0FDF4),
                                  border: const Border(
                                    bottom: BorderSide(color: Color(0xFFF3F4F6)),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Notification Icon with colored background circular badge
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        icon,
                                        color: color,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  notif.title,
                                                  style: TextStyle(
                                                    fontSize: 13.5,
                                                    fontWeight: notif.isRead
                                                        ? FontWeight.w700
                                                        : FontWeight.w800,
                                                    color: notif.isRead
                                                        ? AppColors.onSurfaceVariant
                                                        : AppColors.primary,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                _formatTime(notif.createdAt),
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.onSurfaceVariant,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            notif.content,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: notif.isRead
                                                  ? AppColors.onSurfaceVariant
                                                  : AppColors.onSurface,
                                              fontWeight: notif.isRead
                                                  ? FontWeight.w500
                                                  : FontWeight.w600,
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!notif.isRead) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        margin: const EdgeInsets.only(top: 6),
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

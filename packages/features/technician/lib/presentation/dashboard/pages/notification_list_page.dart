import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:design_system/design_system.dart';
import '../../../domain/repositories/work_repository.dart';
import '../../../domain/entities/work_item.dart';
import '../../work_detail/pages/work_detail_page.dart';

class TechNotification {
  final String id;
  final String title;
  final String content;
  final String type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  TechNotification({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory TechNotification.fromJson(Map<String, dynamic> json) {
    return TechNotification(
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

  TechNotification copyWith({bool? isRead}) {
    return TechNotification(
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

class NotificationListPage extends StatefulWidget {
  const NotificationListPage({super.key});

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {
  final Dio _dio = GetIt.instance<Dio>();
  List<TechNotification> _notifications = [];
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
            _notifications = listData.map((json) => TechNotification.fromJson(json)).toList();
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

  Future<void> _markAsRead(TechNotification notification) async {
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
            backgroundColor: const Color(0xFF006E2F),
          ),
        );
      }
    } catch (e) {
      _loadNotifications();
    }
  }

  Future<void> _deleteNotification(TechNotification notification) async {
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
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _handleNotificationTap(TechNotification notification) async {
    await _markAsRead(notification);

    final workOrderId = notification.data?['workOrderId'];
    if (workOrderId != null && workOrderId is String) {
      _showLoadingDialog();

      try {
        final workRepo = GetIt.instance<WorkRepository>();
        final result = await workRepo.getWorkItemById(workOrderId);
        
        if (mounted) {
          Navigator.of(context).pop(); // Dismiss loading dialog
        }

        result.fold(
          (failure) {
            _showErrorSnackBar('Không thể tải chi tiết phiếu sửa chữa');
          },
          (workItem) {
            if (mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => WorkDetailPage(workItem: workItem),
                ),
              );
            }
          },
        );
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Dismiss loading dialog
        }
        _showErrorSnackBar('Đã xảy ra lỗi khi truy cập phiếu sửa chữa');
      }
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006E2F)),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFFDC2626),
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
    if (t.contains('ASSIGN')) {
      return Icons.assignment_turned_in_rounded;
    } else if (t.contains('APPROVAL')) {
      return Icons.fact_check_rounded;
    } else if (t.contains('INVENTORY') || t.contains('STOCK')) {
      return Icons.warning_amber_rounded;
    }
    return Icons.notifications_rounded;
  }

  Color _getColorForType(String type) {
    final t = type.toUpperCase();
    if (t.contains('ASSIGN')) {
      return const Color(0xFF006E2F);
    } else if (t.contains('APPROVAL')) {
      return const Color(0xFF16A34A);
    } else if (t.contains('INVENTORY') || t.contains('STOCK')) {
      return const Color(0xFFD97706);
    }
    return const Color(0xFF0058BE);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF191C1E), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Thông báo hệ thống',
          style: TextStyle(
            color: Color(0xFF191C1E),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (_notifications.isNotEmpty && _notifications.any((n) => !n.isRead))
            IconButton(
              icon: const Icon(Icons.mark_chat_read_outlined, color: Color(0xFF006E2F)),
              onPressed: _markAllAsRead,
              tooltip: 'Đọc tất cả',
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE5E7EB), height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006E2F)),
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_rounded, size: 56, color: Color(0xFF9CA3AF)),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadNotifications,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006E2F),
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
                            decoration: const BoxDecoration(
                              color: Color(0xFFF3F4F6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              size: 64,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Bạn không có thông báo nào',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Các thông báo công việc sẽ xuất hiện tại đây.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      color: const Color(0xFF006E2F),
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
                              color: const Color(0xFFFEE2E2),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                color: Color(0xFFDC2626),
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
                                        color: color.withOpacity(0.08),
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
                                                        ? const Color(0xFF4B5563)
                                                        : const Color(0xFF006E2F),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                _formatTime(notif.createdAt),
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF9CA3AF),
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
                                                  ? const Color(0xFF6B7280)
                                                  : const Color(0xFF1F2937),
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
                                          color: Color(0xFF006E2F),
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

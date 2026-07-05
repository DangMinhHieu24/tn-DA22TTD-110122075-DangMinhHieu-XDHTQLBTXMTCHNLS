import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import '../../../domain/repositories/work_repository.dart';
import '../../../domain/entities/work_item.dart';
import '../../../domain/entities/work_item_service.dart';
import '../widgets/tech_customer_chat_sheet.dart';

const _serviceTypes = ['MAINTENANCE', 'BATTERY_CHECK', 'BRAKES_TIRES', 'OTHER_REPAIR'];

String _serviceLabel(String type) => switch (type) {
  'MAINTENANCE' => 'Bảo dưỡng định kỳ',
  'BATTERY_CHECK' => 'Kiểm tra pin/sạc',
  'BRAKES_TIRES' => 'Phanh & Lốp',
  'OTHER_REPAIR' => 'Sửa chữa khác',
  _ => type,
};

double _defaultServicePrice(String type) => switch (type) {
  'MAINTENANCE' => 200000,
  'BATTERY_CHECK' => 150000,
  'BRAKES_TIRES' => 250000,
  'OTHER_REPAIR' => 200000,
  _ => 0,
};

/// Chi tiết phiếu sửa chữa - 100% converted from UX design
/// Follows "Kinetic Sanctuary" design philosophy
class WorkDetailPage extends StatefulWidget {
  final WorkItem workItem;

  const WorkDetailPage({
    super.key,
    required this.workItem,
  });

  @override
  State<WorkDetailPage> createState() => _WorkDetailPageState();
}

class _WorkDetailPageState extends State<WorkDetailPage> {
  final PageController _photoController = PageController();
  int _currentPhotoIndex = 0;
  late WorkItem _currentItem;
  late final WorkRepository _workRepository;
  late final WorkOrderRealtimeService _realtimeService;
  // Local photo URLs to allow cache-busting retries
  late List<String> _photoUrls;
  late List<String> _afterRepairPhotoUrls;
  List<WorkItemService> _serviceItems = const [];
  
  // Parts inventory
  List<Map<String, dynamic>> _parts = [];
  List<Map<String, dynamic>> _allParts = [];
  bool _loadingParts = false;
  final TextEditingController _notesController = TextEditingController();
  bool _savingParts = false;
  bool _savingNotes = false;

  @override
  void dispose() {
    _realtimeService.unsubscribe();
    _photoController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB), // background
      body: SafeArea(
        child: Column(
          children: [
            _buildTopAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildHeaderSection(),
                    const SizedBox(height: 24),
                    _buildStatusTimeline(),
                    const SizedBox(height: 24),
                    if (_currentItem.notes != null && _currentItem.notes!.trim().isNotEmpty) ...[
                      _buildIntakeNotesSection(),
                      const SizedBox(height: 24),
                    ],
                    _buildChecklistSection(),
                    const SizedBox(height: 24),
                    _buildPartsInventorySection(),
                    const SizedBox(height: 24),
                    _buildTechnicalNotesSection(),
                    const SizedBox(height: 24),
                    _buildCostSummarySection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// TopAppBar - No border, tonal shift
  Widget _buildTopAppBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F6).withOpacity(0.8), // surface-container-low/80
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF191C1E).withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF006E2F)),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 12),
          const Text(
            'Chi tiết phiếu sửa chữa',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF006E2F),
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF006E2F)),
            onPressed: () {},
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  /// Header Information with vehicle images carousel
  Widget _buildHeaderSection() {
    final photoCount = _photoUrls.length;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFDDF2E8),
            Color(0xFFCFECDF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F9D58).withOpacity(0.12),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ticket #${widget.workItem.id.substring(0, 8).toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF191C1E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.workItem.vehicleModel} - Biển số: ${widget.workItem.licensePlate}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF3D4A3D),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF0F9D58),
                            Color(0xFF22C55E),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F9D58).withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.build,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getStatusLabel(_currentItem.status),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Vehicle Images Carousel
          if (photoCount > 0)
            SizedBox(
              height: 192,
              child: PageView.builder(
                controller: _photoController,
                itemCount: photoCount,
                onPageChanged: (index) {
                  setState(() {
                    _currentPhotoIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final url = _photoUrls[index];
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          url,
                          width: double.infinity,
                          height: 192,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              width: double.infinity,
                              height: 192,
                              color: const Color(0xFFECEEF0),
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: double.infinity,
                              height: 192,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E9E9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFBA1A1A).withOpacity(0.2)),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.broken_image, size: 36, color: Color(0xFFBA1A1A)),
                                    const SizedBox(height: 8),
                                    const Text('Không thể tải ảnh', style: TextStyle(color: Color(0xFFBA1A1A))),
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _photoUrls[index] = '$url?r=${DateTime.now().millisecondsSinceEpoch}';
                                        });
                                      },
                                      child: const Text('Thử lại', style: TextStyle(color: Color(0xFF006E2F))),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF191C1E).withOpacity(0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Ảnh tiếp nhận ${index + 1}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            )
          else
            Container(
              height: 192,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFECEEF0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: Color(0xFFB0B8B2),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Không có ảnh tiếp nhận',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFB0B8B2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          // Customer Info
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              children: [
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    color: const Color(0xFFBCCBB9).withOpacity(0.25),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 18,
                            color: Color(0xFF3D4A3D),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${widget.workItem.customerName} (Khách hàng)',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF3D4A3D),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        if (widget.workItem.customerId != null) {
                          showTechCustomerChatSheet(
                            context,
                            customerId: widget.workItem.customerId!,
                            customerName: widget.workItem.customerName,
                            isSessionActive: widget.workItem.status != WorkStatus.completed,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Không tìm thấy ID khách hàng để chat')),
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 18,
                        color: Color(0xFF006E2F),
                      ),
                      label: const Text(
                        'Chat',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF006E2F),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  /// Status Timeline Stepper
  Widget _buildStatusTimeline() {
    final activeStep = _getActiveStep(_currentItem.status);
    final nextStatus = _getNextStatus(_currentItem.status);
    final approvedServices = _serviceItems.where((s) => s.isApproved);
    final allApprovedDone = approvedServices.every((item) => item.isDone);
    final isActionDisabled = nextStatus == null ||
        (nextStatus == WorkStatus.completed && !allApprovedDone);
    final buttonLabel = isActionDisabled
      ? 'Đã hoàn thành'
      : _getNextStatusButtonLabel(nextStatus!);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F6), // surface-container-low
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WorkStatusTimelineCard(
            title: 'Tiến trình sửa chữa',
            activeStep: activeStep,
          ),
          const SizedBox(height: 24),
          // Update Status Button
          Center(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isActionDisabled
                  ? null
                  : () => _showStatusChangeDialog(nextStatus!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isActionDisabled
                          ? const [Color(0xFFBFC7C2), Color(0xFFBFC7C2)]
                          : const [Color(0xFF006E2F), Color(0xFF22C55E)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (isActionDisabled
                                ? const Color(0xFFBFC7C2)
                                : const Color(0xFF006E2F))
                            .withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          buttonLabel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          size: 18,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _currentItem = widget.workItem;
    _workRepository = GetIt.instance<WorkRepository>();
    _realtimeService = WorkOrderRealtimeService();
    _serviceItems = List<WorkItemService>.from(widget.workItem.services);
    _photoUrls = widget.workItem.photoUrls.isNotEmpty
        ? List<String>.from(widget.workItem.photoUrls)
        : <String>[];
    _afterRepairPhotoUrls = widget.workItem.afterRepairPhotoUrls.isNotEmpty
        ? List<String>.from(widget.workItem.afterRepairPhotoUrls)
        : <String>[];
    _startRealtime();
    _fetchInventory();
  }

  Future<void> _fetchInventory() async {
    setState(() => _loadingParts = true);
    try {
      final dio = GetIt.instance<Dio>();
      final response = await dio.get('/inventory');
      final data = response.data['data'] as List<dynamic>;
      _allParts = data.map((e) {
        final m = e as Map<String, dynamic>;
        return {
          'id': m['id'],
          'partName': m['partName'] ?? '',
          'stock': m['quantity'] ?? 0,
          'price': m['sellPrice'] ?? m['unitPrice'] ?? 0,
          'quantity': 0,
        };
      }).toList();
      _parts = List.from(_allParts);
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('500')
            ? 'Máy chủ đang bảo trì, vui lòng thử lại sau'
            : 'Không thể tải danh sách phụ tùng';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            action: SnackBarAction(
              label: 'Thử lại',
              onPressed: _fetchInventory,
            ),
          ),
        );
      }
    }
    if (mounted) setState(() => _loadingParts = false);
  }

  Future<void> _saveParts() async {
    setState(() => _savingParts = true);
    try {
      final result = await _workRepository.addParts(_currentItem.id, _parts);
      result.fold(
        (l) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Xuất kho thất bại')),
            );
          }
        },
        (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã xuất kho thành công')),
            );
          }
        },
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi kết nối')),
        );
      }
    }
    if (mounted) setState(() => _savingParts = false);
  }

  Future<void> _saveNotes() async {
    setState(() => _savingNotes = true);
    try {
      final result = await _workRepository.updateNotes(
        _currentItem.id,
        _notesController.text,
      );
      result.fold(
        (l) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Lưu ghi chú thất bại')),
            );
          }
        },
        (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã lưu ghi chú')),
            );
          }
        },
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi kết nối')),
        );
      }
    }
    if (mounted) setState(() => _savingNotes = false);
  }

  Future<void> _pickAndUploadPhoto() async {
    final service = GetIt.instance<ImageUploadService>();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Thêm ảnh sau sửa',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Chụp ảnh'),
                subtitle: const Text('Dùng camera chụp ảnh thực tế'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Chọn từ thư viện'),
                subtitle: const Text('Chọn ảnh có sẵn trong máy'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;

    setState(() => _savingNotes = true);

    try {
      final File? imageFile = source == ImageSource.camera
          ? await service.takePhoto()
          : await service.pickImage();

      if (imageFile == null) {
        if (mounted) setState(() => _savingNotes = false);
        return;
      }

      final imageUrl = await service.uploadImage(
        imageFile: imageFile,
        folder: 'work_orders/${_currentItem.id}',
      );

      final result = await _workRepository.addPhoto(
        _currentItem.id,
        imageUrl,
        photoType: 'AFTER_REPAIR',
        description: 'Ảnh sau sửa - ${DateTime.now().toString().substring(0, 16)}',
      );

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi: ${failure.message}')),
            );
          }
        },
        (_) {
          _refreshWorkItem();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã thêm ảnh sau sửa'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi upload ảnh: $e')),
        );
      }
    }

    if (mounted) setState(() => _savingNotes = false);
  }

  void _startRealtime() {
    _realtimeService.subscribeToWorkOrder(
      workOrderId: widget.workItem.id,
      onChanged: _refreshWorkItem,
    );
    _refreshWorkItem();
  }

  Future<void> _refreshWorkItem() async {
    final result = await _workRepository.getWorkItemById(widget.workItem.id);
    result.fold(
      (_) {},
      (item) {
        if (!mounted) return;
        setState(() {
          _currentItem = item;
          _serviceItems = List<WorkItemService>.from(item.services);
          _photoUrls = item.photoUrls.isNotEmpty
              ? List<String>.from(item.photoUrls)
              : const <String>[];
          _afterRepairPhotoUrls = item.afterRepairPhotoUrls.isNotEmpty
              ? List<String>.from(item.afterRepairPhotoUrls)
              : const <String>[];
        });
      },
    );
  }

  Widget _buildTimelineStep(String label, int step, int activeStep) {
    final isDone = step < activeStep;
    final isActive = step == activeStep;

    final circleColor = isActive
      ? const Color(0xFF22C55E)
      : isDone
        ? const Color(0xFF006E2F)
        : const Color(0xFFF2F4F6);
    final iconColor = isActive
      ? const Color(0xFF0B3B20)
      : (isDone ? Colors.white : const Color(0xFF3D4A3D));

    return Column(
      children: [
        SizedBox(
          width: 36,
          height: 36,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFF2F4F6),
                  shape: BoxShape.circle,
                ),
              ),
              if (!isActive && !isDone)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFBFC7C2),
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              if (isActive)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC9D2CC),
                    shape: BoxShape.circle,
                  ),
                ),
              if (isActive)
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E7A3D),
                    shape: BoxShape.circle,
                  ),
                ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDone
                      ? Icons.check
                      : (isActive ? Icons.build : Icons.flag_outlined),
                  size: 12,
                  color: iconColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
            color: isActive || isDone
                ? const Color(0xFF006E2F)
                : const Color(0xFF3D4A3D),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Checklist Items Section
  Widget _buildChecklistSection() {
    final approvedItems = _serviceItems.where((item) => item.isApproved);
    final completedCount = approvedItems.where((item) => item.isDone).length;
    final approvedCount = approvedItems.length;
    final pendingCount = _serviceItems.where((item) => item.isPending).length;
    final rejectedCount = _serviceItems.where((item) => item.isRejected).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Hạng mục công việc',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF191C1E),
              ),
            ),
            Text(
              pendingCount > 0
                  ? '$completedCount/$approvedCount hoàn thành · $pendingCount chờ duyệt'
                  : '$completedCount/$approvedCount hoàn thành',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF3D4A3D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_serviceItems.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBCCBB9).withOpacity(0.18)),
            ),
            child: const Text(
              'Chưa có hạng mục từ hệ thống.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF3D4A3D),
              ),
            ),
          )
        else
          ..._serviceItems.map((item) => _buildChecklistItem(item)),
        const SizedBox(height: 12),
        // Add Item Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showAddServiceDialog(context),
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF2FBF5), Color(0xFFE3F7E9)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF006E2F).withOpacity(0.16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF006E2F).withOpacity(0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    size: 20,
                    color: Color(0xFF006E2F),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Thêm hạng mục',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF005622),
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistItem(WorkItemService item) {
    final isDone = item.isDone;
    final isPending = item.isPending;
    final isRejectedStatus = item.isRejected;
    final title = _serviceLabel(item.serviceType);
    final priceLabel = item.price != null
        ? _formatPrice(item.price!)
        : 'Chưa có giá';

    Color? _statusColor() {
      if (isPending) return const Color(0xFFF59E0B);
      if (isRejectedStatus) return const Color(0xFFBA1A1A);
      return null;
    }

    String _statusLabel() {
      if (isPending) return 'Chờ duyệt';
      if (isRejectedStatus) return 'Đã từ chối';
      return '';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: !isDone && !isPending && !isRejectedStatus
            ? const Border(
                left: BorderSide(
                  color: Color(0xFF006E2F),
                  width: 4,
                ),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF191C1E).withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: isDone,
            onChanged: isPending || isRejectedStatus
                ? null
                : (value) => _toggleServiceStatus(item, value ?? false),
            activeColor: const Color(0xFF006E2F),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDone ? const Color(0xFF3D4A3D).withOpacity(0.7) : const Color(0xFF191C1E),
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    if (_statusLabel().isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _statusColor()!.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _statusLabel(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _statusColor(),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.description ?? 'Không có mô tả chi tiết.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF3D4A3D),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            priceLabel,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF191C1E),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleServiceStatus(WorkItemService item, bool isDone) async {
    final result = await _workRepository.updateWorkServiceStatus(
      _currentItem.id,
      item.id,
      isDone,
    );

    result.fold(
      (failure) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (updatedService) {
        if (!mounted) return;
        setState(() {
          _serviceItems = _serviceItems.map((service) {
            if (service.id == updatedService.id) {
              return updatedService;
            }
            return service;
          }).toList();
        });
      },
    );
  }

  Future<void> _showAddServiceDialog(BuildContext context) async {
    final existingTypes = widget.workItem.services.map((s) => s.serviceType).toSet();
    final availableTypes = _serviceTypes.where((t) => !existingTypes.contains(t)).toList();
    final descCtrl = TextEditingController();
    String selectedType = availableTypes.isNotEmpty ? availableTypes.first : 'MAINTENANCE';
    final priceCtrl = TextEditingController(text: _formatPrice(_defaultServicePrice(selectedType)));

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFBFC7C2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Gradient header
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF006E2F), Color(0xFF22C55E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF006E2F).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.add_circle_outline,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Thêm hạng mục',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Phát hiện thêm vấn đề? Bổ sung ngay',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Service type selection
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Loại hạng mục',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF191C1E),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(_serviceTypes.length, (i) {
                          final type = _serviceTypes[i];
                          final isSelected = selectedType == type;
                          final isExisting = existingTypes.contains(type);
                          final icons = [
                            Icons.build_circle_outlined,
                            Icons.battery_charging_full,
                            Icons.precision_manufacturing,
                            Icons.handyman_outlined,
                          ];
                          return Padding(
                            padding: EdgeInsets.only(bottom: i < _serviceTypes.length - 1 ? 8 : 0),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: isExisting
                                    ? null
                                    : () => setDialogState(() {
                                          selectedType = type;
                                          priceCtrl.text = _formatPrice(_defaultServicePrice(type));
                                        }),
                                borderRadius: BorderRadius.circular(12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isExisting
                                        ? const Color(0xFFF0F0F0)
                                        : isSelected
                                            ? const Color(0xFFE8F5E9)
                                            : const Color(0xFFF5F7F8),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isExisting
                                          ? const Color(0xFFE0E3E5)
                                          : isSelected
                                              ? const Color(0xFF006E2F)
                                              : const Color(0xFFE0E3E5),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        icons[i],
                                        size: 22,
                                        color: isExisting
                                            ? const Color(0xFFB0B0B0)
                                            : isSelected
                                                ? const Color(0xFF006E2F)
                                                : const Color(0xFF3D4A3D),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _serviceLabel(type),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                            color: isExisting
                                                ? const Color(0xFFB0B0B0)
                                                : isSelected
                                                    ? const Color(0xFF006E2F)
                                                    : const Color(0xFF191C1E),
                                          ),
                                        ),
                                      ),
                                      if (isExisting)
                                        Text(
                                          'Đã có',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: const Color(0xFFB0B0B0),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        )
                                      else if (isSelected)
                                        Container(
                                          width: 22,
                                          height: 22,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF006E2F),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Description input
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mô tả chi tiết',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF191C1E),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: descCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Nhập mô tả chi tiết hạng mục...',
                            hintStyle: TextStyle(
                              color: const Color(0xFF3D4A3D).withOpacity(0.5),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF5F7F8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: const Color(0xFFBCCBB9).withOpacity(0.18),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: const Color(0xFFBCCBB9).withOpacity(0.18),
                              ),
                            ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF006E2F),
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Price input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chi phí (VNĐ)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF191C1E),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Nhập chi phí...',
                    hintStyle: TextStyle(
                      color: const Color(0xFF3D4A3D).withOpacity(0.5),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F7F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: const Color(0xFFBCCBB9).withOpacity(0.18),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: const Color(0xFFBCCBB9).withOpacity(0.18),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF006E2F),
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ],
            ),
          ),
                  const SizedBox(height: 24),
                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Color(0xFFE0E3E5)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Hủy',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF191C1E),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: availableTypes.isEmpty
                                ? null
                                : () {
                                    if (descCtrl.text.trim().isEmpty) return;
                                    Navigator.of(ctx).pop({
                                      'serviceType': selectedType,
                                      'description': descCtrl.text.trim(),
                                      'price': priceCtrl.text.trim().isEmpty
                                    ? null
                                    : double.tryParse(
                                        priceCtrl.text.trim().replaceAll(RegExp(r'[^\d]'), ''),
                                      ),
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                color: availableTypes.isEmpty ? const Color(0xFFB0B0B0) : null,
                                gradient: availableTypes.isNotEmpty
                                    ? const LinearGradient(
                                        colors: [Color(0xFF006E2F), Color(0xFF22C55E)],
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: availableTypes.isNotEmpty
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF006E2F).withOpacity(0.25),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      availableTypes.isEmpty ? Icons.block : Icons.add,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      availableTypes.isEmpty
                                          ? 'Đã đủ hạng mục'
                                          : 'Thêm hạng mục',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result == null) return;

    try {
      final service = await _workRepository.addService(
        _currentItem.id,
        result['serviceType']!,
        result['description']!,
        serviceName: null,
        price: result['price'] as double?,
      );
      service.fold(
        (l) => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thêm hạng mục thất bại')),
        ),
        (r) {
          setState(() => _serviceItems.add(r));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã thêm hạng mục')),
          );
        },
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi kết nối')),
        );
      }
    }
  }

  /// Parts Inventory Section
  Widget _buildPartsInventorySection() {
    final selectedParts = _parts.where((p) => (p['quantity'] as int? ?? 0) > 0).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF191C1E).withOpacity(0.06),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.inventory_2, size: 20, color: Color(0xFF0058BE)),
              SizedBox(width: 8),
              Text(
                'Xuất kho phụ tùng',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF191C1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loadingParts)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else ...[
            if (selectedParts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Chưa chọn phụ tùng',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF3D4A3D)),
                ),
              )
            else
              ...selectedParts.map((part) => _buildPartItem(part)),
            const SizedBox(height: 12),
            // Add Parts Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showAddPartsSheet,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Thêm phụ tùng'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF006E2F),
                  side: const BorderSide(color: Color(0xFF006E2F)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Save Parts Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _savingParts || selectedParts.isEmpty
                    ? null
                    : () => _saveParts(),
                icon: _savingParts
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.inventory_2, size: 18),
                label: Text(_savingParts ? 'Đang lưu...' : 'Xác nhận xuất kho'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006E2F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddPartsSheet() {
    final searchCtrl = TextEditingController();
    var filteredParts = List<Map<String, dynamic>>.from(_allParts);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              builder: (ctx, scrollCtrl) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 64),
                  child: Column(
                    children: [
                      Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFBFC7C2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm mã hoặc tên phụ tùng...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          filled: true,
                          fillColor: const Color(0xFFE0E3E5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (v) {
                          setDialogState(() {
                            final q = v.toLowerCase();
                            filteredParts = _allParts.where((p) =>
                              (p['partName'] as String? ?? '').toLowerCase().contains(q)
                            ).toList();
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollCtrl,
                          itemCount: filteredParts.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final part = filteredParts[i];
                            final selectedQty = _parts.firstWhere(
                              (p) => p['id'] == part['id'],
                              orElse: () => <String, dynamic>{},
                            )['quantity'] as int? ?? 0;
                            return ListTile(
                              title: Text(
                                part['partName'] as String? ?? '',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                'Tồn: ${part['stock']}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 18),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: selectedQty <= 0 ? null : () {
                                      setDialogState(() {
                                        final idx = _parts.indexWhere((p) => p['id'] == part['id']);
                                        if (idx >= 0) _parts[idx]['quantity'] = selectedQty - 1;
                                      });
                                      setState(() {});
                                    },
                                  ),
                                  SizedBox(
                                    width: 28,
                                    child: Text(
                                      '$selectedQty',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 18),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      setDialogState(() {
                                        final idx = _parts.indexWhere((p) => p['id'] == part['id']);
                                        if (idx >= 0) {
                                          _parts[idx]['quantity'] = selectedQty + 1;
                                        } else {
                                          _parts.add({...part, 'quantity': 1});
                                        }
                                      });
                                      setState(() {});
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF006E2F), Color(0xFF22C55E)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF006E2F).withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              alignment: Alignment.center,
                              child: const Text(
                                'Xong',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPartItem(Map<String, dynamic> part) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  part['partName'] as String? ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF191C1E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tồn: ${part['stock']}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF3D4A3D),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Quantity Controls
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE0E3E5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      if (part['quantity'] > 0) {
                        part['quantity']--;
                      }
                    });
                  },
                  icon: const Icon(Icons.remove, size: 18),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
                Container(
                  width: 32,
                  alignment: Alignment.center,
                  child: Text(
                    '${part['quantity']}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      part['quantity']++;
                    });
                  },
                  icon: const Icon(Icons.add, size: 18),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              setState(() {
                part['quantity'] = 0;
              });
            },
            icon: const Icon(
              Icons.delete,
              size: 18,
              color: Color(0xFFBA1A1A),
            ),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// Ghi chú của staff lúc tiếp nhận
  Widget _buildIntakeNotesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF5E6C8),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF5E6C8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              size: 20,
              color: Color(0xFFB8860B),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ghi chú tiếp nhận',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFB8860B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _currentItem.notes ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF5D4E37),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Technical Notes & Evidence Section
  Widget _buildTechnicalNotesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE0E3E5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notes + Photos inline header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit_note_rounded, size: 18, color: Color(0xFF006E2F)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Ghi chú & Ảnh sau sửa',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF191C1E)),
                ),
              ),
              // Save button inline
              SizedBox(
                height: 32,
                child: ElevatedButton.icon(
                  onPressed: _savingNotes ? null : () => _saveNotes(),
                  icon: _savingNotes
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded, size: 16),
                  label: Text(_savingNotes ? 'Đang lưu' : 'Lưu', style: const TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006E2F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Text field
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Mô tả tình trạng, nguyên nhân và hướng xử lý...',
              hintStyle: TextStyle(fontSize: 13, color: const Color(0xFF3D4A3D).withOpacity(0.4)),
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: const Color(0xFFE0E3E5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: const Color(0xFFE0E3E5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF006E2F), width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),
          // Uploaded after-repair photos preview
          if (_afterRepairPhotoUrls.isNotEmpty) ...[
            const Text(
              'Ảnh sau sửa đã thêm:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3D4A3D),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _afterRepairPhotoUrls.length,
                itemBuilder: (context, index) {
                  final url = _afterRepairPhotoUrls[index];
                  return GestureDetector(
                    onTap: () => _showFullscreenImage(url),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE0E3E5)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(Icons.broken_image, size: 24, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Photo row
          InkWell(
            onTap: _savingNotes ? null : _pickAndUploadPhoto,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE0E3E5), width: 1),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_rounded, size: 18, color: Color(0xFF006E2F)),
                  SizedBox(width: 8),
                  Text(
                    'Thêm ảnh sau sửa',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF006E2F)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullscreenImage(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                },
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.5),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Cost Summary Section
  double _totalServiceCost() =>
      _serviceItems.fold<double>(0, (sum, s) => sum + (s.price ?? 0));

  double _totalPartsCost() => _parts.fold<double>(0, (sum, p) {
        final qty = p['quantity'] as int? ?? 0;
        final price = p['price'] as num? ?? 0;
        return sum + qty * price.toDouble();
      });

  double _subtotal() => _totalServiceCost() + _totalPartsCost();

  double _vat() => _subtotal() * 0.08;

  double _grandTotal() => _subtotal() + _vat();

  int _selectedPartsCount() =>
      _parts.fold<int>(0, (sum, p) => sum + (p['quantity'] as int? ?? 0));

  String _formatPrice(double amount) {
    if (amount <= 0) return '0₫';
    final whole = amount.floor();
    final parts = <String>[];
    var s = whole.toString();
    while (s.length > 3) {
      parts.add(s.substring(s.length - 3));
      s = s.substring(0, s.length - 3);
    }
    parts.add(s);
    return '${parts.reversed.join('.')}₫';
  }

  Widget _buildCostSummarySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFBCCBB9).withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF191C1E).withOpacity(0.06),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tổng chi phí dự kiến',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF191C1E),
            ),
          ),
          const SizedBox(height: 16),
          _buildCostRow(
            'Phí dịch vụ (${_serviceItems.length} hạng mục)',
            _formatPrice(_totalServiceCost()),
          ),
          const SizedBox(height: 8),
          _buildCostRow(
            'Phụ tùng xuất kho (${_selectedPartsCount()} món)',
            _formatPrice(_totalPartsCost()),
          ),
          const SizedBox(height: 8),
          _buildCostRow('Thuế VAT (8%)', _formatPrice(_vat())),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Color(0xFFBCCBB9),
                  width: 0.2,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng thanh toán',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF191C1E),
                  ),
                ),
                Text(
                  _formatPrice(_grandTotal()),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF006E2F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostRow(String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF3D4A3D),
          ),
        ),
        Text(
          amount,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF191C1E),
          ),
        ),
      ],
    );
  }


  /// Confirmation Dialog
  void _showStatusChangeDialog(WorkStatus nextStatus) {
    final statusLabel = _getStatusLabel(nextStatus);
    final actionLabel = _getNextStatusButtonLabel(nextStatus);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.help,
                  size: 24,
                  color: Color(0xFF006E2F),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                actionLabel,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF191C1E),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Bạn có chắc chắn muốn chuyển phiếu sửa chữa này sang trạng thái "$statusLabel"? Hãy đảm bảo bước hiện tại đã hoàn tất trước khi tiếp tục.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF3D4A3D),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(
                          color: Color(0xFFE6E8EA),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF191C1E),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _updateWorkStatus(nextStatus);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF006E2F), Color(0xFF22C55E)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          child: const Text(
                            'Xác nhận',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateWorkStatus(WorkStatus nextStatus) async {
    final result = await _workRepository.updateWorkStatus(
      _currentItem.id,
      nextStatus,
    );

    result.fold(
      (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật trạng thái thất bại')),
        );
      },
      (item) {
        if (!mounted) return;
        setState(() {
          _currentItem = item;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã chuyển sang "${_getStatusLabel(item.status)}"')),
        );
      },
    );
  }

  // Helper methods
  String _getStatusLabel(WorkStatus status) {
    switch (status) {
      case WorkStatus.pending:
        return 'Chờ xử lý';
      case WorkStatus.inspection:
        return 'Kiểm tra';
      case WorkStatus.inProgress:
        return 'Đang sửa';
      case WorkStatus.completed:
        return 'Hoàn thành';
      case WorkStatus.cancelled:
        return 'Đã hủy';
      default:
        return 'Đang sửa';
    }
  }

  WorkStatus? _getNextStatus(WorkStatus status) {
    switch (status) {
      case WorkStatus.pending:
        return WorkStatus.inspection;
      case WorkStatus.inspection:
        return WorkStatus.inProgress;
      case WorkStatus.inProgress:
        return WorkStatus.completed;
      case WorkStatus.completed:
      case WorkStatus.cancelled:
        return null;
    }
  }

  String _getNextStatusButtonLabel(WorkStatus nextStatus) {
    switch (nextStatus) {
      case WorkStatus.inspection:
        return 'Hoàn thành tiếp nhận';
      case WorkStatus.inProgress:
        return 'Hoàn thành kiểm tra';
      case WorkStatus.completed:
        return 'Hoàn thành sửa chữa';
      case WorkStatus.pending:
        return 'Cập nhật trạng thái';
      default:
        return 'Cập nhật trạng thái';
    }
  }

  int _getActiveStep(WorkStatus status) {
    switch (status) {
      case WorkStatus.pending:
        return 0;
      case WorkStatus.inspection:
        return 1;
      case WorkStatus.inProgress:
        return 2;
      case WorkStatus.completed:
        return 3;
      case WorkStatus.cancelled:
        return 4;
      default:
        return 2;
    }
  }
}

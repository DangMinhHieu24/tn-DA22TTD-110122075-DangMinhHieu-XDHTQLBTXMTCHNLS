import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import '../../../domain/repositories/work_repository.dart';
import '../../../domain/entities/work_item.dart';
import '../../../domain/entities/work_item_service.dart';

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
  String? _thumbnailUrl;
  List<WorkItemService> _serviceItems = const [];
  
  // Parts inventory
  final List<Map<String, dynamic>> _parts = [
    {
      'name': 'Má phanh đĩa trước Klara',
      'code': 'PT-0921',
      'stock': 14,
      'quantity': 1,
    },
    {
      'name': 'Chai xịt dưỡng xích 150ml',
      'code': 'CH-0112',
      'stock': 45,
      'quantity': 1,
    },
  ];

  @override
  void dispose() {
    _realtimeService.unsubscribe();
    _photoController.dispose();
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
                    _buildChecklistSection(),
                    const SizedBox(height: 24),
                    _buildPartsInventorySection(),
                    const SizedBox(height: 24),
                    _buildTechnicalNotesSection(),
                    const SizedBox(height: 24),
                    _buildCostSummarySection(),
                    const SizedBox(height: 96), // Extra padding for bottom button
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildCompleteButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
                      Icons.add_a_photo,
                      size: 48,
                      color: Color(0xFF3D4A3D),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Thêm ảnh',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF3D4A3D),
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
                    Row(
                      children: [
                        const Icon(
                          Icons.person,
                          size: 18,
                          color: Color(0xFF3D4A3D),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.workItem.customerName} (Khách hàng)',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF3D4A3D),
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.call,
                        size: 18,
                        color: Color(0xFF006E2F),
                      ),
                      label: const Text(
                        'Gọi',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF006E2F),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
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
    final isActionDisabled = nextStatus == null;
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
    // Initialize editable local photo list for retry UX
    _photoUrls = widget.workItem.photoUrls.isNotEmpty
        ? List<String>.from(widget.workItem.photoUrls)
        : (widget.workItem.imageUrl != null && widget.workItem.imageUrl!.isNotEmpty
            ? [widget.workItem.imageUrl!]
            : <String>[]);
    _thumbnailUrl = (_photoUrls.isNotEmpty) ? _photoUrls.first : 'https://via.placeholder.com/80';
    _startRealtime();
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
    final completedCount = _serviceItems.where((item) => item.isDone).length;
    final totalCount = _serviceItems.length;

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
              '$completedCount/$totalCount hoàn thành',
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
            onTap: () {},
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
              child: const Row(
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
    final title = item.serviceName?.isNotEmpty == true
        ? item.serviceName!
        : item.description?.isNotEmpty == true
            ? item.description!
            : 'Hạng mục';
    final priceLabel = item.price != null
        ? '${_formatMoney(item.price!)}đ'
        : 'Chưa có giá';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: !isDone
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
            onChanged: (value) => _toggleServiceStatus(item, value ?? false),
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
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDone ? const Color(0xFF3D4A3D).withOpacity(0.7) : const Color(0xFF191C1E),
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
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

  String _formatMoney(double value) {
    final raw = value.toStringAsFixed(0);
    final reversed = raw.split('').reversed.toList();
    final chunks = <String>[];

    for (var i = 0; i < reversed.length; i += 3) {
      chunks.add(reversed.sublist(i, i + 3 > reversed.length ? reversed.length : i + 3).join());
    }

    return chunks.map((chunk) => chunk.split('').reversed.join()).toList().reversed.join(',');
  }

  /// Parts Inventory Section
  Widget _buildPartsInventorySection() {
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
              Icon(
                Icons.inventory_2,
                size: 20,
                color: Color(0xFF0058BE),
              ),
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
          ..._parts.map((part) => _buildPartItem(part)),
          const SizedBox(height: 16),
          // Search Field
          TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm mã hoặc tên phụ tùng...',
              hintStyle: TextStyle(
                fontSize: 14,
                color: const Color(0xFF3D4A3D).withOpacity(0.6),
              ),
              prefixIcon: const Icon(
                Icons.search,
                size: 20,
                color: Color(0xFF3D4A3D),
              ),
              filled: true,
              fillColor: const Color(0xFFE0E3E5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
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
                  part['name'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF191C1E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mã: ${part['code']} | Tồn: ${part['stock']}',
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
            onPressed: () {},
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

  /// Technical Notes & Evidence Section
  Widget _buildTechnicalNotesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF7F9FB)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFBCCBB9).withOpacity(0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF191C1E).withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ghi chú kỹ thuật & Hình ảnh sau sửa',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF191C1E),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ghi chú thêm về tình trạng xe, khuyến nghị cho lần bảo dưỡng sau...',
              hintStyle: TextStyle(
                fontSize: 14,
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
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Add Photo Button
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECEEF0),
                    border: Border.all(
                      color: const Color(0xFFBCCBB9),
                      style: BorderStyle.solid,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo,
                        size: 24,
                        color: Color(0xFF006E2F),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Chụp ảnh',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF006E2F),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Sample Photo
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _thumbnailUrl ?? 'https://via.placeholder.com/80',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          width: 80,
                          height: 80,
                          color: const Color(0xFFECEEF0),
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E9E9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFBA1A1A).withOpacity(0.15)),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.broken_image, size: 20, color: Color(0xFFBA1A1A)),
                                const SizedBox(height: 4),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      final url = _thumbnailUrl ?? 'https://via.placeholder.com/80';
                                      _thumbnailUrl = '$url?r=${DateTime.now().millisecondsSinceEpoch}';
                                    });
                                  },
                                  child: const Text('Thử lại', style: TextStyle(fontSize: 12, color: Color(0xFF006E2F))),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: InkWell(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF191C1E).withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Cost Summary Section
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
          _buildCostRow('Phí dịch vụ (3 hạng mục)', '280,000đ'),
          const SizedBox(height: 8),
          _buildCostRow('Phụ tùng xuất kho (2 món)', '320,000đ'),
          const SizedBox(height: 8),
          _buildCostRow('Thuế VAT (8%)', '48,000đ'),
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
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tổng thanh toán',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF191C1E),
                  ),
                ),
                Text(
                  '648,000đ',
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

  /// Complete Button (Floating)
  Widget _buildCompleteButton() {
    final nextStatus = _getNextStatus(_currentItem.status);
    if (nextStatus == null) {
      return const SizedBox.shrink();
    }
    final buttonLabel = _getNextStatusButtonLabel(nextStatus);

    return Container(
      width: MediaQuery.of(context).size.width - 32,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: () {
          _showStatusChangeDialog(nextStatus);
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
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF006E2F).withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 20,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  buttonLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
      (_) {},
      (item) {
        if (!mounted) return;
        setState(() {
          _currentItem = item;
        });
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
      default:
        return 2;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import '../../../domain/entities/work_item.dart';

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

  WorkItem get workItem => widget.workItem;

  @override
  void dispose() {
    _photoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = _buildTasks(workItem.description);
    final statusLabel = _statusLabel(workItem.status);
    final activeStep = _activeStepIndex(workItem.status);

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      appBar: AppBar(
        title: const Text('Chi tiết phiếu sửa chữa'),
        backgroundColor: AppColors.surfaceContainerLow,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimelineSection(statusLabel, activeStep),
            const SizedBox(height: 16),
            _buildVehicleSection(),
            const SizedBox(height: 16),
            _buildWorkItemsSection(tasks),
            const SizedBox(height: 16),
            _buildPartsSection(),
            const SizedBox(height: 16),
            _buildReportSection(),
            const SizedBox(height: 16),
            _buildCostSection(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          boxShadow: [
            BoxShadow(
              color: AppColors.onSurface.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          height: 56,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: AppColors.primaryContainer.withOpacity(0.25),
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.zero,
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primaryContainer,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.task_alt, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Hoàn thành sửa chữa',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineSection(String statusLabel, int activeStep) {
    const steps = [
      'Tiếp nhận',
      'Kiểm tra',
      'Đang sửa',
      'Thanh toán',
      'Hoàn thành',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tiến trình sửa chữa',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: activeStep / (steps.length - 1),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primaryContainer,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(steps.length, (index) {
                  final isDone = index < activeStep;
                  final isActive = index == activeStep;
                  final labelColor = isActive
                      ? AppColors.primary
                      : isDone
                          ? AppColors.onSurface
                          : AppColors.onSurfaceVariant;

                  return Text(
                    steps[index],
                    style: AppTextStyles.labelSmall.copyWith(
                      color: labelColor,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 10,
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '$statusLabel — 1 giờ 20 phút',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Kỹ thuật viên đang thực hiện thay thế linh kiện.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, authState) {
                        final name = authState is AuthAuthenticated
                            ? authState.user.name
                            : 'Kỹ thuật viên';
                        final shortId = authState is AuthAuthenticated
                            ? _shortId(authState.user.id)
                            : _shortId(workItem.id);
                        return Text(
                          'KTV: $name - $shortId',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSection() {
    final customerInitial = _initials(workItem.customerName);
    final photos = workItem.photoUrls.isNotEmpty
        ? workItem.photoUrls
        : (workItem.imageUrl != null && workItem.imageUrl!.isNotEmpty
            ? [workItem.imageUrl!]
            : <String>[]);
    final photoCount = photos.length;
    final displayIndex = _currentPhotoIndex < photoCount ? _currentPhotoIndex : 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: photoCount > 0
                      ? PageView.builder(
                          controller: _photoController,
                          itemCount: photoCount,
                          onPageChanged: (index) {
                            setState(() {
                              _currentPhotoIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return Image.network(
                              photos[index],
                              fit: BoxFit.cover,
                            );
                          },
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.surfaceContainerHigh,
                                AppColors.surfaceContainerLow,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.electric_moped,
                              size: 72,
                              color: AppColors.onSurfaceVariant.withOpacity(0.6),
                            ),
                          ),
                        ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.5),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                bottom: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workItem.licensePlate,
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          workItem.vehicleModel,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.verified_user,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Còn bảo hành: 245 ngày',
                                style: AppTextStyles.labelSmall.copyWith(
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
              if (photoCount > 0)
                Positioned(
                  right: 12,
                  bottom: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.photo_camera,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${displayIndex + 1}/$photoCount',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.secondaryContainer,
                  radius: 20,
                  child: Text(
                    customerInitial,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workItem.customerName,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.call,
                            size: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '0904.xxx.888',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: Icon(
                    Icons.chat,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    'Nhắn tin khách',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _shortId(String id) {
    final normalized = id.trim();
    if (normalized.isEmpty) return '----';
    return normalized.length <= 8
        ? normalized.toUpperCase()
        : normalized.substring(0, 8).toUpperCase();
  }

  Widget _buildWorkItemsSection(List<_WorkTask> tasks) {
    final completedCount = tasks.where((task) => task.isDone).length;
    final totalCount = tasks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Hạng mục công việc',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$completedCount/$totalCount Hoàn thành',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.onSurface.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              ...tasks.map((task) => _buildTaskItem(task)),
              const SizedBox(height: 8),
              _DashedActionButton(
                onTap: () {},
                label: 'Thêm hạng mục',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskItem(_WorkTask task) {
    final needsTool = task.subtitle != null &&
        task.subtitle!.toLowerCase().contains('cần thiết bị');

    if (task.isDone) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            _TaskCheckbox(isChecked: true),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.onSurfaceVariant,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  if (task.subtitle != null)
                    Text(
                      task.subtitle!,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TaskCheckbox(isChecked: false),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (task.subtitle != null)
                      Row(
                        children: [
                          if (needsTool)
                            Icon(
                              Icons.battery_charging_full,
                              size: 14,
                              color: AppColors.secondary,
                            ),
                          if (needsTool) const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              task.subtitle!,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: needsTool
                                    ? AppColors.secondary
                                    : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _TaskActionButton(
                label: 'Đánh dấu chờ',
                onTap: () {},
                textColor: AppColors.onSurface,
                borderColor: AppColors.outlineVariant.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              _TaskActionButton(
                label: 'Bỏ qua hạng mục',
                onTap: () {},
                textColor: AppColors.error,
                borderColor: AppColors.error.withOpacity(0.4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Xuất kho phụ tùng',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.onSurface.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Tìm kiếm phụ tùng...',
                  filled: true,
                  fillColor: AppColors.surfaceContainerHigh,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildPartItem(
                'Má phanh Brembo',
                'Tồn kho: 12 bộ',
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuCrE6r8BimfKawkwE84VxFTC5OCiS84Abb-APkAnNAbFg1VD7mns7bwwyiO-P2IwUXKfytXqEptSdjPKLIOYv3-fIHv-18_iTHTf8Gq-AKlQTeDSbVZXNJ0GeUre33szvo26oExnOCDAnRp9-iWIPxfiVTV86mXSXP1Uz-R_mrqwNtki37GtXLIvQhlKM3JsbvIzyQcZTtw5AZSMEEaxFIh8Y5WaIWVvXAdvs6a9XqEjdkRpMK9uZINML93mLlG2HY2CUPLCtttbDI',
              ),
              const SizedBox(height: 8),
              _buildPartItem(
                'Dầu xích Motul',
                'Tồn kho: 45 chai',
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuB47zzxN_IJJUAXUFm53wgu4gap6ID6gfDb7Ach7qvgj2sNXb7LFTjryEIkqR-Z-rbpHmSHOXfob5l5VNAbJG4z3johJz4FExAkpHHMn5cGLwX-3rBUhzsFKvohFwM_9KL_G2S8K3n49IqyQL9j2CQ_rPDZ8xK-M07WmnuUHGkfPEelbWEsu0fxZY_mnKSK67wQqvHl0_qmr-yYb21wkOfdVqoLAMx7f2u8UZzjjoWPTo3b-m1p05HZBs4Nb70syj2MmddG6Ncon-w',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPartItem(String name, String stock, {required String imageUrl}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.7),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.12),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stock,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.12),
              ),
            ),
            child: Row(
              children: [
                _QtyButton(
                  icon: Icons.remove,
                  onTap: () {},
                ),
                const SizedBox(width: 4),
                Text(
                  '1',
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                _QtyButton(
                  icon: Icons.add,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Báo cáo kỹ thuật',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.onSurface.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hình ảnh sau sửa (After)',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tải ảnh lên',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.image,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ghi chú cho lần bảo dưỡng sau',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Nhập ghi chú kỹ thuật...',
                  filled: true,
                  fillColor: AppColors.surfaceContainerHigh,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCostSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tổng kết chi phí',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _buildCostRow('Phí dịch vụ (Công thợ)', '150,000 đ'),
          _buildCostRow('Phụ tùng (2 mục)', '650,000 đ',
              subtitle: 'Tự động tính từ xuất kho'),
          _buildCostRow('Thuế VAT (8%)', '64,000 đ'),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: AppColors.surfaceContainerHigh,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng tiền',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '864,000 đ',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCostRow(String title, String value, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  List<_WorkTask> _buildTasks(String description) {
    final rawTasks = description
        .split(',')
        .map((task) => task.trim())
        .where((task) => task.isNotEmpty)
        .toList();

    if (rawTasks.isEmpty) {
      return const [
        _WorkTask(title: 'Kiểm tra pin', isDone: false, subtitle: 'Cần thiết bị đo chuyên dụng'),
        _WorkTask(title: 'Thay má phanh trước', isDone: true, subtitle: 'Thực hiện: 10:30 AM'),
        _WorkTask(title: 'Vệ sinh xích & bôi trơn', isDone: true, subtitle: 'Thực hiện: 11:15 AM'),
      ];
    }

    return List.generate(rawTasks.length, (index) {
      return _WorkTask(
        title: rawTasks[index],
        isDone: index < 2,
        subtitle: index < 2 ? 'Thực hiện: 10:${30 + (index * 15)} AM' : null,
      );
    });
  }

  String _statusLabel(WorkStatus status) {
    switch (status) {
      case WorkStatus.pending:
        return 'Chờ xử lý';
      case WorkStatus.inProgress:
        return 'Đang sửa';
      case WorkStatus.waitingParts:
        return 'Chờ phụ tùng';
      case WorkStatus.completed:
        return 'Hoàn thành';
    }
  }

  int _activeStepIndex(WorkStatus status) {
    switch (status) {
      case WorkStatus.pending:
        return 0;
      case WorkStatus.inProgress:
        return 2;
      case WorkStatus.waitingParts:
        return 2;
      case WorkStatus.completed:
        return 4;
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'KH';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _WorkTask {
  final String title;
  final bool isDone;
  final String? subtitle;

  const _WorkTask({
    required this.title,
    required this.isDone,
    this.subtitle,
  });
}

class _TaskCheckbox extends StatelessWidget {
  final bool isChecked;

  const _TaskCheckbox({
    required this.isChecked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: isChecked ? AppColors.primary : Colors.transparent,
        border: Border.all(
          color: isChecked ? AppColors.primary : AppColors.outlineVariant,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: isChecked
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }
}

class _TaskActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color textColor;
  final Color borderColor;

  const _TaskActionButton({
    required this.label,
    required this.onTap,
    required this.textColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _DashedActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;

  const _DashedActionButton({
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: AppColors.primary.withOpacity(0.45),
          radius: 12,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(radius),
        ),
      );

    const dashWidth = 6.0;
    const dashGap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        final segment = metric.extractPath(distance, next);
        canvas.drawPath(segment, paint);
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: AppColors.onSurface,
        ),
      ),
    );
  }
}

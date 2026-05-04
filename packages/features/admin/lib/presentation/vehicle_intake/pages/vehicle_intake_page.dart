import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../bloc/vehicle_intake_bloc.dart';

/// Vehicle Intake Page - 100% converted from HTML design
/// Follows Material Design 3 color system and "Kinetic Sanctuary" design philosophy
class VehicleIntakePage extends StatelessWidget {
  const VehicleIntakePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetIt.instance<VehicleIntakeBloc>(),
      child: const _VehicleIntakeView(),
    );
  }
}

class _VehicleIntakeView extends StatefulWidget {
  const _VehicleIntakeView();

  @override
  State<_VehicleIntakeView> createState() => _VehicleIntakeViewState();
}

class _VehicleIntakeViewState extends State<_VehicleIntakeView> {
  final _licensePlateController = TextEditingController();
  final _kmController = TextEditingController();
  final _notesController = TextEditingController();
  final _estimatedHoursController = TextEditingController(text: '2.5');

  @override
  void dispose() {
    _licensePlateController.dispose();
    _kmController.dispose();
    _notesController.dispose();
    _estimatedHoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VehicleIntakeBloc, VehicleIntakeState>(
      listener: (context, state) {
        if (state.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tạo phiếu tiếp nhận thành công!')),
          );
          Navigator.of(context).pop();
        } else if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${state.errorMessage}')),
          );
        }
      },
      child: Scaffold(
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
                      _buildStep1VehicleIdentification(),
                      const SizedBox(height: 24),
                      _buildStep2VisualDocumentation(),
                      const SizedBox(height: 24),
                      _buildStep3ServiceSelection(),
                      const SizedBox(height: 24),
                      _buildStep4AssignmentConfirmation(),
                      const SizedBox(height: 96), // Extra padding for bottom
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// TopAppBar with back button
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
          const SizedBox(width: 16),
          const Text(
            'Tiếp nhận xe mới',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF191C1E),
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          const Text(
            'EK',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF006E2F),
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  /// Step 1: Vehicle Identification
  Widget _buildStep1VehicleIdentification() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF), // surface-container-lowest
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF191C1E).withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Decorative gradient orb - positioned at top-right corner
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF22C55E).withOpacity(0.2),
                      const Color(0xFF22C55E).withOpacity(0),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step header
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E), // primary-container
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        '1',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF004B1E), // on-primary-container
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Định danh phương tiện',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF191C1E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // License plate input with QR button
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E3E5), // surface-container-highest
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _licensePlateController,
                        textInputAction: TextInputAction.done,
                        onChanged: (value) {
                          context.read<VehicleIntakeBloc>().add(
                            VehicleIntakeLicensePlateChanged(value),
                          );
                        },
                        onSubmitted: (value) {
                          context.read<VehicleIntakeBloc>().add(
                            VehicleIntakeLicensePlateSearched(value),
                          );
                        },
                        decoration: const InputDecoration(
                          hintText: 'Nhập biển số xe (VD: 29A-123.45)',
                          hintStyle: TextStyle(
                            color: Color(0x993D4A3D), // on-surface-variant/60
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                        style: const TextStyle(
                          color: Color(0xFF191C1E),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // QR Scanner button
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6E8EA), // surface-container-high
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF006E2F)),
                      onPressed: () {
                        // TODO: Implement QR scanner
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Pre-filled vehicle data (simulated)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F6), // surface-container-low
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Xe đã lưu trong hệ thống',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF3D4A3D),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'VinFast Klara S',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF006E2F),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Khách hàng: Nguyễn Văn A • 0901234567',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF3D4A3D),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6BFF8F), // primary-fixed
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: const Text(
                            'CÒN BẢO HÀNH',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF002109), // on-primary-fixed
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // KM and Color inputs
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SỐ KM HIỆN TẠI',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF3D4A3D),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0E3E5),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: TextField(
                                  controller: _kmController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: 'Nhập số KM...',
                                    hintStyle: TextStyle(fontSize: 13),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF191C1E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'MÀU XE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF3D4A3D),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Trắng ngọc trai',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF191C1E),
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
            ],
          ),
        ],
      ),
    ),
    );
  }

  /// Step 2: Visual Documentation
  Widget _buildStep2VisualDocumentation() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF191C1E).withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFE6E8EA), // surface-container-high
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '2',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3D4A3D), // on-surface-variant
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tình trạng ngoại quan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF191C1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Chụp ảnh các góc xe, vị trí xước xát (Tối đa 5 ảnh)',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF3D4A3D),
            ),
          ),
          const SizedBox(height: 16),
          // Photo grid
          BlocBuilder<VehicleIntakeBloc, VehicleIntakeState>(
            builder: (context, state) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: state.photoFiles.length + 1, // +1 for add button
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // Add photo button
                    return GestureDetector(
                      onTap: () {
                        // Show dialog to choose camera or gallery
                        showDialog(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Thêm ảnh'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.camera_alt),
                                  title: const Text('Chụp ảnh'),
                                  onTap: () {
                                    Navigator.pop(dialogContext);
                                    context.read<VehicleIntakeBloc>().add(
                                      const VehicleIntakePhotoCaptured(),
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.photo_library),
                                  title: const Text('Chọn từ thư viện'),
                                  onTap: () {
                                    Navigator.pop(dialogContext);
                                    context.read<VehicleIntakeBloc>().add(
                                      const VehicleIntakePhotoPickedFromGallery(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F9FB), // surface
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFBCCBB9), // outline-variant
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.add_a_photo,
                              size: 32,
                              color: Color(0xFF3D4A3D),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Thêm ảnh',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF3D4A3D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  // Photo thumbnails
                  final photoFile = state.photoFiles[index - 1];
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6E8EA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        // Display image from file
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            photoFile,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        // Delete button
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0E3E5).withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                context.read<VehicleIntakeBloc>().add(
                                  VehicleIntakePhotoRemoved(index - 1),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  /// Step 3: Service Selection
  Widget _buildStep3ServiceSelection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF191C1E).withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFE6E8EA),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '3',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3D4A3D),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Yêu cầu dịch vụ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF191C1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Service checkboxes grid
          BlocBuilder<VehicleIntakeBloc, VehicleIntakeState>(
            builder: (context, state) {
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildServiceCheckbox(
                    icon: Icons.handyman,
                    label: 'Bảo dưỡng định kỳ',
                    isChecked: state.maintenanceChecked,
                    onChanged: (val) => context.read<VehicleIntakeBloc>().add(
                      VehicleIntakeServiceToggled('maintenance', val ?? false),
                    ),
                  ),
                  _buildServiceCheckbox(
                    icon: Icons.battery_charging_full,
                    label: 'Kiểm tra pin/sạc',
                    isChecked: state.batteryChecked,
                    onChanged: (val) => context.read<VehicleIntakeBloc>().add(
                      VehicleIntakeServiceToggled('battery', val ?? false),
                    ),
                  ),
                  _buildServiceCheckbox(
                    icon: Icons.tire_repair,
                    label: 'Phanh & Lốp',
                    isChecked: state.brakesChecked,
                    onChanged: (val) => context.read<VehicleIntakeBloc>().add(
                      VehicleIntakeServiceToggled('brakes', val ?? false),
                    ),
                  ),
                  _buildServiceCheckbox(
                    icon: Icons.build_circle,
                    label: 'Sửa chữa khác',
                    isChecked: state.otherChecked,
                    onChanged: (val) => context.read<VehicleIntakeBloc>().add(
                      VehicleIntakeServiceToggled('other', val ?? false),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          // Notes textarea
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE0E3E5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ghi chú thêm về tình trạng xe hoặc yêu cầu đặc biệt của khách hàng...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: Color(0x993D4A3D),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
              ),
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF191C1E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Service checkbox item
  Widget _buildServiceCheckbox({
    required IconData icon,
    required String label,
    required bool isChecked,
    required ValueChanged<bool?> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!isChecked),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F6), // surface-container-low
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isChecked ? const Color(0xFF006E2F) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isChecked ? const Color(0xFF006E2F) : const Color(0xFF3D4A3D),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF191C1E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Step 4: Assignment & Confirmation
  Widget _buildStep4AssignmentConfirmation() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF191C1E).withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFE6E8EA),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '4',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3D4A3D),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Phân công & Thời gian',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF191C1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Technician select
          BlocBuilder<VehicleIntakeBloc, VehicleIntakeState>(
            builder: (context, state) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E3E5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'KTV PHỤ TRÁCH',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF3D4A3D),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: state.selectedTechnician,
                        isExpanded: true,
                        isDense: true,
                        padding: EdgeInsets.zero,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF191C1E),
                        ),
                        icon: const Icon(Icons.expand_more, color: Color(0xFF3D4A3D), size: 20),
                        items: const [
                          DropdownMenuItem(value: 'auto', child: Text('Tự động điều phối')),
                          DropdownMenuItem(value: 'ktv1', child: Text('Trần Văn Bình (Sẵn sàng)')),
                          DropdownMenuItem(value: 'ktv2', child: Text('Lê Quang Cường (Đang bận)')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            context.read<VehicleIntakeBloc>().add(
                              VehicleIntakeTechnicianChanged(value),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Estimated time input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E3E5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ƯỚC TÍNH THỜI GIAN (GIỜ)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF3D4A3D),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _estimatedHoursController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF191C1E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Submit button with gradient
          BlocBuilder<VehicleIntakeBloc, VehicleIntakeState>(
            builder: (context, state) {
              return SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: state.isSubmitting
                      ? null
                      : () {
                          context.read<VehicleIntakeBloc>().add(
                            const VehicleIntakeSubmitted(),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: const Color(0xFF22C55E).withOpacity(0.2),
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF006E2F), // primary
                          Color(0xFF22C55E), // primary-container
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: state.isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Tạo phiếu tiếp nhận',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

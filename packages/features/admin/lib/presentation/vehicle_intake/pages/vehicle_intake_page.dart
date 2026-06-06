import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:admin/data/models/work_order_model.dart';
import 'package:core/core.dart';
import '../bloc/vehicle_intake_bloc.dart';

/// Vehicle Intake Page - 100% converted from HTML design
/// Follows Material Design 3 color system and "Kinetic Sanctuary" design philosophy
class VehicleIntakePage extends StatelessWidget {
  final String? initialLicensePlate;

  const VehicleIntakePage({super.key, this.initialLicensePlate});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetIt.instance<VehicleIntakeBloc>(),
      child: _VehicleIntakeView(initialLicensePlate: initialLicensePlate),
    );
  }
}

class _VehicleIntakeView extends StatefulWidget {
  final String? initialLicensePlate;

  const _VehicleIntakeView({this.initialLicensePlate});

  @override
  State<_VehicleIntakeView> createState() => _VehicleIntakeViewState();
}

class _VehicleIntakeViewState extends State<_VehicleIntakeView> {
  final _licensePlateController = TextEditingController();
  final _kmController = TextEditingController();
  final _notesController = TextEditingController();
  final _estimatedHoursController = TextEditingController(text: '2.5');
  
  // New vehicle form controllers
  final _ownerNameController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _vehicleYearController = TextEditingController();
  final _vehicleColorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<VehicleIntakeBloc>();
      bloc.add(const VehicleIntakeTechniciansRequested());

      if (widget.initialLicensePlate != null && widget.initialLicensePlate!.isNotEmpty) {
        _licensePlateController.text = widget.initialLicensePlate!;
        bloc.add(VehicleIntakeLicensePlateSearched(widget.initialLicensePlate!));
      }
    });
  }

  @override
  void dispose() {
    _licensePlateController.dispose();
    _kmController.dispose();
    _notesController.dispose();
    _estimatedHoursController.dispose();
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
    _vehicleTypeController.dispose();
    _vehicleYearController.dispose();
    _vehicleColorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VehicleIntakeBloc, VehicleIntakeState>(
      listener: (context, state) {
        if (state.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tạo phiếu tiếp nhận thành công!'),
              backgroundColor: Color(0xFF22C55E),
              duration: Duration(seconds: 2),
            ),
          );
          // Reset form by clearing all controllers
          _licensePlateController.clear();
          _kmController.clear();
          _notesController.clear();
          _estimatedHoursController.text = '2.5';
          _ownerNameController.clear();
          _ownerPhoneController.clear();
          _vehicleTypeController.clear();
          _vehicleYearController.clear();
          _vehicleColorController.clear();
          
          // Reset BLoC state by creating a new instance
          // This will be handled by switching tabs
        } else if (state.vehicleFound && state.vehicleId != null) {
          if (_ownerNameController.text.isEmpty && state.ownerName.isNotEmpty) {
            _ownerNameController.text = state.ownerName;
          }
          if (_ownerPhoneController.text.isEmpty && state.ownerPhone.isNotEmpty) {
            _ownerPhoneController.text = state.ownerPhone;
          }
          if (_vehicleTypeController.text.isEmpty && state.vehicleModel?.isNotEmpty == true) {
            _vehicleTypeController.text = state.vehicleModel!;
          }
          if (_vehicleColorController.text.isEmpty && state.vehicleColor?.isNotEmpty == true) {
            _vehicleColorController.text = state.vehicleColor!;
          }
        } else if (state.errorMessage != null) {
          final isKmError = state.errorMessage!.contains('KM');
          if (!isKmError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
          }
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
    final canPop = Navigator.of(context).canPop();
    return Container(
      height: 60,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFECEEF0),
            width: 1.0,
          ),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Back button (left)
          if (canPop)
            Positioned(
              left: 0,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Color(0xFF191C1E),
                    size: 16,
                  ),
                ),
              ),
            ),
          // Centered title
          const Text(
            'Tiếp nhận xe mới',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF191C1E),
              letterSpacing: -0.2,
            ),
          ),
          // Pill indicator (right)
          Positioned(
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Text(
                'Phiếu mới',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF006E2F),
                ),
              ),
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
          border: Border.all(color: const Color(0xFFDBDEE0), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF191C1E).withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 6),
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
                      const Color(0xFF22C55E).withValues(alpha: 0.2),
                      const Color(0xFF22C55E).withValues(alpha: 0),
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
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFDBDEE0), width: 1),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _licensePlateController,
                        textInputAction: TextInputAction.done,
                        onChanged: (value) {
                           // Chỉ reset state xe khi giá trị thực sự thay đổi so với state hiện tại
                           final currentState = context.read<VehicleIntakeBloc>().state;
                           if (value != currentState.licensePlate) {
                             context.read<VehicleIntakeBloc>().add(
                               VehicleIntakeLicensePlateChanged(value),
                             );
                           }
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
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFDBDEE0), width: 1),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF006E2F)),
                      onPressed: () async {
                        final qrService = GetIt.instance<QRScannerService>();
                        final scannedCode = await qrService.scanQRCode(context);
                        
                        if (scannedCode != null && scannedCode.isNotEmpty) {
                          _licensePlateController.text = scannedCode;
                          if (mounted) {
                            context.read<VehicleIntakeBloc>().add(
                              VehicleIntakeLicensePlateChanged(scannedCode),
                            );
                            context.read<VehicleIntakeBloc>().add(
                              VehicleIntakeLicensePlateSearched(scannedCode),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Vehicle info display - conditional based on search state
              BlocBuilder<VehicleIntakeBloc, VehicleIntakeState>(
                builder: (context, state) {
                  // Show loading indicator when searching
                  if (state.isSearching) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFDBDEE0), width: 1),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  // Show vehicle info if found
                  if (state.vehicleFound && state.vehicleModel != null) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFDBDEE0), width: 1),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
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
                                  children: [
                                    const Text(
                                      'Xe đã lưu trong hệ thống',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF3D4A3D),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      state.vehicleModel ?? 'N/A',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF006E2F),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (state.warrantyStatus == true)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6BFF8F),
                                    borderRadius: BorderRadius.circular(9999),
                                  ),
                                  child: const Text(
                                    'CÒN BẢO HÀNH',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF002109),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Owner info
                          if (state.ownerName.isNotEmpty || state.ownerPhone.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CHỦ XE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF3D4A3D),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  state.ownerName.isNotEmpty ? state.ownerName : 'Chưa có thông tin',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF191C1E),
                                  ),
                                ),
                                if (state.ownerPhone.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    state.ownerPhone,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF191C1E),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                              ],
                            ),
                          // KM and Color inputs
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                            color: const Color(0xFFFFFFFF),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFFDBDEE0), width: 1),
                                          ),
                                          child: TextField(
                                            controller: _kmController,
                                            keyboardType: TextInputType.number,
                                            onChanged: (value) {
                                              context.read<VehicleIntakeBloc>().add(
                                                VehicleIntakeKmChanged(value),
                                              );
                                            },
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
                                      children: [
                                        const Text(
                                          'MÀU XE',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF3D4A3D),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          state.vehicleColor ?? 'Chưa có thông tin',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF191C1E),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (state.errorMessage != null && state.errorMessage!.contains('KM'))
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    _formatKmError(state.errorMessage!),
                                    softWrap: true,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }

                  // Show message if vehicle not found
                  if (state.licensePlate.isNotEmpty && !state.vehicleFound && !state.isSearching) {
                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4E6),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFFF9800),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: Color(0xFFFF9800)),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Xe chưa có trong hệ thống. Vui lòng nhập thông tin xe mới bên dưới.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF191C1E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // New vehicle form
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFDBDEE0), width: 1),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x12000000),
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'THÔNG TIN CHỦ XE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF3D4A3D),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Owner name
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFFFF),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFDBDEE0), width: 1),
                                ),
                                child: TextField(
                                  controller: _ownerNameController,
                                  onChanged: (value) {
                                    context.read<VehicleIntakeBloc>().add(
                                      VehicleIntakeOwnerNameChanged(value),
                                    );
                                  },
                                  decoration: const InputDecoration(
                                    hintText: 'Tên chủ xe *',
                                    hintStyle: TextStyle(fontSize: 13),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF191C1E),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Owner phone
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFFFF),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFDBDEE0), width: 1),
                                ),
                                child: TextField(
                                  controller: _ownerPhoneController,
                                  keyboardType: TextInputType.phone,
                                  onChanged: (value) {
                                    context.read<VehicleIntakeBloc>().add(
                                      VehicleIntakeOwnerPhoneChanged(value),
                                    );
                                  },
                                  decoration: const InputDecoration(
                                    hintText: 'Số điện thoại *',
                                    hintStyle: TextStyle(fontSize: 13),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF191C1E),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'THÔNG TIN XE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF3D4A3D),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Vehicle type
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFFFF),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFDBDEE0), width: 1),
                                ),
                                child: TextField(
                                  controller: _vehicleTypeController,
                                  onChanged: (value) {
                                    context.read<VehicleIntakeBloc>().add(
                                      VehicleIntakeVehicleTypeChanged(value),
                                    );
                                  },
                                  decoration: const InputDecoration(
                                    hintText: 'Loại xe (VD: VinFast Klara S) *',
                                    hintStyle: TextStyle(fontSize: 13),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF191C1E),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Year and Color row
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFFFFF),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFFDBDEE0), width: 1),
                                      ),
                                      child: TextField(
                                        controller: _vehicleYearController,
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) {
                                          context.read<VehicleIntakeBloc>().add(
                                            VehicleIntakeVehicleYearChanged(value),
                                          );
                                        },
                                        decoration: const InputDecoration(
                                          hintText: 'Năm SX',
                                          hintStyle: TextStyle(fontSize: 13),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        ),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF191C1E),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFFFFF),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFFDBDEE0), width: 1),
                                      ),
                                      child: TextField(
                                        controller: _vehicleColorController,
                                        onChanged: (value) {
                                          context.read<VehicleIntakeBloc>().add(
                                            VehicleIntakeVehicleColorChanged(value),
                                          );
                                        },
                                        decoration: const InputDecoration(
                                          hintText: 'Màu xe',
                                          hintStyle: TextStyle(fontSize: 13),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        ),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF191C1E),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // KM input
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFFFF),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFDBDEE0), width: 1),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextField(
                                      controller: _kmController,
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        context.read<VehicleIntakeBloc>().add(
                                          VehicleIntakeKmChanged(value),
                                        );
                                      },
                                      decoration: const InputDecoration(
                                        hintText: 'Số KM hiện tại',
                                        hintStyle: TextStyle(fontSize: 13),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF191C1E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (state.errorMessage != null && state.errorMessage!.contains('KM'))
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    _formatKmError(state.errorMessage!),
                                    softWrap: true,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
              // Vehicle history section (when vehicle is found)
              BlocBuilder<VehicleIntakeBloc, VehicleIntakeState>(
                builder: (context, state) {
                  if (!state.vehicleFound || state.vehicleId == null) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFDBDEE0), width: 1),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'LỊCH SỬ SỬA CHỮA',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF3D4A3D),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                if (state.isLoadingHistory)
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (state.vehicleHistory.isEmpty && !state.isLoadingHistory)
                              const Text(
                                'Chưa có lịch sử sửa chữa',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF3D4A3D),
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            else
                              ...state.vehicleHistory.take(3).map((WorkOrderModel workOrder) {
                                final wo = workOrder;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFFFF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            wo.orderNumber,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF006E2F),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(wo.status),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              _getStatusText(wo.status),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFFFFFFFF),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        wo.notes ?? 'Không có ghi chú',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF3D4A3D),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            if (state.vehicleHistory.length > 3)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '+ ${state.vehicleHistory.length - 3} lần sửa chữa khác',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF006E2F),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  String _formatKmError(String message) {
    return message.replaceFirst('Exception: ', '');
  }

  /// Step 2: Visual Documentation
  Widget _buildStep2VisualDocumentation() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDBDEE0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF191C1E).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 6),
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
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
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
                              color: const Color(0xFFE0E3E5).withValues(alpha: 0.8),
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
        border: Border.all(color: const Color(0xFFDBDEE0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF191C1E).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 6),
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
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDBDEE0), width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _notesController,
              maxLines: 3,
              onChanged: (value) {
                context.read<VehicleIntakeBloc>().add(
                  VehicleIntakeNotesChanged(value),
                );
              },
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
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isChecked ? const Color(0xFF006E2F) : const Color(0xFFDBDEE0),
            width: isChecked ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
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
            color: const Color(0xFF191C1E).withValues(alpha: 0.03),
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
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDBDEE0), width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
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
                        items: [
                          const DropdownMenuItem(value: 'auto', child: Text('Tự động điều phối')),
                          ...state.availableTechnicians.map((tech) {
                            return DropdownMenuItem(
                              value: tech.id,
                              child: Text(tech.name),
                            );
                          }),
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
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDBDEE0), width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'THỜI GIAN HOÀN THÀNH DỰ KIẾN (GIỜ)',
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
                  onChanged: (value) {
                    context.read<VehicleIntakeBloc>().add(
                      VehicleIntakeEstimatedHoursChanged(value),
                    );
                  },
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
                const SizedBox(height: 4),
                Text(
                  'Dùng để tính thời điểm hoàn thành dự kiến cho thợ và khách.',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF5F6B5F),
                    height: 1.3,
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
                    shadowColor: const Color(0xFF22C55E).withValues(alpha: 0.2),
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
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
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

  /// Helper method to get status color
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'PENDING':
        return const Color(0xFFFF9800); // Orange
      case 'IN_PROGRESS':
        return const Color(0xFF2196F3); // Blue
      case 'COMPLETED':
        return const Color(0xFF4CAF50); // Green
      case 'CANCELLED':
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  /// Helper method to get status text
  String _getStatusText(String? status) {
    switch (status) {
      case 'PENDING':
        return 'CHỜ XỬ LÝ';
      case 'IN_PROGRESS':
        return 'ĐANG SỬA';
      case 'COMPLETED':
        return 'HOÀN THÀNH';
      case 'CANCELLED':
        return 'ĐÃ HỦY';
      default:
        return 'KHÔNG RÕ';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:design_system/design_system.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/customer_vehicle.dart';
import '../../../domain/usecases/get_customer_vehicles.dart';
import '../bloc/appointment_bloc.dart';

class CreateAppointmentPage extends StatefulWidget {
  const CreateAppointmentPage({super.key});

  @override
  State<CreateAppointmentPage> createState() => _CreateAppointmentPageState();
}

class _CreateAppointmentPageState extends State<CreateAppointmentPage> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedServiceType;
  String? _selectedVehicleId;
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  List<CustomerVehicle> _vehicles = [];
  bool _isLoadingVehicles = true;

  final List<Map<String, dynamic>> _serviceTypes = [
    {
      'value': 'MAINTENANCE',
      'label': 'Bảo dưỡng định kỳ',
      'icon': Icons.build,
      'description': 'Thay dầu, kiểm tra tổng quát',
    },
    {
      'value': 'BATTERY_CHECK',
      'label': 'Kiểm tra pin/sạc',
      'icon': Icons.battery_charging_full,
      'description': 'Kiểm tra dung lượng, sạc pin',
    },
    {
      'value': 'BRAKES_TIRES',
      'label': 'Phanh & Lốp',
      'icon': Icons.tire_repair,
      'description': 'Thay phanh, lốp, kiểm tra an toàn',
    },
    {
      'value': 'OTHER_REPAIR',
      'label': 'Sửa chữa khác',
      'icon': Icons.handyman,
      'description': 'Các dịch vụ sửa chữa khác',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    final result = await GetIt.instance<GetCustomerVehicles>()();
    if (!mounted) return;
    result.fold(
      (_) => setState(() => _isLoadingVehicles = false),
      (vehicles) => setState(() {
        _vehicles = vehicles;
        _isLoadingVehicles = false;
      }),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppointmentBloc, AppointmentState>(
      listener: (context, state) {
        if (state is AppointmentCreated) {
          Navigator.of(context).pop(true);
        }
        if (state is AppointmentError) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        if (state is AppointmentLoading) {
          setState(() => _isSubmitting = true);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios, size: 20),
          ),
          title: Text(
            'Đặt lịch hẹn',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step 1: Vehicle
              _buildSectionTitle('1', 'Chọn xe'),
              const SizedBox(height: 12),
              _buildVehicleSelector(),
              const SizedBox(height: 28),

              // Step 2: Service type
              _buildSectionTitle('2', 'Chọn dịch vụ'),
              const SizedBox(height: 12),
              _buildServiceTypeSelector(),
              const SizedBox(height: 28),

              // Step 3: Date
              _buildSectionTitle('3', 'Chọn ngày'),
              const SizedBox(height: 12),
              _buildDatePicker(),
              const SizedBox(height: 28),

              // Step 4: Time
              _buildSectionTitle('4', 'Chọn giờ'),
              const SizedBox(height: 12),
              _buildTimePicker(),
              const SizedBox(height: 28),

              // Step 5: Notes
              _buildSectionTitle('5', 'Ghi chú (tuỳ chọn)'),
              const SizedBox(height: 12),
              _buildNotesField(),
              const SizedBox(height: 36),

              // Submit button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String step, String title) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              step,
              style: AppTextStyles.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: AppTextStyles.titleSmall.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleSelector() {
    if (_isLoadingVehicles) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    String? displayText;
    IconData displayIcon;
    if (_selectedVehicleId == null) {
      displayText = 'Chọn xe (không bắt buộc)';
      displayIcon = Icons.directions_car;
    } else if (_selectedVehicleId == 'none') {
      displayText = 'Không chọn xe';
      displayIcon = Icons.block;
    } else {
      final selected = _vehicles.firstWhere((v) => v.id == _selectedVehicleId);
      displayText = '${selected.brand ?? ''} ${selected.model} - ${selected.licensePlate}';
      displayIcon = Icons.directions_car;
    }

    return GestureDetector(
      onTap: _showVehiclePicker,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _selectedVehicleId != null
                ? AppColors.primary
                : AppColors.outlineVariant.withValues(alpha: 0.5),
            width: _selectedVehicleId != null ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              displayIcon,
              color: _selectedVehicleId != null
                  ? AppColors.primary
                  : AppColors.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayText,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: _selectedVehicleId != null
                      ? AppColors.onSurface
                      : AppColors.onSurfaceVariant,
                  fontWeight:
                      _selectedVehicleId != null ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 24,
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  void _showVehiclePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Chọn xe',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Icon(Icons.block, color: AppColors.onSurfaceVariant),
                  title: const Text('Không chọn xe'),
                  trailing: _selectedVehicleId == 'none' || _selectedVehicleId == null
                      ? Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() => _selectedVehicleId = 'none');
                    Navigator.of(ctx).pop();
                  },
                ),
                ..._vehicles.map((v) => ListTile(
                      leading: const Icon(Icons.directions_car),
                      title: Text('${v.brand ?? ''} ${v.model}'),
                      subtitle: Text(v.licensePlate),
                      trailing: _selectedVehicleId == v.id
                          ? Icon(Icons.check, color: AppColors.primary)
                          : null,
                      onTap: () {
                        setState(() => _selectedVehicleId = v.id);
                        Navigator.of(ctx).pop();
                      },
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildServiceTypeSelector() {
    return Column(
      children: _serviceTypes.map((service) {
        final isSelected = _selectedServiceType == service['value'];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () {
              setState(() => _selectedServiceType = service['value']);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryContainer.withValues(alpha: 0.25)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.outlineVariant.withValues(alpha: 0.5),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      service['icon'] as IconData,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service['label'] as String,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          service['description'] as String,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: AppColors.primary,
                      size: 22,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _selectedDate != null
                ? AppColors.primary
                : AppColors.outlineVariant.withValues(alpha: 0.5),
            width: _selectedDate != null ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: _selectedDate != null
                  ? AppColors.primary
                  : AppColors.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedDate != null
                    ? DateFormat('EEEE, dd/MM/yyyy', 'vi')
                        .format(_selectedDate!)
                    : 'Nhấn để chọn ngày',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: _selectedDate != null
                      ? AppColors.onSurface
                      : AppColors.onSurfaceVariant,
                  fontWeight:
                      _selectedDate != null ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return GestureDetector(
      onTap: _pickTime,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _selectedTime != null
                ? AppColors.primary
                : AppColors.outlineVariant.withValues(alpha: 0.5),
            width: _selectedTime != null ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              color: _selectedTime != null
                  ? AppColors.primary
                  : AppColors.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedTime != null
                    ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                    : 'Nhấn để chọn giờ',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: _selectedTime != null
                      ? AppColors.onSurface
                      : AppColors.onSurfaceVariant,
                  fontWeight:
                      _selectedTime != null ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: TextField(
        controller: _notesController,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'VD: Xe có tiếng kêu lạ ở phanh...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        style: AppTextStyles.bodyMedium,
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isValid = _selectedDate != null && _selectedTime != null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isValid && !_isSubmitting ? _submit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.onSurfaceVariant.withValues(alpha: 0.2),
          disabledForegroundColor: AppColors.onSurfaceVariant,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: isValid ? 4 : 0,
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Xác nhận đặt lịch',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _submit() {
    if (_selectedDate == null || _selectedTime == null) return;

    final scheduledAt = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    // Validate future date
    if (scheduledAt.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng chọn thời gian trong tương lai'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    context.read<AppointmentBloc>().add(
          CreateNewAppointment(
            scheduledAt: scheduledAt,
            serviceType: _selectedServiceType,
            notes: _notesController.text.trim().isNotEmpty
                ? _notesController.text.trim()
                : null,
            vehicleId: _selectedVehicleId == 'none' ? null : _selectedVehicleId,
          ),
        );
  }
}

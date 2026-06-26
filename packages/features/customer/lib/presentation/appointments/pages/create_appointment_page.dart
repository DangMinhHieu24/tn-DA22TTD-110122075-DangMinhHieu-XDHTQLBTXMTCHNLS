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
      'icon': Icons.build_circle_outlined,
      'color': const Color(0xFF006E2F),
      'description': 'Thay dầu, kiểm tra xe tổng quát',
    },
    {
      'value': 'BATTERY_CHECK',
      'label': 'Kiểm tra pin/sạc',
      'icon': Icons.battery_charging_full_outlined,
      'color': const Color(0xFF0058BE),
      'description': 'Kiểm tra dung lượng, sạc pin',
    },
    {
      'value': 'BRAKES_TIRES',
      'label': 'Phanh & Lốp',
      'icon': Icons.tire_repair_outlined,
      'color': const Color(0xFFE65100),
      'description': 'Thay phanh, lốp, kiểm tra an toàn',
    },
    {
      'value': 'OTHER_REPAIR',
      'label': 'Sửa chữa khác',
      'icon': Icons.handyman_outlined,
      'color': const Color(0xFF9E4036),
      'description': 'Các dịch vụ sửa chữa khác',
    },
  ];

  final List<String> _timeSlots = [
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '13:30',
    '14:30',
    '15:30',
    '16:30',
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
        if (vehicles.isNotEmpty) {
          _selectedVehicleId = vehicles.first.id;
        } else {
          _selectedVehicleId = 'none';
        }
      }),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double _getCompletionProgress() {
    double progress = 0.0;
    if (_selectedVehicleId != null) progress += 0.25;
    if (_selectedServiceType != null) progress += 0.25;
    if (_selectedDate != null) progress += 0.25;
    if (_selectedTime != null) progress += 0.25;
    return progress;
  }

  List<DateTime> _generateDates() {
    final list = <DateTime>[];
    final now = DateTime.now();
    for (int i = 0; i < 14; i++) {
      list.add(now.add(Duration(days: i)));
    }
    return list;
  }

  String _getWeekdayName(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'T2';
      case DateTime.tuesday:
        return 'T3';
      case DateTime.wednesday:
        return 'T4';
      case DateTime.thursday:
        return 'T5';
      case DateTime.friday:
        return 'T6';
      case DateTime.saturday:
        return 'T7';
      case DateTime.sunday:
        return 'CN';
      default:
        return '';
    }
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String? _getActiveTimeSlot() {
    if (_selectedTime == null) return null;
    final hr = _selectedTime!.hour.toString().padLeft(2, '0');
    final min = _selectedTime!.minute.toString().padLeft(2, '0');
    final slot = '$hr:$min';
    if (_timeSlots.contains(slot)) {
      return slot;
    }
    return 'custom';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateList = _generateDates();
    final progress = _getCompletionProgress();
    final activeTimeSlot = _getActiveTimeSlot();

    // Check if selected date is custom (not in the next 14 days)
    bool isCustomDateSelected = _selectedDate != null &&
        !dateList.any((d) => _isSameDay(d, _selectedDate));

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
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF191C1E)),
          ),
          title: Text(
            'Đặt lịch hẹn',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF191C1E),
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Smooth Animated Progress Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hoàn thiện hồ sơ đặt lịch',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 4,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECEEF0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: (MediaQuery.of(context).size.width - 40) * progress,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step 1: Selection of Vehicle
                    _buildSectionHeader('1', 'Chọn phương tiện'),
                    const SizedBox(height: 12),
                    _buildHorizontalVehicleSelector(),
                    const SizedBox(height: 28),

                    // Step 2: Selection of Service
                    _buildSectionHeader('2', 'Chọn dịch vụ cần xử lý'),
                    const SizedBox(height: 12),
                    _buildServiceGrid(),
                    const SizedBox(height: 28),

                    // Step 3: Selection of Date
                    _buildSectionHeader('3', 'Chọn ngày hẹn'),
                    const SizedBox(height: 12),
                    _buildHorizontalDateStrip(dateList, isCustomDateSelected),
                    const SizedBox(height: 28),

                    // Step 4: Selection of Time
                    _buildSectionHeader('4', 'Chọn khung giờ'),
                    const SizedBox(height: 12),
                    _buildTimeSlotGrid(activeTimeSlot),
                    const SizedBox(height: 28),

                    // Step 5: Description Notes
                    _buildSectionHeader('5', 'Ghi chú mô tả sự cố (nếu có)'),
                    const SizedBox(height: 12),
                    _buildNotesInput(),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomConfirmBar(),
      ),
    );
  }

  Widget _buildSectionHeader(String index, String title) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              index,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
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
            color: const Color(0xFF191C1E),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalVehicleSelector() {
    if (_isLoadingVehicles) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          // "Không chọn xe" option card
          _buildVehicleCard(
            id: 'none',
            title: 'Không chọn xe',
            subtitle: 'Bỏ qua bước này',
            icon: Icons.block_outlined,
            isSelected: _selectedVehicleId == 'none' || _selectedVehicleId == null,
          ),
          
          if (_vehicles.isEmpty)
            _buildEmptyVehicleCard()
          else
            ..._vehicles.map((v) {
              return _buildVehicleCard(
                id: v.id,
                title: v.model,
                subtitle: v.licensePlate,
                icon: Icons.directions_car_outlined,
                isSelected: _selectedVehicleId == v.id,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildEmptyVehicleCard() {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(left: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECEEF0)),
      ),
      child: Center(
        child: Text(
          'Bạn chưa thêm xe nào',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleCard({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedVehicleId = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 155,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFECEEF0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : const Color(0xFFF2F4F6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: isSelected ? AppColors.primary : const Color(0xFF3D4A3D),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isSelected ? AppColors.primary : const Color(0xFF191C1E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (isSelected)
              const Positioned(
                right: 0,
                top: 0,
                child: Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildServiceCard(_serviceTypes[0])),
            const SizedBox(width: 12),
            Expanded(child: _buildServiceCard(_serviceTypes[1])),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildServiceCard(_serviceTypes[2])),
            const SizedBox(width: 12),
            Expanded(child: _buildServiceCard(_serviceTypes[3])),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final value = service['value'] as String;
    final label = service['label'] as String;
    final icon = service['icon'] as IconData;
    final color = service['color'] as Color;
    final description = service['description'] as String;

    final isSelected = _selectedServiceType == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedServiceType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 105,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFECEEF0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.15)
                        : color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: color,
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.primary : const Color(0xFF191C1E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalDateStrip(List<DateTime> dateList, bool isCustomDateSelected) {
    return SizedBox(
      height: 76,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          ...dateList.map((date) {
            final isSelected = !isCustomDateSelected && _isSameDay(_selectedDate, date);
            return GestureDetector(
              onTap: () => _onDateSelected(date),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 60,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : const Color(0xFFECEEF0),
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    else
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _getWeekdayName(date),
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.75)
                            : AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${date.day}',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w900,
                        color: isSelected ? Colors.white : const Color(0xFF191C1E),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // "Chọn ngày khác..." fallback card
          GestureDetector(
            onTap: _pickDate,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 100,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isCustomDateSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCustomDateSelected ? AppColors.primary : const Color(0xFFECEEF0),
                ),
                boxShadow: [
                  if (isCustomDateSelected)
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 20,
                    color: isCustomDateSelected ? Colors.white : AppColors.primary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCustomDateSelected
                        ? DateFormat('dd/MM/yy').format(_selectedDate!)
                        : 'Ngày khác',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isCustomDateSelected ? Colors.white : const Color(0xFF191C1E),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotGrid(String? activeTimeSlot) {
    return Column(
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ..._timeSlots.map((slot) {
              final isSelected = activeTimeSlot == slot;
              return GestureDetector(
                onTap: () => _onTimeSlotSelected(slot),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: (MediaQuery.of(context).size.width - 70) / 4,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : const Color(0xFFECEEF0),
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      slot,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : const Color(0xFF191C1E),
                      ),
                    ),
                  ),
                ),
              );
            }),

            // "Khác..." time slot fallback card
            GestureDetector(
              onTap: _pickTime,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: (MediaQuery.of(context).size.width - 70) / 4 * 2 + 10, // Double width card
                height: 44,
                decoration: BoxDecoration(
                  color: activeTimeSlot == 'custom' ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: activeTimeSlot == 'custom' ? AppColors.primary : const Color(0xFFECEEF0),
                  ),
                  boxShadow: [
                    if (activeTimeSlot == 'custom')
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: activeTimeSlot == 'custom' ? Colors.white : AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        activeTimeSlot == 'custom'
                            ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                            : 'Giờ khác',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: activeTimeSlot == 'custom' ? Colors.white : const Color(0xFF191C1E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECEEF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16),
            child: Icon(
              Icons.sticky_note_2_outlined,
              size: 20,
              color: AppColors.primary.withValues(alpha: 0.6),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _notesController,
              maxLines: 3,
              style: AppTextStyles.bodyMedium.copyWith(
                color: const Color(0xFF191C1E),
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Nhập thông tin mô tả chi tiết sự cố xe...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomConfirmBar() {
    final hasDateAndTime = _selectedDate != null && _selectedTime != null;
    final hasService = _selectedServiceType != null;
    final isValid = hasDateAndTime && hasService;

    String dateSummary = '';
    if (_selectedDate != null && _selectedTime != null) {
      final timeStr =
          '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
      final dateStr = DateFormat('dd/MM/yyyy').format(_selectedDate!);
      dateSummary = '$timeStr, $dateStr';
    }

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFECEEF0), width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thời gian đã chọn',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isValid ? dateSummary : 'Chưa hoàn tất chọn',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isValid ? AppColors.primary : const Color(0xFF7986CB),
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: isValid && !_isSubmitting ? _submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFD8DADC),
              disabledForegroundColor: const Color(0xFF8A9A89),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: isValid ? 2 : 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Đặt lịch ngay',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  void _onTimeSlotSelected(String slot) {
    final parts = slot.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    setState(() {
      _selectedTime = TimeOfDay(hour: hour, minute: minute);
    });
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
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF191C1E),
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
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF191C1E),
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

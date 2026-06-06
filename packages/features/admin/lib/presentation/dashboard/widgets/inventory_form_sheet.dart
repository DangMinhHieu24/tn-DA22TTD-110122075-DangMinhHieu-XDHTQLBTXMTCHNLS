import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/inventory_model.dart';

typedef OnFormSubmit = void Function(Map<String, dynamic> data);

class InventoryFormSheet extends StatefulWidget {
  final InventoryModel? item; // null = create, non-null = edit
  final OnFormSubmit onSubmit;

  const InventoryFormSheet({
    super.key,
    this.item,
    required this.onSubmit,
  });

  static void showCreate(BuildContext context, OnFormSubmit onSubmit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InventoryFormSheet(onSubmit: onSubmit),
    );
  }

  static void showEdit(BuildContext context, InventoryModel item, OnFormSubmit onSubmit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InventoryFormSheet(item: item, onSubmit: onSubmit),
    );
  }

  @override
  State<InventoryFormSheet> createState() => _InventoryFormSheetState();
}

class _InventoryFormSheetState extends State<InventoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _thresholdCtrl;
  late final TextEditingController _unitPriceCtrl;
  late final TextEditingController _sellPriceCtrl;
  late final TextEditingController _warrantyDaysCtrl;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameCtrl = TextEditingController(text: item?.partName ?? '');
    _qtyCtrl = TextEditingController(text: item?.quantity.toString() ?? '0');
    _thresholdCtrl = TextEditingController(text: item?.minThreshold.toString() ?? '5');
    _unitPriceCtrl = TextEditingController(text: item?.unitPrice.toStringAsFixed(0) ?? '');
    _sellPriceCtrl = TextEditingController(text: item?.sellPrice.toStringAsFixed(0) ?? '');
    _warrantyDaysCtrl = TextEditingController(text: item?.warrantyDays.toString() ?? '0');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _thresholdCtrl.dispose();
    _unitPriceCtrl.dispose();
    _sellPriceCtrl.dispose();
    _warrantyDaysCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final data = {
      'partName': _nameCtrl.text.trim(),
      'quantity': int.tryParse(_qtyCtrl.text) ?? 0,
      'minThreshold': int.tryParse(_thresholdCtrl.text) ?? 5,
      'unitPrice': double.tryParse(_unitPriceCtrl.text.replaceAll(',', '')) ?? 0,
      'sellPrice': double.tryParse(_sellPriceCtrl.text.replaceAll(',', '')) ?? 0,
      'warrantyDays': int.tryParse(_warrantyDaysCtrl.text) ?? 0,
    };
    Navigator.pop(context);
    widget.onSubmit(data);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBDEE0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                _isEdit ? 'Chỉnh sửa phụ tùng' : 'Thêm phụ tùng mới',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF191C1E),
                ),
              ),
              const SizedBox(height: 24),

              // Tên phụ tùng
              _buildLabel('Tên phụ tùng *'),
              _buildTextField(
                controller: _nameCtrl,
                hint: 'VD: Phanh trước VinFast Klara',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 16),

              // Số lượng + Ngưỡng cảnh báo (2 cột)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Tồn kho'),
                        _buildTextField(
                          controller: _qtyCtrl,
                          hint: '0',
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Ngưỡng cảnh báo'),
                        _buildTextField(
                          controller: _thresholdCtrl,
                          hint: '5',
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Giá nhập + Giá bán (2 cột)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Giá nhập (VNĐ)'),
                        _buildTextField(
                          controller: _unitPriceCtrl,
                          hint: '0',
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Giá bán (VNĐ)'),
                        _buildTextField(
                          controller: _sellPriceCtrl,
                          hint: '0',
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Bảo hành (ngày)
              _buildLabel('Bảo hành (ngày)'),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _warrantyDaysCtrl,
                      hint: '0 = không BH',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.info_outline, size: 16, color: Color(0xFF6D7B6C)),
                ],
              ),
              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006E2F),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    _isEdit ? 'Lưu thay đổi' : 'Thêm phụ tùng',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF3D4A3D),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: Color(0xFF191C1E)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFBCCBB9)),
        filled: true,
        fillColor: const Color(0xFFF7F9FB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDBDEE0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDBDEE0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF006E2F), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
        ),
      ),
    );
  }
}

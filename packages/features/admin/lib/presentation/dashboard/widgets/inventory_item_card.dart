import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../data/models/inventory_model.dart';
import '../bloc/inventory_bloc.dart';
import '../bloc/inventory_event.dart';
import 'inventory_form_sheet.dart';

class InventoryItemCard extends StatelessWidget {
  final InventoryModel item;

  const InventoryItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<InventoryBloc>();
    final currencyFmt = NumberFormat.decimalPattern('vi');

    // Status
    final String statusLabel;
    final Color statusBg;
    final Color statusText;
    if (item.quantity == 0) {
      statusLabel = 'HẾT HÀNG';
      statusBg = const Color(0xFFFFDAD6);
      statusText = const Color(0xFF93000A);
    } else if (item.isBelowThreshold) {
      statusLabel = 'SẮP HẾT';
      statusBg = const Color(0xFFFFF7D1);
      statusText = const Color(0xFF6B5200);
    } else {
      statusLabel = 'CÒN HÀNG';
      statusBg = const Color(0xFFD6FBE5);
      statusText = const Color(0xFF0F5F2A);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF191C1E).withValues(alpha: 0.06),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Top row: image + info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Part image
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F6),
                  borderRadius: BorderRadius.circular(8),
                  image: item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(item.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: item.imageUrl == null || item.imageUrl!.isEmpty
                    ? const Icon(Icons.inventory_2_outlined, size: 32, color: Color(0xFFBCCBB9))
                    : null,
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.partName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF191C1E),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'SKU-${item.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6D7B6C),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Status + quantity adjuster row
                    Row(
                      children: [
                        // Status pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusText,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Quantity adjuster pill
                        Container(
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F4F6),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFBCCBB9).withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildAdjustBtn(
                                icon: Icons.remove,
                                onTap: item.quantity > 0
                                    ? () => bloc.add(AdjustInventoryQuantity(item.id, -1))
                                    : null,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  '${item.quantity}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF191C1E),
                                  ),
                                ),
                              ),
                              _buildAdjustBtn(
                                icon: Icons.add,
                                onTap: () => bloc.add(AdjustInventoryQuantity(item.id, 1)),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(right: 6),
                                child: Text(
                                  'chiếc',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF3D4A3D),
                                  ),
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

          // Divider
          Container(
            margin: const EdgeInsets.only(top: 10),
            height: 1,
            color: const Color(0xFFE6E8EA),
          ),

          // Bottom: price + edit button
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${currencyFmt.format(item.sellPrice.toInt())} ₫',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF191C1E),
                    fontFamily: 'Manrope',
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    InventoryFormSheet.showEdit(context, item, (data) {
                      bloc.add(UpdateInventoryItem(item.id, data));
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: Color(0xFF006E2F),
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

  Widget _buildAdjustBtn({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 24,
        height: 28,
        child: Icon(
          icon,
          size: 14,
          color: onTap == null ? const Color(0xFFBCCBB9) : const Color(0xFF3D4A3D),
        ),
      ),
    );
  }
}

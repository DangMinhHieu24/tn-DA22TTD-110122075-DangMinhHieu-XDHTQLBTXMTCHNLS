import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class DraggableFab extends StatefulWidget {
  final VoidCallback? onTap;
  final Offset initialPosition;

  const DraggableFab({
    super.key,
    this.onTap,
    this.initialPosition = const Offset(8, 450),
  });

  @override
  State<DraggableFab> createState() => _DraggableFabState();
}

class _DraggableFabState extends State<DraggableFab> {
  late Offset _position;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: Draggable(
        feedback: _buildFABButton(isDragging: true),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: _buildFABButton(isDragging: false),
        ),
        onDragEnd: (details) {
          setState(() {
            final screenSize = MediaQuery.of(context).size;
            final centerX = screenSize.width / 2;
            
            // Snap to left or right edge based on position
            final snapToLeft = details.offset.dx < centerX;
            final newX = snapToLeft ? 8.0 : screenSize.width - 140.0;
            
            // Keep Y within bounds
            final newY = details.offset.dy.clamp(80.0, screenSize.height - 140);
            
            _position = Offset(newX, newY);
          });
        },
        onDragStarted: () {},
        child: _buildFABButton(isDragging: false),
      ),
    );
  }

  Widget _buildFABButton({required bool isDragging}) {
    return Material(
      elevation: isDragging ? 12 : 8,
      borderRadius: BorderRadius.circular(28),
      shadowColor: AppColors.primary.withOpacity(0.4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF00A86B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: InkWell(
          onTap: isDragging ? null : widget.onTap,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Tiếp nhận',
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
    );
  }
}

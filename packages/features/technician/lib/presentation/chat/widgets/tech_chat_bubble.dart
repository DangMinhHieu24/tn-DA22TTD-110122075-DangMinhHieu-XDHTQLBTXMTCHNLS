import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import '../domain/entities/tech_chat_message.dart';

class TechChatBubble extends StatelessWidget {
  final TechChatMessage message;
  final bool showTimestamp;

  const TechChatBubble({
    super.key,
    required this.message,
    this.showTimestamp = true,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == TechMessageRole.user;
    final isTyping = message.isTyping;

    if (message.role == TechMessageRole.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.onSurface.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message.content,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 60 : 0,
        right: isUser ? 0 : 60,
        top: 5,
        bottom: 2,
      ),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF006E2F), Color(0xFF059669)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.smart_toy_rounded,
                        size: 12, color: Colors.white),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Trợ lý KTV',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          if (isTyping)
            _buildTypingBubble()
          else
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF006E2F)
                    : const Color(0xFFF0F4F1),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isUser
                            ? const Color(0xFF006E2F)
                            : AppColors.onSurface)
                        .withValues(alpha: isUser ? 0.15 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      letterSpacing: 0.15,
                      color: isUser
                          ? Colors.white
                          : const Color(0xFF191C1E),
                    ),
                  ),
                  if (showTimestamp) ...[
                    const SizedBox(height: 6),
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isUser
                            ? Colors.white.withValues(alpha: 0.6)
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
          bottomLeft: Radius.circular(4),
        ),
      ),
      child: _TypingDots(),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Animation<double>> _dots;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _dots = List.generate(3, (i) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _ctrl,
          curve: Interval(i * 0.18, 0.5 + i * 0.18, curve: Curves.easeInOut),
        ),
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _dots[i],
          builder: (_, __) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF006E2F)
                      .withValues(alpha: 0.25 + 0.55 * _dots[i].value),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

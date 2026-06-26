import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class ChatInputBar extends StatefulWidget {
  final ValueChanged<String> onSend;

  const ChatInputBar({super.key, required this.onSend});

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
    setState(() => _hasText = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 4,
        bottom: MediaQuery.of(context).padding.bottom + 4,
        top: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: _controller,
                maxLines: 4,
                minLines: 1,
                onChanged: (v) => setState(() => _hasText = v.trim().isNotEmpty),
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Material(
            color: _hasText ? AppColors.primary : AppColors.primary.withValues(alpha: 0.4),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: _hasText ? _send : null,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  Icons.send_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

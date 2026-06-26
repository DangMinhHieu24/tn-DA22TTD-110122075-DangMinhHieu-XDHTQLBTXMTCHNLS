import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class TechChatInputBar extends StatefulWidget {
  final ValueChanged<String> onSend;

  const TechChatInputBar({super.key, required this.onSend});

  @override
  State<TechChatInputBar> createState() => _TechChatInputBarState();
}

class _TechChatInputBarState extends State<TechChatInputBar> {
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
        right: 8,
        bottom: MediaQuery.of(context).padding.bottom + 6,
        top: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.onSurface.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4F1),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: _hasText
                      ? const Color(0xFF006E2F).withValues(alpha: 0.3)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: _controller,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onChanged: (v) => setState(() => _hasText = v.trim().isNotEmpty),
                onSubmitted: (_) => _hasText ? _send() : null,
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                ),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: const Color(0xFF191C1E),
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _hasText ? 44 : 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: _hasText
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF006E2F), Color(0xFF059669)],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF006E2F).withValues(alpha: 0.3),
                        const Color(0xFF059669).withValues(alpha: 0.3),
                      ],
                    ),
              shape: BoxShape.circle,
              boxShadow: _hasText
                  ? [
                      BoxShadow(
                        color: const Color(0xFF006E2F).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: InkWell(
              onTap: _hasText ? _send : null,
              customBorder: const CircleBorder(),
              child: const Icon(
                Icons.send_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:design_system/design_system.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import 'chat_bubble.dart';
import 'chat_input_bar.dart';
import 'chat_suggestions.dart';

void showChatPanel(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      snap: true,
      snapSizes: const [0.5, 0.8, 0.92],
      builder: (_, scrollCtrl) => _ChatPanel(scrollController: scrollCtrl),
    ),
  );
}

class ChatFloatingBubble extends StatefulWidget {
  const ChatFloatingBubble({super.key});

  @override
  State<ChatFloatingBubble> createState() => _ChatFloatingBubbleState();
}

class _ChatFloatingBubbleState extends State<ChatFloatingBubble> with SingleTickerProviderStateMixin {
  late final ValueNotifier<Offset> _positionNotifier;
  bool _isDragging = false;
  late AnimationController _animationController;
  Animation<Offset>? _animation;
  static const String _positionKey = 'chat_bubble_position';

  @override
  void initState() {
    super.initState();
    // Vị trí mặc định: góc dưới phải, cách lề 16px
    _positionNotifier = ValueNotifier<Offset>(const Offset(double.infinity, double.infinity));
    _loadSavedPosition();
    
    // Animation controller cho snap effect
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Lắng nghe animation thay đổi để cập nhật notifier
    _animationController.addListener(() {
      if (_animation != null) {
        _positionNotifier.value = _animation!.value;
      }
    });
  }

  // Load vị trí đã lưu từ SharedPreferences
  Future<void> _loadSavedPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final x = prefs.getDouble('${_positionKey}_x');
      final y = prefs.getDouble('${_positionKey}_y');
      
      if (x != null && y != null && mounted) {
        _positionNotifier.value = Offset(x, y);
      }
    } catch (e) {
      // Ignore errors, use default position
    }
  }

  // Lưu vị trí vào SharedPreferences
  Future<void> _savePosition(Offset position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('${_positionKey}_x', position.dx);
      await prefs.setDouble('${_positionKey}_y', position.dy);
    } catch (e) {
      // Ignore errors
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _positionNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatBloc = GetIt.instance<Bloc<ChatEvent, ChatState>>();
    final screenSize = MediaQuery.of(context).size;

    return ValueListenableBuilder<Offset>(
      valueListenable: _positionNotifier,
      builder: (context, position, child) {
        // Tính vị trí thực tế nếu dùng infinity
        final actualX = position.dx == double.infinity 
            ? screenSize.width - 72  // 56 (width) + 16 (margin)
            : position.dx;
        final actualY = position.dy == double.infinity
            ? screenSize.height - 150  // Cách bottom 150px để tránh navigation
            : position.dy;

        return Positioned(
          left: actualX,
          top: actualY,
          child: child!,
        );
      },
      child: GestureDetector(
        onPanStart: (_) {
          setState(() {
            _isDragging = true;
          });
          _animationController.stop();
          _animation = null; // Hủy animation khi bắt đầu kéo

          // Giải quyết giá trị vô hạn thành tọa độ thực tế ngay khi bắt đầu kéo
          if (_positionNotifier.value.dx == double.infinity) {
            _positionNotifier.value = Offset(
              screenSize.width - 72,
              screenSize.height - 150,
            );
          }
        },
        onPanUpdate: (details) {
          final current = _positionNotifier.value;
          // Cập nhật vị trí khi kéo
          double newX = current.dx + details.delta.dx;
          double newY = current.dy + details.delta.dy;

          // Giới hạn trong màn hình (để không bị kéo ra ngoài)
          newX = newX.clamp(0.0, screenSize.width - 56);
          newY = newY.clamp(0.0, screenSize.height - 56);

          _positionNotifier.value = Offset(newX, newY);
        },
        onPanEnd: (_) {
          setState(() => _isDragging = false);
          _snapToEdge(screenSize);
        },
        onTap: _isDragging ? null : () => showChatPanel(context),
        child: BlocBuilder<Bloc<ChatEvent, ChatState>, ChatState>(
          bloc: chatBloc,
          builder: (context, state) {
            final unread = state is ChatLoaded ? state.unreadCount : 0;

            return AnimatedScale(
              scale: _isDragging ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF006E2F), Color(0xFF059669)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: _isDragging ? 0.6 : 0.4),
                      blurRadius: _isDragging ? 20 : 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Center(
                      child: Icon(
                        Icons.chat_bubble_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    if (unread > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFDC2626),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Text(
                            unread > 99 ? '99+' : '$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Tự động dính vào cạnh gần nhất (như Messenger) với animation
  void _snapToEdge(Size screenSize) {
    final currentPosition = _positionNotifier.value;
    final currentX = currentPosition.dx == double.infinity 
        ? screenSize.width - 72 
        : currentPosition.dx;
    final currentY = currentPosition.dy == double.infinity
        ? screenSize.height - 150
        : currentPosition.dy;

    // Tính khoảng cách đến cạnh trái và phải
    final distanceToLeft = currentX;
    final distanceToRight = screenSize.width - currentX - 56;

    // Dính vào cạnh gần nhất
    final targetX = distanceToLeft < distanceToRight ? 16.0 : screenSize.width - 72.0;

    // Giữ nguyên Y nhưng đảm bảo trong phạm vi
    final targetY = currentY.clamp(50.0, screenSize.height - 150.0);

    final targetPosition = Offset(targetX, targetY);

    // Lưu vị trí mới
    _savePosition(targetPosition);

    // Tạo animation từ vị trí hiện tại đến vị trí target
    _animation = Tween<Offset>(
      begin: Offset(currentX, currentY),
      end: targetPosition,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack, // Hiệu ứng bounce nhẹ
    ));

    _animationController.forward(from: 0).then((_) {
      _positionNotifier.value = targetPosition;
      _animation = null;
    });
  }
}

class _ChatPanel extends StatelessWidget {
  final ScrollController scrollController;
  const _ChatPanel({required this.scrollController});

  Bloc<ChatEvent, ChatState> get _chatBloc => GetIt.instance<Bloc<ChatEvent, ChatState>>();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            _PanelHeader(),
            Expanded(
              child: BlocBuilder<Bloc<ChatEvent, ChatState>, ChatState>(
                bloc: _chatBloc,
                builder: (context, state) {
                  if (state is ChatLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is ChatError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          state.message,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  if (state is ChatLoaded) {
                    final messages = state.messages;
                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.support_agent,
                              size: 48,
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Bạn cần hỗ trợ gì?',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (_, i) => ChatBubble(message: messages[i]),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            BlocBuilder<Bloc<ChatEvent, ChatState>, ChatState>(
              bloc: _chatBloc,
              builder: (context, state) {
                final showSuggestions =
                    state is ChatLoaded && state.messages.length <= 2;
                if (showSuggestions) {
                  return ChatSuggestions(
                    onTap: (text) => _chatBloc.add(ChatSendMessage(text)),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            ChatInputBar(
              onSend: (text) => _chatBloc.add(ChatSendMessage(text)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final chatBloc = GetIt.instance<Bloc<ChatEvent, ChatState>>();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.onSurface.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hỗ trợ Xanh EV',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                BlocBuilder<Bloc<ChatEvent, ChatState>, ChatState>(
                  bloc: chatBloc,
                  builder: (context, state) {
                    final isTyping = state is ChatLoaded && state.isTyping;
                    return Text(
                      isTyping ? 'đang trả lời...' : 'Trực tuyến',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 11,
                        color: isTyping
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.onSurface.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(
                Icons.close,
                size: 18,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

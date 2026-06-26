import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:design_system/design_system.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../bloc/tech_chat_bloc.dart';
import '../bloc/tech_chat_event.dart';
import '../bloc/tech_chat_state.dart';
import 'tech_chat_bubble.dart';
import 'tech_chat_input_bar.dart';
import 'tech_chat_suggestions.dart';

void showTechChatPanel(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [0.5, 0.85, 0.95],
      builder: (_, scrollCtrl) => _TechChatPanel(scrollController: scrollCtrl),
    ),
  );
}

class TechChatFloatingBubble extends StatefulWidget {
  const TechChatFloatingBubble({super.key});

  @override
  State<TechChatFloatingBubble> createState() => _TechChatFloatingBubbleState();
}

class _TechChatFloatingBubbleState extends State<TechChatFloatingBubble>
    with SingleTickerProviderStateMixin {
  late final ValueNotifier<Offset> _positionNotifier;
  bool _isDragging = false;
  late AnimationController _animationController;
  Animation<Offset>? _animation;
  static const String _positionKey = 'tech_chat_bubble_position';

  static const _bubbleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A5631), Color(0xFF006E2F), Color(0xFF059669)],
    stops: [0.0, 0.5, 1.0],
  );

  @override
  void initState() {
    super.initState();
    _positionNotifier =
        ValueNotifier<Offset>(const Offset(double.infinity, double.infinity));
    _loadSavedPosition();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.addListener(() {
      if (_animation != null) {
        _positionNotifier.value = _animation!.value;
      }
    });
  }

  Future<void> _loadSavedPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final x = prefs.getDouble('${_positionKey}_x');
      final y = prefs.getDouble('${_positionKey}_y');
      if (x != null && y != null && mounted) {
        _positionNotifier.value = Offset(x, y);
      }
    } catch (_) {}
  }

  Future<void> _savePosition(Offset position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('${_positionKey}_x', position.dx);
      await prefs.setDouble('${_positionKey}_y', position.dy);
    } catch (_) {}
  }

  @override
  void dispose() {
    _animationController.dispose();
    _positionNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatBloc = GetIt.instance<TechChatBloc>();
    final screenSize = MediaQuery.of(context).size;

    return ValueListenableBuilder<Offset>(
      valueListenable: _positionNotifier,
      builder: (context, position, child) {
        final actualX = position.dx == double.infinity
            ? screenSize.width - 72
            : position.dx;
        final actualY = position.dy == double.infinity
            ? screenSize.height - 150
            : position.dy;

        return Positioned(left: actualX, top: actualY, child: child!);
      },
      child: GestureDetector(
        onPanStart: (_) {
          setState(() => _isDragging = true);
          _animationController.stop();
          _animation = null;
          if (_positionNotifier.value.dx == double.infinity) {
            _positionNotifier.value = Offset(
              screenSize.width - 72,
              screenSize.height - 150,
            );
          }
        },
        onPanUpdate: (details) {
          final current = _positionNotifier.value;
          double newX =
              (current.dx + details.delta.dx).clamp(0.0, screenSize.width - 56);
          double newY =
              (current.dy + details.delta.dy).clamp(0.0, screenSize.height - 56);
          _positionNotifier.value = Offset(newX, newY);
        },
        onPanEnd: (_) {
          setState(() => _isDragging = false);
          _snapToEdge(screenSize);
        },
        onTap: _isDragging ? null : () => showTechChatPanel(context),
        child: BlocBuilder<TechChatBloc, TechChatState>(
          bloc: chatBloc,
          builder: (context, state) {
            final unread = state is TechChatLoaded ? state.unreadCount : 0;
            return AnimatedScale(
              scale: _isDragging ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: _bubbleGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF006E2F)
                          .withValues(alpha: _isDragging ? 0.6 : 0.35),
                      blurRadius: _isDragging ? 20 : 14,
                      spreadRadius: _isDragging ? 2 : 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Center(
                      child: Icon(
                        Icons.build_circle_outlined,
                        color: Colors.white,
                        size: 26,
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

  void _snapToEdge(Size screenSize) {
    final currentPosition = _positionNotifier.value;
    final currentX = currentPosition.dx == double.infinity
        ? screenSize.width - 72
        : currentPosition.dx;
    final currentY = currentPosition.dy == double.infinity
        ? screenSize.height - 150
        : currentPosition.dy;
    final distanceToLeft = currentX;
    final distanceToRight = screenSize.width - currentX - 56;
    final targetX =
        distanceToLeft < distanceToRight ? 16.0 : screenSize.width - 72.0;
    final targetY = currentY.clamp(50.0, screenSize.height - 150.0);
    final targetPosition = Offset(targetX, targetY);
    _savePosition(targetPosition);
    _animation = Tween<Offset>(
      begin: Offset(currentX, currentY),
      end: targetPosition,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    _animationController.forward(from: 0).then((_) {
      _positionNotifier.value = targetPosition;
      _animation = null;
    });
  }
}

class _TechChatPanel extends StatelessWidget {
  final ScrollController scrollController;
  const _TechChatPanel({required this.scrollController});

  TechChatBloc get _chatBloc => GetIt.instance<TechChatBloc>();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          children: [
            _TechPanelHeader(),
            Divider(height: 0, color: AppColors.onSurface.withValues(alpha: 0.08)),
            Expanded(
              child: BlocBuilder<TechChatBloc, TechChatState>(
                bloc: _chatBloc,
                builder: (context, state) {
                  if (state is TechChatLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF006E2F)),
                      ),
                    );
                  }
                  if (state is TechChatError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline_rounded,
                                size: 48, color: AppColors.error),
                            const SizedBox(height: 16),
                            Text(
                              state.message,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.error,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (state is TechChatLoaded) {
                    final messages = state.messages;
                    if (messages.isEmpty) {
                      return _buildEmptyState();
                    }
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      itemCount: messages.length,
                      itemBuilder: (_, i) =>
                          TechChatBubble(message: messages[i]),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            BlocBuilder<TechChatBloc, TechChatState>(
              bloc: _chatBloc,
              builder: (context, state) {
                final showSuggestions =
                    state is TechChatLoaded && state.messages.length <= 2;
                if (showSuggestions) {
                  return TechChatSuggestions(
                    onTap: (text) => _chatBloc.add(TechChatSendMessage(text)),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            _buildSafeArea(),
            TechChatInputBar(
              onSend: (text) => _chatBloc.add(TechChatSendMessage(text)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 40,
                color: Color(0xFF006E2F),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Trợ lý KTV',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF191C1E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hỏi tôi bất cứ điều gì về xe,\nphụ tùng và phiếu sửa chữa',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafeArea() {
    return Container(
      color: AppColors.surface,
      height: 0,
    );
  }
}

class _TechPanelHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final chatBloc = GetIt.instance<TechChatBloc>();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF8FAFB),
            AppColors.surface,
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF006E2F), Color(0xFF059669)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF006E2F).withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.smart_toy_rounded, size: 22, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Trợ lý KTV',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF191C1E),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                BlocBuilder<TechChatBloc, TechChatState>(
                  bloc: chatBloc,
                  builder: (context, state) {
                    final isTyping =
                        state is TechChatLoaded && state.isTyping;
                    return Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: isTyping
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isTyping ? 'đang trả lời...' : 'Trực tuyến',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isTyping ? FontWeight.w600 : FontWeight.w400,
                            color: isTyping
                                ? const Color(0xFF16A34A)
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.onSurface.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 22,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

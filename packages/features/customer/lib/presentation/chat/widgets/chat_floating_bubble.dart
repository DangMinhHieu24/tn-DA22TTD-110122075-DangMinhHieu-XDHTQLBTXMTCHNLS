import 'dart:async';
import 'dart:convert';
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
import '../domain/entities/chat_message.dart';
import '../data/datasources/chat_remote_datasource.dart';
import '../data/models/chat_message_model.dart';

void showChatPanel(BuildContext context, {int initialTab = 0}) {
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
      builder: (_, scrollCtrl) => _ChatPanel(
        scrollController: scrollCtrl,
        initialTab: initialTab,
      ),
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
    final chatBloc = GetIt.instance<ChatBloc>();
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
        child: BlocBuilder<ChatBloc, ChatState>(
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
      curve: Curves.easeOutBack,
    ));

    _animationController.forward(from: 0).then((_) {
      _positionNotifier.value = targetPosition;
      _animation = null;
    });
  }
}


class _ChatPanel extends StatefulWidget {
  final ScrollController scrollController;
  final int initialTab;
  const _ChatPanel({required this.scrollController, this.initialTab = 0});

  @override
  State<_ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<_ChatPanel> {
  late int _activeTab; // 0 = Trợ lý AI, 1 = Kỹ thuật viên

  final ChatRemoteDataSource _chatRemote = GetIt.instance<ChatRemoteDataSource>();

  String? _conversationId;
  Map<String, dynamic>? _techInfo;
  List<ChatMessage> _techMessages = [];
  bool _loadingTechChat = true;
  String? _techChatError;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    _chatBloc = GetIt.instance<ChatBloc>();
    _chatBloc.stream.listen((_) {
      if (mounted) _scrollToBottom();
    });
    _initDirectChat();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _initDirectChat() async {
    try {
      if (!mounted) return;
      setState(() {
        _loadingTechChat = true;
        _techChatError = null;
      });

      final data = await _chatRemote.getDirectConversation();
      final convId = data['conversationId'] as String;
      final messagesList = data['messages'] as List;
      final tech = data['technician'] as Map<String, dynamic>?;

      final parsedMessages = messagesList
          .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _conversationId = convId;
          _techInfo = tech;
          _techMessages = parsedMessages;
          _loadingTechChat = false;
        });
        _scrollToBottom();
        _startPolling();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _techChatError = 'Không thể kết nối hội thoại trực tiếp: $e';
          _loadingTechChat = false;
        });
      }
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (!mounted || _activeTab != 1 || _conversationId == null) return;
      try {
        final messages = await _chatRemote.getDirectHistory(_conversationId!);
        if (messages.length != _techMessages.length && mounted) {
          setState(() {
            _techMessages = messages;
          });
          _scrollToBottom();
        }
      } catch (e) {
        // Silent catch for network hiccups
      }
    });
  }

  void _sendTechMessage(String text) async {
    if (text.trim().isEmpty || _conversationId == null) return;
    final content = text.trim();

    // Responsive local insert
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = ChatMessageModel(
      id: tempId,
      role: MessageRole.customer,
      content: jsonEncode({
        'senderId': 'temp',
        'senderName': 'Bạn',
        'text': content,
      }),
      timestamp: DateTime.now(),
    );

    setState(() {
      _techMessages.add(tempMsg);
    });
    _scrollToBottom();

    try {
      final sentMsg = await _chatRemote.sendDirectMessage(content, _conversationId!);
      if (mounted) {
        setState(() {
          _techMessages.removeWhere((m) => m.id == tempId);
          _techMessages.add(sentMsg);
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi gửi tin nhắn: $e')),
        );
        setState(() {
          _techMessages.removeWhere((m) => m.id == tempId);
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.scrollController.hasClients) {
        widget.scrollController.animateTo(
          widget.scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _parseMessageContent(String rawContent) {
    try {
      final decoded = jsonDecode(rawContent) as Map<String, dynamic>;
      return decoded['text'] as String? ?? rawContent;
    } catch (e) {
      return rawContent;
    }
  }

  String? _parseSenderName(String rawContent, String defaultName) {
    try {
      final decoded = jsonDecode(rawContent) as Map<String, dynamic>;
      return decoded['senderName'] as String?;
    } catch (e) {
      return defaultName;
    }
  }

  late final ChatBloc _chatBloc;

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: Alignment(_activeTab == 0 ? -1.0 : 1.0, 0.0),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _activeTab = 0),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.smart_toy_outlined,
                          size: 16,
                          color: _activeTab == 0 ? AppColors.primary : AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Trợ lý AI',
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: _activeTab == 0 ? FontWeight.w700 : FontWeight.w500,
                            color: _activeTab == 0 ? AppColors.primary : AppColors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _activeTab = 1);
                    _scrollToBottom();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.build_circle_outlined,
                          size: 16,
                          color: _activeTab == 1 ? AppColors.primary : AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Kỹ thuật viên',
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: _activeTab == 1 ? FontWeight.w700 : FontWeight.w500,
                            color: _activeTab == 1 ? AppColors.primary : AppColors.onSurfaceVariant,
                            fontSize: 12,
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
      ),
    );
  }

  Widget _buildAIView() {
    return BlocBuilder<ChatBloc, ChatState>(
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
          // Filter to only display AI chatbot messages
          final aiMessages = messages.where((m) => 
            m.role == MessageRole.user || 
            m.role == MessageRole.bot || 
            m.role == MessageRole.system
          ).toList();

          if (aiMessages.isEmpty) {
            return SingleChildScrollView(
              padding: const EdgeInsets.only(top: 40, bottom: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Xin chào! Mình là trợ lý AI',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Mình có thể giải đáp các thắc mắc của bạn về dịch vụ, bảo dưỡng xe điện Xanh EV.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ChatSuggestions(
                    onTap: (text) => _chatBloc.add(ChatSendMessage(text)),
                  ),
                ],
              ),
            );
          }

          final lastMessage = aiMessages.isNotEmpty ? aiMessages.last : null;
          final lastIsBot = lastMessage != null &&
              lastMessage.role != MessageRole.user &&
              lastMessage.role != MessageRole.customer;
          
          List<String>? dynamicSuggestions;
          if (lastIsBot) {
            dynamicSuggestions = _getDynamicSuggestions(lastMessage.content);
          }

          final hasDynamic = dynamicSuggestions != null && dynamicSuggestions.isNotEmpty;
          final showSuggestions = aiMessages.length <= 2 || hasDynamic;

          return ListView.builder(
            controller: widget.scrollController,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            itemCount: aiMessages.length + (showSuggestions ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == aiMessages.length) {
                return ChatSuggestions(
                  customSuggestions: dynamicSuggestions,
                  onTap: _onSuggestionTap,
                );
              }
              return ChatBubble(message: aiMessages[i]);
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _onSuggestionTap(String text) {
    if (text.contains('Chọn ngày & giờ khác') || text == 'Chọn ngày & giờ khác...') {
      _selectCustomDateTime();
      return;
    }
    String replyText = text;
    final match = RegExp(r'^\d+\.\s*(.*)').firstMatch(text);
    if (match != null) {
      replyText = match.group(1)!;
    }
    _chatBloc.add(ChatSendMessage(replyText));
  }

  Future<void> _selectCustomDateTime() async {
    final now = DateTime.now();
    
    // 1. Show Date Picker
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDate == null) return;
    if (!mounted) return;

    // 2. Show Time Picker
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return;

    // 3. Format and send
    final day = pickedDate.day.toString().padLeft(2, '0');
    final month = pickedDate.month.toString().padLeft(2, '0');
    final hour = pickedTime.hour.toString().padLeft(2, '0');
    final minute = pickedTime.minute.toString().padLeft(2, '0');
    
    final formattedText = '$day/$month $hour:$minute';
    _chatBloc.add(ChatSendMessage(formattedText));
  }

  List<String>? _getDynamicSuggestions(String content) {
    final list = <String>[];
    
    // Extract pipe-separated options from HTML comments
    final match = RegExp(r'<!--\s*Options:\s*(.*?)\s*-->', caseSensitive: false).firstMatch(content);
    if (match != null) {
      final optionsStr = match.group(1)!;
      final parts = optionsStr.split('|');
      for (var part in parts) {
        final trimmed = part.trim();
        if (trimmed.isNotEmpty) {
          list.add(trimmed);
        }
      }
    }
    
    return list.isEmpty ? null : list;
  }

  Widget _buildTechnicianView() {
    if (_loadingTechChat) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (_techChatError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 40),
              const SizedBox(height: 12),
              Text(
                _techChatError!,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _initDirectChat,
                child: const Text('Thử lại', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
    }

    // Filter to only display direct customer-technician messages
    final directMessages = _techMessages.where((m) => 
      m.role == MessageRole.customer || 
      m.role == MessageRole.technician
    ).toList();

    if (directMessages.isEmpty) {
      return Column(
        children: [
          _buildTechnicianHeaderCard(),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 40,
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Bắt đầu trò chuyện với Kỹ thuật viên...',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildTechnicianHeaderCard(),
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            itemCount: directMessages.length,
            itemBuilder: (_, i) {
              final msg = directMessages[i];
              final isUser = msg.role == MessageRole.customer || msg.role == MessageRole.user;
              final displayContent = _parseMessageContent(msg.content);
              final senderName = isUser 
                  ? null 
                  : _parseSenderName(msg.content, _techInfo?['name'] as String? ?? 'Kỹ thuật viên');

              final displayMsg = msg.copyWith(content: displayContent);

              return ChatBubble(
                message: displayMsg,
                senderName: senderName,
                senderIcon: isUser ? null : Icons.build_circle_outlined,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicianHeaderCard() {
    final hasTech = _techInfo != null;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasTech ? Icons.build_circle_outlined : Icons.support_agent_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasTech 
                      ? 'KTV phụ trách: ${_techInfo!['name']}' 
                      : 'Hỗ trợ Xanh EV',
                  style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  hasTech 
                      ? 'Đang thực hiện sửa xe của bạn • Đang trực tuyến'
                      : 'Kết nối trực tiếp khi xe của bạn được tiếp nhận sửa chữa.',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurfaceVariant, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
            _buildTabBar(),
            Expanded(
              child: _activeTab == 0 ? _buildAIView() : _buildTechnicianView(),
            ),
            if (_activeTab == 0 || _techInfo != null)
              ChatInputBar(
                onSend: (text) {
                  if (_activeTab == 0) {
                    _chatBloc.add(ChatSendMessage(text));
                  } else {
                    _sendTechMessage(text);
                  }
                },
              )
            else
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 12,
                  top: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  border: Border(
                    top: BorderSide(
                      color: AppColors.onSurface.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Kênh chat bị khóa khi không có phiên sửa chữa hoạt động.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
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
    final chatBloc = GetIt.instance<ChatBloc>();

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
                BlocBuilder<ChatBloc, ChatState>(
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

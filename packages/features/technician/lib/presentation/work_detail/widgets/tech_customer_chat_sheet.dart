import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:design_system/design_system.dart';

void showTechCustomerChatSheet(BuildContext context, {
  required String customerId,
  required String customerName,
  bool isSessionActive = true,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [0.5, 0.8, 0.95],
      builder: (_, scrollCtrl) => TechCustomerChatSheet(
        scrollController: scrollCtrl,
        customerId: customerId,
        customerName: customerName,
        isSessionActive: isSessionActive,
      ),
    ),
  );
}

class TechCustomerChatSheet extends StatefulWidget {
  final ScrollController scrollController;
  final String customerId;
  final String customerName;
  final bool isSessionActive;

  const TechCustomerChatSheet({
    super.key,
    required this.scrollController,
    required this.customerId,
    required this.customerName,
    this.isSessionActive = true,
  });

  @override
  State<TechCustomerChatSheet> createState() => _TechCustomerChatSheetState();
}

class _TechCustomerChatSheetState extends State<TechCustomerChatSheet> {
  final Dio _dio = GetIt.instance<Dio>();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String? _conversationId;
  List<dynamic> _messages = [];
  bool _loading = true;
  String? _error;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchConversation();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchConversation() async {
    try {
      if (!mounted) return;
      setState(() {
        _loading = true;
        _error = null;
      });

      final res = await _dio.get('/chat/direct/conversation', queryParameters: {
        'customerId': widget.customerId,
      });

      final data = res.data['data'] as Map<String, dynamic>;
      final convId = data['conversationId'] as String;
      final messagesList = data['messages'] as List;

      if (mounted) {
        setState(() {
          _conversationId = convId;
          _messages = messagesList;
          _loading = false;
        });
        _scrollToBottom();
        _startPolling();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Không thể kết nối phòng chat: $e';
          _loading = false;
        });
      }
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (!mounted || _conversationId == null) return;
      try {
        final res = await _dio.get('/chat/direct/history/$_conversationId');
        final messagesList = res.data['data'] as List;
        if (messagesList.length != _messages.length && mounted) {
          setState(() {
            _messages = messagesList;
          });
          _scrollToBottom();
        }
      } catch (_) {}
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _conversationId == null) return;
    
    _textController.clear();
    _focusNode.requestFocus();

    // Insert message locally for responsive UI
    final tempMsg = {
      'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
      'role': 'technician',
      'content': jsonEncode({
        'senderId': 'temp',
        'senderName': 'Bạn',
        'text': text,
      }),
      'createdAt': DateTime.now().toIso8601String(),
    };

    setState(() {
      _messages.add(tempMsg);
    });
    _scrollToBottom();

    try {
      final res = await _dio.post('/chat/direct/message', data: {
        'content': text,
        'conversationId': _conversationId,
      });
      
      final savedMsg = res.data['data'];
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m['id'] == tempMsg['id']);
          _messages.add(savedMsg);
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi gửi tin nhắn: $e')),
        );
        setState(() {
          _messages.removeWhere((m) => m['id'] == tempMsg['id']);
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

  String _formatTime(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Vừa xong';
      if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
      return '${dt.hour.padLeft()}:${dt.minute.padLeft()}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        color: AppColors.surface,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildChatArea()),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.onSurface.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF006E2F), Color(0xFF059669)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.customerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF191C1E),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Khách hàng • Trực tuyến',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF0F9D58),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, size: 26, color: Color(0xFF6B7280)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006E2F)),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 44),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _fetchConversation,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppColors.onSurfaceVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            const Text(
              'Gửi tin nhắn để bắt đầu hội thoại với Khách hàng',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isMe = msg['role'] == 'technician';
        final text = _parseMessageContent(msg['content'] ?? '');
        final time = _formatTime(msg['createdAt'] ?? '');

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF006E2F) : const Color(0xFFECEEF0),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: isMe ? Colors.white : const Color(0xFF191C1E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 9,
                      color: isMe ? Colors.white70 : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    if (!widget.isSessionActive) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 12,
          top: 12,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.onSurface.withValues(alpha: 0.06)),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFF6B7280),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Phiên chat đã đóng do phiếu sửa chữa đã hoàn thành.',
                style: TextStyle(
                  color: const Color(0xFF6B7280),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.onSurface.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFECEEF0),
                borderRadius: BorderRadius.circular(22),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  hintStyle: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF006E2F),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF006E2F).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

extension IntPadding on int {
  String padLeft([int width = 2, String padding = '0']) =>
      toString().padLeft(width, padding);
}

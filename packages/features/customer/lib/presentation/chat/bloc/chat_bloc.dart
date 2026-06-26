import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/entities/chat_message.dart';
import '../domain/repositories/chat_repository.dart';
import '../data/models/chat_message_model.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _repository;
  static const _botResponses = {
    'dịch vụ': 'Xanh EV cung cấp các dịch vụ:\n'
        '• Sửa chữa & bảo dưỡng xe điện\n'
        '• Thay pin, sạc pin\n'
        '• Kiểm tra & nâng cấp phần mềm\n'
        '• Tư vấn kỹ thuật miễn phí\n\n'
        'Bạn muốn biết thêm về dịch vụ nào?',
    'bảo dưỡng': 'Lịch bảo dưỡng định kỳ:\n'
        '• Sau 1.000 km đầu tiên\n'
        '• Mỗi 5.000 km tiếp theo\n'
        '• Kiểm tra pin mỗi 10.000 km\n\n'
        'Bạn có thể đặt lịch qua mục "Đặt lịch" trên ứng dụng.',
    'giá': 'Chi phí tham khảo:\n'
        '• Kiểm tra tổng quát: 100.000đ\n'
        '• Bảo dưỡng định kỳ: 200.000đ - 500.000đ\n'
        '• Thay pin: Liên hệ báo giá\n'
        '• Sửa chữa: Tuỳ mức độ hư hỏng\n\n'
        'Giá có thể thay đổi theo từng dòng xe.',
    'địa chỉ': 'Hệ thống Xanh EV:\n'
        '📍 123 Nguyễn Thị Minh Khai, P.7, TP. Trà Vinh\n\n'
        'Giờ làm việc: 7:00 - 19:00 (T2-CN)',
    'giờ': 'Giờ làm việc: 7:00 - 19:00\nTất cả các ngày trong tuần (kể cả CN).',
    'bảo hành': 'Chính sách bảo hành:\n'
        '• Linh kiện thay thế: 6 tháng\n'
        '• Pin: 12 tháng hoặc 20.000 km\n'
        '• Sửa chữa: 3 tháng\n\n'
        'Xem chi tiết tại mục "Bảo hành" trên ứng dụng.',
    'điểm': 'Chương trình tích điểm:\n'
        '• 20.000đ = 1 điểm\n'
        '• 50 điểm = 50.000đ giảm giá\n'
        '• Điểm tích luỹ không giới hạn thời gian',
    'cây': 'Chương trình trồng cây:\n'
        '• Mỗi đơn sửa chữa: +1 cây\n'
        '• Cứ 500.000đ: thêm 1 cây\n'
        '• Chúng tôi trồng cây thay bạn trên khắp Việt Nam 🌱',
  };

  ChatBloc({required ChatRepository repository})
      : _repository = repository,
        super(ChatLoaded(messages: [])) {
    on<ChatLoadHistory>(_onLoadHistory);
    on<ChatSendMessage>(_onSendMessage);
    on<ChatClearHistory>(_onClearHistory);
    add(ChatLoadHistory());
  }

  Future<void> _onLoadHistory(
    ChatLoadHistory event,
    Emitter<ChatState> emit,
  ) async {
    final result = await _repository.getHistory();
    await result.fold(
      (failure) async {},
      (messages) async {
        if (messages.isNotEmpty) {
          emit(ChatLoaded(messages: messages));
        }
      },
    );
  }

  Future<void> _onSendMessage(
    ChatSendMessage event,
    Emitter<ChatState> emit,
  ) async {
    final current = state;
    if (current is! ChatLoaded) return;

    final userMsg = ChatMessageModel.userMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: event.content,
    );

    final typingMsg = ChatMessageModel.typingIndicator();

    emit(current.copyWith(
      messages: [...current.messages, userMsg, typingMsg],
      isTyping: true,
    ));

    final result = await _repository.sendMessage(event.content);

    await result.fold(
      (failure) async {
        final msgs = List<ChatMessage>.from(current.messages)
          ..add(userMsg)
          ..add(ChatMessageModel.botMessage(
            id: 'err_${DateTime.now().millisecondsSinceEpoch}',
            content: 'Rất tiếc, tôi chưa thể trả lời ngay. '
                'Vui lòng thử lại sau hoặc gọi hotline 0976 985 305 để được hỗ trợ.',
          ));
        emit(current.copyWith(messages: msgs, isTyping: false));
      },
      (botMsg) async {
        final msgs = List<ChatMessage>.from(current.messages)
          ..add(userMsg)
          ..add(botMsg);
        emit(current.copyWith(messages: msgs, isTyping: false));
      },
    );
  }

  Future<void> _onClearHistory(
    ChatClearHistory event,
    Emitter<ChatState> emit,
  ) async {
    await _repository.clearHistory();
    emit(const ChatLoaded(messages: []));
  }
}

// ──────────────────────────────
// Mock chat bloc for development
// ──────────────────────────────

class MockChatBloc extends Bloc<ChatEvent, ChatState> {
  MockChatBloc() : super(ChatLoaded(messages: [
    ChatMessageModel.botMessage(
      id: 'welcome',
      content: 'Xin chào! Tôi là trợ lý ảo của Xanh EV. '
          'Tôi có thể giúp gì cho bạn?\n\n'
          '💡 Gợi ý:\n'
          '• "Có những dịch vụ gì?"\n'
          '• "Bảo dưỡng xe điện"\n'
          '• "Báo giá sửa chữa"\n'
          '• "Địa chỉ cửa hàng"',
    ),
  ])) {
    on<ChatSendMessage>(_onMockSend);
  }

  String _findResponse(String input) {
    final lower = input.toLowerCase();
    for (final entry in _mockKeywords.entries) {
      if (entry.key.any((kw) => lower.contains(kw))) {
        return entry.value;
      }
    }
    return 'Cảm ơn bạn đã liên hệ! Hiện tôi chưa hiểu rõ yêu cầu. '
        'Bạn có thể thử hỏi:\n'
        '• Dịch vụ sửa chữa\n'
        '• Bảo dưỡng định kỳ\n'
        '• Báo giá\n'
        '• Địa chỉ & giờ làm việc\n'
        '• Chính sách bảo hành\n'
        '• Điểm thưởng & cây xanh';
  }

  Future<void> _onMockSend(
    ChatSendMessage event,
    Emitter<ChatState> emit,
  ) async {
    final current = state;
    if (current is! ChatLoaded) return;

    final userMsg = ChatMessageModel.userMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: event.content,
    );

    final typingMsg = ChatMessageModel.typingIndicator();
    emit(current.copyWith(
      messages: [...current.messages, userMsg, typingMsg],
      isTyping: true,
    ));

    await Future.delayed(Duration(milliseconds: 800 + 200 * _random.nextInt(4)));

    final botReply = ChatMessageModel.botMessage(
      id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
      content: _findResponse(event.content),
    );

    final msgs = List<ChatMessage>.from(current.messages)
      ..add(userMsg)
      ..add(botReply);
    emit(current.copyWith(messages: msgs, isTyping: false));
  }
}

const _mockKeywords = <List<String>, String>{
  ['dịch vụ', 'làm gì', 'sửa', 'sửa chữa']: 'Xanh EV cung cấp các dịch vụ:\n'
      '• Sửa chữa & bảo dưỡng xe điện\n'
      '• Thay pin, sạc pin\n'
      '• Kiểm tra & nâng cấp phần mềm\n'
      '• Tư vấn kỹ thuật miễn phí\n\n'
      'Bạn muốn biết thêm về dịch vụ nào?',
  ['bảo dưỡng', 'bảo trì', 'định kỳ']: 'Lịch bảo dưỡng định kỳ:\n'
      '• Sau 1.000 km đầu tiên\n'
      '• Mỗi 5.000 km tiếp theo\n'
      '• Kiểm tra pin mỗi 10.000 km\n\n'
      'Bạn có thể đặt lịch qua mục "Đặt lịch" trên ứng dụng.',
  ['giá', 'bao nhiêu', 'phí', 'chi phí']: 'Chi phí tham khảo:\n'
      '• Kiểm tra tổng quát: 100.000đ\n'
      '• Bảo dưỡng định kỳ: 200.000đ - 500.000đ\n'
      '• Thay pin: Liên hệ báo giá\n'
      '• Sửa chữa: Tuỳ mức độ\n\n'
      'Liên hệ hotline để báo giá chính xác theo dòng xe.',
  ['địa chỉ', 'cửa hàng', 'ở đâu', 'đường']: 'Hệ thống Xanh EV:\n'
      '📍 123 Nguyễn Thị Minh Khai, P.7, TP. Trà Vinh\n\n'
      'Giờ làm việc: 7:00 - 19:00 (T2-CN)',
  ['giờ', 'mở cửa', 'đóng cửa']: 'Giờ làm việc: 7:00 - 19:00\nTất cả các ngày trong tuần (kể cả CN).',
  ['bảo hành', 'bảo hiểm']: 'Chính sách bảo hành:\n'
      '• Linh kiện thay thế: 6 tháng\n'
      '• Pin: 12 tháng hoặc 20.000 km\n'
      '• Sửa chữa: 3 tháng\n\n'
      'Xem chi tiết tại mục "Bảo hành" trên ứng dụng.',
  ['điểm', 'tích điểm', 'quà tặng']: 'Chương trình tích điểm:\n'
      '• 20.000đ = 1 điểm\n'
      '• 50 điểm = 50.000đ giảm giá\n'
      '• Điểm tích luỹ không giới hạn thời gian',
  ['cây', 'cây xanh', 'trồng', 'xanh']: 'Chương trình trồng cây:\n'
      '• Mỗi đơn sửa chữa: +1 cây\n'
      '• Cứ 500.000đ: thêm 1 cây\n'
      '• Chúng tôi trồng cây thay bạn trên khắp Việt Nam 🌱',
};

final _random = Random();

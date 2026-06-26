import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/entities/tech_chat_message.dart';
import '../domain/repositories/tech_chat_repository.dart';
import '../data/models/tech_chat_message_model.dart';
import 'tech_chat_event.dart';
import 'tech_chat_state.dart';

class TechChatBloc extends Bloc<TechChatEvent, TechChatState> {
  final TechChatRepository _repository;

  TechChatBloc({required TechChatRepository repository})
      : _repository = repository,
        super(TechChatLoaded(messages: [])) {
    on<TechChatLoadHistory>(_onLoadHistory);
    on<TechChatSendMessage>(_onSendMessage);
    on<TechChatClearHistory>(_onClearHistory);
    add(TechChatLoadHistory());
  }

  Future<void> _onLoadHistory(
    TechChatLoadHistory event,
    Emitter<TechChatState> emit,
  ) async {
    final result = await _repository.getHistory();
    await result.fold(
      (failure) async {},
      (messages) async {
        if (messages.isNotEmpty) {
          emit(TechChatLoaded(messages: messages));
        }
      },
    );
  }

  Future<void> _onSendMessage(
    TechChatSendMessage event,
    Emitter<TechChatState> emit,
  ) async {
    final current = state;
    if (current is! TechChatLoaded) return;

    final userMsg = TechChatMessageModel.userMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: event.content,
    );

    final typingMsg = TechChatMessageModel.typingIndicator();

    emit(current.copyWith(
      messages: [...current.messages, userMsg, typingMsg],
      isTyping: true,
    ));

    final result = await _repository.sendMessage(event.content);

    await result.fold(
      (failure) async {
        final msgs = List<TechChatMessage>.from(current.messages)
          ..add(userMsg)
          ..add(TechChatMessageModel.botMessage(
            id: 'err_${DateTime.now().millisecondsSinceEpoch}',
            content: 'Rất tiếc, tôi chưa thể trả lời ngay. '
                'Vui lòng thử lại sau.',
          ));
        emit(current.copyWith(messages: msgs, isTyping: false));
      },
      (botMsg) async {
        final msgs = List<TechChatMessage>.from(current.messages)
          ..add(userMsg)
          ..add(botMsg);
        emit(current.copyWith(messages: msgs, isTyping: false));
      },
    );
  }

  Future<void> _onClearHistory(
    TechChatClearHistory event,
    Emitter<TechChatState> emit,
  ) async {
    await _repository.clearHistory();
    emit(const TechChatLoaded(messages: []));
  }
}
